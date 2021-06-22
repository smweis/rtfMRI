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
saveMatrix = 0;

% get required paths and adjust to paramater values
[~, scannerPathStem, codePath, scratchPath, ~, subjectProcessedPath] = getpaths(subject,projectName);

scannerPath = fullfile(scannerPathStem,subject,'simulatedScannerDirectory',strcat('run',run));
if ~exist(scannerPath,'dir')
    mkdir(scannerPath)
end
fprintf('Using scannerPath at: %s\n',scannerPath);

cd(codePath);

% example-specific paths (not used outside of this script)
basePath = pwd;
anatPath = fullfile(basePath,"tests","imgs","anatomical"); % location of reference images, ROIs, and matrices
runPath = fullfile(scannerPath,"processed",strcat('run',run));

if ~exist(runPath,'dir')
    mkdir(runPath);
end

rawImagePath = fullfile(basePath,"tests","imgs","functional"); % location of collected NIFTI images, including SBREF
rawImageDir = dir(rawImagePath);
rawImageDir = rawImageDir(3:end);
rawImageDir = table2struct(sortrows(struct2table(rawImageDir),'datenum')); % sort by aquisition time

% simulate MRI scanner by copying sbref to directory
iImage = 2;
try
    copyfile(fullfile(rawImagePath,sbref),scannerPath);
    disp("Copied SBREF to scannerPath");
catch
    error("No SBREF found.");
end
pause(1);

%% register to SBREF
fprintf('Performing registration on SBREF\n');
registrationImage = sbref;

% Reassign sbref image to new_epi
scoutNifti = fullfile(runPath,'new_epi.nii.gz');
copyfile(fullfile(scannerPath,registrationImage),scoutNifti);

% Define roiEPI
roiEpiName = strcat('epi_',roiName);

% Determine paths and set up images
fprintf('\nImage file path locations\n');

[~,anatPathWsl] = system(sprintf('wsl --exec wslpath %s',anatPath));
[~,processedPathWsl] = system(sprintf('wsl --exec wslpath %s',runPath));
[~,scannerPathWsl] = system(sprintf('wsl --exec wslpath %s',scannerPath));
anatPathWsl = anatPathWsl(1:end-1);
processedPathWsl = processedPathWsl(1:end-1);

% T1
T1 = [anatPathWsl '/RTQEST_test2_MPRAGE_SENSE2_3_1.nii'];
fprintf('\tT1: subjectProcessedPath/\n');

% masked T1
maskedT1 = [anatPathWsl '/T1_masked.nii.gz'];
fprintf('\tMasked T1: subjectProcessedPath/\n');

% sbref
scoutEPI = strcat(scannerPathWsl,'/',registrationImage);
fprintf('\tScout EPI: scannerPath/run#\n');

% MNI
referenceImage = [anatPathWsl '/MNI152lin_T1_1mm_brain.nii.gz'];
fprintf('\tMNI reference: bidsPath/derivatives/templates/\n');

% ROI template
roiReferenceSpace = [anatPathWsl '/' roiName];
fprintf('\tROI template: bidsPath/derivatives/templates/\n');

% ROI in EPI space
roiEpiSpace = [anatPathWsl '/' roiEpiName];
fprintf('\tROI EPI: subjectProcessedPath/\n');

pause(1)

fprintf('\nMat file path locations\n');
fprintf('\tanat2coreg,anat2standard,coreg2anat,standard2anat,standard2coreg: subjectProcessedPath/\n');
fprintf('\ttimeseries,mainData: subjectProcessedPath/processed/run#/ (output)\n\n');

% Compose WSL command and run registration script
cmd = strcat('wsl --exec ./brainprocessing/setuproi.sh ');
args = [' ' processedPathWsl ' ' T1 ' ' maskedT1 ' ' scoutEPI ' ' referenceImage ' ' roiReferenceSpace ' ' roiEpiSpace];
exec = regexprep(strcat(cmd,args),'\s+',' '); % replace all newline characters with spaces

disp('Starting registration...');
[status,cmdout] = system(exec,'-echo');
assert(isempty(cmdout), 'Registration failed');

disp('Registration successful');

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

%% Main Loop

% Initialize the main data struct;
mainData = struct;
mainData.acqTime = {}; % time at which the DICOM hit the local computer
mainData.dataTimepoint = {}; % time at which the DICOM was processed
mainData.dicomName = {}; % name of the DICOM
mainData.roiSignal = {}; % whatever signal is the output (default is mean)

fprintf('Starting real-time processing sequence. To stop press CTRL+C.');

% Grab, process, and extract BOLD signal from new images
for i = iImage:length(rawImageDir)
    
    % Copy niftis one-by-one as simulated MRI scanner
    copyfile(fullfile(rawImagePath,rawImageDir(i).name),scannerPath);
    disp(strcat("Copied ",rawImageDir(i).name," to scannerPath"));
    pause(1);

    % Check for a new image, do some processing.
    [mainData(i).acqTime,mainData(i).dataTimepoint,mainData(i).roiSignal,...
     initialDirSize, mainData(i).dicomName] = ...
     checkfornewimage(subject,run,scannerPath,runPath,roiIndex,initialDirSize,minFileSize,scoutEPI,saveMatrix);

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

    