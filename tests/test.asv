% This script will perform a proof-of-concept demonstration of rtfmri
% Designed to run adjacent to simulatescanner.m

subject = 'test';
run = '0';
atScanner = false;
sbref = 'sbRef_RT-fMR_e1_d1.nii';
brainFileFormat = '.nii';
roiName = 'kastner_v1lh_10.nii.gz';
projectName = 'neurofeedback';
minFileSize = 2900000;

anatPath = "C:\Users\jacob.frank\Documents\MATLAB\toolboxes\rtfmri\tests\imgs\anatomical";
functPath = "tests\imgs\functional\";
processedPath = strcat(scannerPath,'\processed');

[~, scannerPathStem, ~, scratchPath, ~, subjectProcessedPath] = getpaths(subject,projectName);
scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];
if ~exist(scannerPath,'dir')
    mkdir(scannerPath)
end

if ~exist(processedPath,'dir')
    mkdir(processedPath);
end

fprintf('Performing registration on SBREF\n');
registrationImage = sbref;
% Complete Registration to First DICOM
dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'/*',brainFileFormat,'*')));

newEPI = strcat(processedPath,filesep,'new_epi.nii.gz');
copyfile(fullfile(scannerPath,registrationImage),newEPI);
roiEPIName = strcat('epi_',roiName);

% Determine paths
[~,anatPathWsl] = system(sprintf('wsl --exec wslpath %s',anatPath));
[~,processedPathWsl] = system(sprintf('wsl --exec wslpath %s',processedPath));
anatPathWsl = anatPathWsl(1:end-1);
processedPathWsl = processedPathWsl(1:end-1);

% 
% maskedScoutEPI = [subjectProcessedPath '/scoutEPI_masked.nii.gz'];
% roiTemplate = [bidsPath '/derivatives/templates/' p.Results.roiName];
% roiEPI = [runPath '/' roiEPIName];
% newEPI = [runPath '/new_epi.nii.gz'];
% maskedT1 = [subjectProcessedPath '/T1_masked.nii.gz'];

maskedScoutEPI = [anatPathWsl '/scoutEPI_masked.nii.gz'];
roiTemplate = [anatPathWsl '/' roiName];
roiEPI = [anatPathWsl '/' roiEPIName];
newEPI = [processedPathWsl '/new_epi.nii.gz'];
maskedT1 = [anatPathWsl '/T1_masked.nii.gz'];

% Run registration script
[err,output] = system(sprintf('wsl --exec ./realtime/registerepitoepi.sh %s %s %s %s %s %s %s',...,
anatPathWsl, processedPathWsl, newEPI, maskedScoutEPI, roiTemplate, roiEPI, maskedT1),'-echo');

if ~err
    disp("Registration completed.");
else
    error("Registration failed.");
end

roiEpiName = strcat('epi_',roiName);
scoutNifti = strcat(processedPath,filesep,'new_epi.nii.gz');
initialDirSize = 1;
roiPath = fullfile(anatPath, roiEpiName);

% Load the NIFTI located at roiPath, and turn it into a logical index
roiNiftiInfo = niftiinfo(roiPath);
roiNifti = niftiread(roiNiftiInfo);
roiIndex = logical(roiNifti);

% Initialize plot
figure;
hold on;

%% Main Neurofeedback Loop

% Initialize the main data struct;
mainData = struct;
mainData.acqTime = {}; % time at which the DICOM hit the local computer
mainData.dataTimepoint = {}; % time at which the DICOM was processed
mainData.dicomName = {}; % name of the DICOM
mainData.roiSignal = {}; % whatever signal is the output (default is mean)

fprintf('Starting real-time processing sequence. To stop press CTRL+C.');

i = 1;

while true

    % Check for a new image, do some processing.
    [mainData(i).acqTime,mainData(i).dataTimepoint,mainData(i).roiSignal,...
     initialDirSize, mainData(i).dicomName] = ...
     checkfornewimage(subject,run,scannerPath,roiIndex,initialDirSize,processedPath,minFileSize,scoutNifti);

    % Normalize BOLD data
    dataPlot = [mainData.roiSignal]; % vectorize
    if std(dataPlot) ~= 0
        dataPlot = (dataPlot - mean(dataPlot))./std(dataPlot); % mean-center
    end
    dataPlot = detrend(dataPlot); % detrend

    % Simple line plot.
    cla reset;
    plot(dataPlot,'.');

    i = i + 1;

    pause(.01);
end

    