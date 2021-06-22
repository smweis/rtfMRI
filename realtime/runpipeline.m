function [mainData,firstTriggerTime] = runpipeline(varargin)

% The main function for the real-time fMRI pipeline on the scanner.
%
% Syntax:
%   mainData = runpipeline(varargin)
%
% Description:
%	Takes in the subject and run IDs. Can either simulate the pipeline
%	based on 'fake' scanner data (a local directory of images) or based on
%	data actually being acquired at the scanner.
%
% Optional key/value pairs:
%  'sbref'                - String. If included, the path to the sbref
%                           image. If sbref is empty, will register to the
%                           first image from the run.
%  'showFig'              - Logical. If true, will show a figure of the
%                           mean results.
%  'checkForTrigger'      - Logical. If true, will wait for a trigger ('t').
%
%  'minFileSize'          - Integer. The minimum size for a DICOM file in bytes.
%  'projectName'          - String. Name of project. Default =
%                           'neurofeedback'
%  'brainFileFormat'      - String. The brain image filetype (.dcm or .nii)
%  'saveMatrix'           - Logical. If true, a text file containing the
%                           vector of the ROI voxel values is writtem. 
% Outputs:
%   mainData              - Struct. Contains the main processed fMRI data
%                           as well as time stamps.
%
%   roiMeanTimeseries     - Array. Contains mean BOLD values for each trial



% Examples:

%{

% 1. Subject: test; run: 0; atScanner: n
% Run through a simulated scanner. Use a seperate instance of MATLAB to run
the simulatedscanner script located in tests/

Instance 1 (if debug set to 1):
    showFig = true;
    checkForTrigger = false;
    minFileSize = 1950000;
    mainData = runpipeline('showFig',showFig,'checkForTrigger',checkForTrigger,'minFileSize',minFileSize);

Instance 2:
    simulatedscanner;

% 2. Sanity check.
% You should see a successful registration and plotting of the BOLD signal. 

example;

% 3. UF
% Open command prompt
% Navigate to C:\Users\jacob.frank\Documents\drinDataDumper_tobeshared_UFlorida\drinDataDumper_tobeshared_UFlorida
% run python drinDumper.py -s 10.15.208.156 -o C:\Users\jacob.frank\Documents\blue\share\rtfmri_incoming\sub-102\simulatedScannerDirectory\run1 
sbref = 'C:\Users\jacob.frank\Documents\blue\share\rtfmri_incoming\test\simulatedScannerDirectory\run0\sbRef_RT-fMR_e1_d1.nii';
showFig = true;
checkForTrigger = true;
minFileSize = 2900000;
mainData = runpipeline('sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger,'minFileSize',minFileSize);
  
%}
debug = 0;
%% Parse input
p = inputParser;

% Required input
% p.addRequired('subject',@isstr);
% p.addRequired('run',@isstr);
% p.addRequired('atScanner',@islogical);

% Optional params
p.addParameter('sbref', 'sbRef_RT-fMR_e1_d1.nii', @isstr);
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('showFig', true, @islogical);
p.addParameter('checkForTrigger', true, @islogical);
p.addParameter('minFileSize',1950000,@isnumeric);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr);
p.addParameter('saveMatrix',false,@islogical);

% Prompt user for input
subject = input("Subject name: ",'s');
run = input("Run #: ",'s');
assert(~isnan(str2double(run)),"Run must be an integer");

atScanner = input("Are you at the scanner (y/n): ",'s');
assert(strcmpi(atScanner,'y') || strcmpi(atScanner,'n'),'Invalid input');
if strcmpi(atScanner,'y')
    atScanner = true;
elseif strcmpi(atScanner,'n')
    atScanner = false;
end

% If not in debug mode, generate parameters
if ~debug
    varargin = rtgetparams(subject,run);
end

% Parse command line input
p.parse(varargin{:});

