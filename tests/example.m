% This script will perform a proof-of-concept demonstration of rtfmri
% Designed to run adjacent to simulatescanner.m

%% Setup

% default parameters
subject = 'test';
run = '0';
atScanner = false;
sbref = 'sbRef_RT-fMR_e1_d1.nii';
brainFileFormat = '.nii';
roiName = 'kastner_v1lh_10.nii.gz';
projectName = 'neurofeedback';
minFileSize = 2900000;

% get required paths and adjust to paramater values
[~, scannerPathStem, ~, scratchPath, ~, subjectProcessedPath] = getpaths(subject,projectName);
scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];
if ~exist(scannerPath,'dir')
    mkdir(scannerPath)
end
fprintf('Using scannerPath at: %s\n',scannerPath);

% example-specific paths (not used outside of this script)
basePath = pwd;
anatPath = fullfile(basePath,"tests","imgs","anatomical"); % location of reference images, ROIs, and matrices
processedPath = fullfile(scannerPath,"processed");

if ~exist(processedPath,'dir')
    mkdir(processedPath);
end

rawImagePath = fullfile(basePath,"tests","imgs","functional"); % location of collected NIFTI images, including SBREF
rawImageDir = dir(rawImagePath);
rawImageDir = rawImageDir(3:end);
rawImageDir = table2struct(sortrows(struct2table(rawImageDir),'datenum')); % sort by aquisition time

% simulate MRI scanner by copying sbref to directory
iImage = 2;
try
    copyfile(fullfile(rawImagePath,"sbRef*"),scannerPath);
    disp("Copied SBREF to scannerPath");
catch
    error("No SBREF found.");
end
pause(1);

%% register to SBREF
fprintf('Performing registration on SBREF\n');
registrationImage = sbref;
% Complete Registration to First DICOM
dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'/*',brainFileFormat,'*')));

% reassign sbref image to new_epi
newEPI = fullfile(processedPath,'new_epi.nii.gz');
copyfile(fullfile(scannerPath,registrationImage),newEPI);

% define roiEPI
roiEPIName = strcat('epi_',roiName);

% Determine paths
[~,anatPathWsl] = system(sprintf('wsl --exec wslpath %s',anatPath));
[~,processedPathWsl] = system(sprintf('wsl --exec wslpath %s',processedPath));
anatPathWsl = anatPathWsl(1:end-1);
processedPathWsl = processedPathWsl(1:end-1);

% verbose path output
fprintf('\nImage file path locations\n');
maskedScoutEPI = [anatPathWsl '/scoutEPI_masked.nii.gz'];
fprintf('\tMasked Scout EPI: subjectProcessedPath/\n');
roiTemplate = [anatPathWsl '/' roiName];
fprintf('\tROI Template: bidsPath/derivatives/templates/\n');
roiEPI = [anatPathWsl '/' roiEPIName];
fprintf('\tROI EPI: subjectProcessedPath/\n');
newEPI = [processedPathWsl '/new_epi.nii.gz'];
% fprintf('new EPI: subjectProcessedPath/run#/processed');
maskedT1 = [anatPathWsl '/T1_masked.nii.gz'];
fprintf('\tMasked T1: subjectProcessedPath/\n');
pause(1)

fprintf('\nMat file path locations\n');
fprintf('\tanat2coreg,anat2standard,coreg2anat,standard2anat,standard2coreg: subjectProcessedPath/\n');
fprintf('\ttimeseries,mainData: subjectProcessedPath/processed/run#/ (output)\n\n');

% Run registration script
[err,output] = system(sprintf('wsl --exec ./realtime/registerepitoepi.sh %s %s %s %s %s %s %s',...,
anatPathWsl, processedPathWsl, newEPI, maskedScoutEPI, roiTemplate, roiEPI, maskedT1),'-echo');

if ~err
    disp("Registration completed.");
else
    error("Registration failed.");
end

% redefine paths
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

disp("Press any key to begin");
pause;

%% Main Neurofeedback Loop

% Initialize the main data struct;
mainData = struct;
mainData.acqTime = {}; % time at which the DICOM hit the local computer
mainData.dataTimepoint = {}; % time at which the DICOM was processed
mainData.dicomName = {}; % name of the DICOM
mainData.roiSignal = {}; % whatever signal is the output (default is mean)

fprintf('Starting real-time processing sequence. To stop press CTRL+C.');

for i = iImage:length(rawImageDir)
    
    % copy niftis one-by-one as simulated MRI scanner
    copyfile(strcat(rawImagePath,rawImageDir(i).name),scannerPath);
    disp(strcat("Copied ",rawImageDir(i).name," to scannerPath"));
    pause(1);

    % Check for a new image, do some processing.
    [mainData(i).acqTime,mainData(i).dataTimepoint,mainData(i).roiSignal,...
     initialDirSize, mainData(i).dicomName] = ...
     checkfornewimage(subject,run,scannerPath,roiIndex,initialDirSize,processedPath,minFileSize,scoutNifti);

    % Normalize BOLD data
    dataPlot = cell2mat([mainData.roiSignal]); % vectorize
    if std(dataPlot) ~= 0
        dataPlot = (dataPlot - mean(dataPlot))./std(dataPlot); % mean-center
    end
    dataPlot = detrend(dataPlot); % detrend

    % Simple line plot.
    cla reset;
    plot(dataPlot,'.');

    pause(.01);
end

    