% Check to see if a minimum file size was not given
if any(strcmp(p.UsingDefaults, 'minFileSize'))
    warning('The minimum file size was set by default to: 1950000 bytes. Verify that this file size is sufficiently close to your actual image file size');
end

%% Get Relevant Paths

[~, scannerPathStem, ~, ~, ~, subjectProcessedPath] = getpaths(subject,p.Results.projectName);

runPath = fullfile(subjectProcessedPath,'processed',strcat('run',run));
assert(~exist(runPath,'dir'),['Delete ' runPath ' then re-run']);
mkdir(runPath);

% Deteremine scannerPath
if atScanner
    scannerPath = fullfile(scannerPathStem,subject,strcat('run',run));
else
    scannerPath = fullfile(scannerPathStem,subject,'simulatedScannerDirectory',strcat('run',run));
end

if ~exist(scannerPath,'dir')
    mkdir(scannerPath)
end

% Grab sbref in scannerPath if none supplied
if any(strcmp(p.UsingDefaults, 'sbref'))
    warning('The sbref in scannerPath is being used by default. If this is incorrect, exit the script and select an sbref.');
    sbrefFile = fullfile(scannerPath,p.Results.sbref);
else
    sbrefFile = p.Results.sbref;
end
%% Register to First DICOM or SBREF

% If there is an sbref, register to that. Else register to first DICOM.
if ~isempty(sbrefFile)
%     [initialDirSize,roiEpiName,scoutNifti] = registerfirstimage(subject,run,scannerPath,'sbref',p.Results.sbref,'brainFileFormat',p.Results.brainFileFormat,'roiName',p.Results.roiName);
    setuproi(subject,run,p.Results.projectName,sbrefFile);
    if p.Results.checkForTrigger
        firstTriggerTime = waitfortrigger;
    end
    
% If we are registering to the first image, then we want to wait for the
% trigger first, then register.
else
    if p.Results.checkForTrigger
        firstTriggerTime = waitfortrigger;
    end

    [initialDirSize,roiEpiName,scoutNifti] = registerfirstimage(subject,run,scannerPath,runPath,'brainFileFormat',p.Results.brainFileFormat,'roiName',p.Results.roiName);
end

% Write json file containing information for other pipeline modules
globalVars.subject = subject;
globalVars.run = run;

fid = fopen(fullfile(subjectProcessedPath,'subjectParams.json'),'w');
fprintf(fid,jsonencode(globalVars));
fclose(fid);
%% Load the ROI

roiEpiName = strcat('epi_',p.Results.roiName);
scoutNifti = strcat(runPath,filesep,'new_epi.nii.gz');
initialDirSize = 1;
roiPath = fullfile(subjectProcessedPath, roiEpiName);

% Load the NIFTI located at roiPath, and turn it into a logical index
roiNiftiInfo = niftiinfo(roiPath);
roiNifti = niftiread(roiNiftiInfo);
roiIndex = logical(roiNifti);

%% Initialize figure
if p.Results.showFig
    figure;
    hold on;
end


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

    % Check for a new dicom, do some processing.
    [mainData(i).acqTime,mainData(i).dataTimepoint,mainData(i).roiSignal,...
     initialDirSize, mainData(i).dicomName] = ...
     checkfornewimage(subject,run,scannerPath,runPath,roiIndex,initialDirSize,p.Results.minFileSize,scoutNifti,p.Results.saveMatrix);

    % Normalize BOLD data
    dataPlot = [mainData.roiSignal]; % vectorize
    if std(dataPlot) ~= 0
        dataPlot = (dataPlot - mean(dataPlot))./std(dataPlot); % mean-center
    end
    dataPlot = detrend(dataPlot); % detrend

    % Simple line plot.
    cla reset;
    plot(dataPlot,'.');

    % Write out a file to the run directory each time a new mainData struct is written.
    save(fullfile(runPath,'mainData'),'mainData');
    writematrix(dataPlot,fullfile(runPath,strcat('roiMeanTimeseries_',run)));

    i = i + 1;

    pause(.01);

end
end
