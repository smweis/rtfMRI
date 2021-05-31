function [mainData,firstTriggerTime] = runpipeline(varargin)

% The main function for the real-time fMRI pipeline on the scanner.
%
% Syntax:
%   mainData = runpipeline(subject,run,atScanner,varargin)
%
% Description:
%	Takes in the subject and run IDs. Can either simulate the pipeline
%	based on 'fake' scanner data (a local directory of DICOMs) or based on
%	data actually being acquired at the scanner.
%
% Inputs:
%   subject               - String. The name/ID of the subject.
%   run                   - String. The run or acquisition number. Will
%                           generate a folder with the string 'run' before
%                           it.
%   atScanner             - Logical. Are you actually at the scanner?

% Optional key/value pairs:
%  'sbref'                - String. If included, the path to the sbref
%                           DICOM. If sbref is empty, will register to the
%                           first DICOM from the run.
%  'showFig'              - Logical. If true, will show a figure of the
%                           mean results.
%  'checkForTrigger'      - Logical. If true, will wait for a trigger ('t').
%
%  'minFileSize'          - Integer. The minimum size for a DICOM file in bytes.
%  'projectName'          - String. Name of project. Default =
%                           'neurofeedback'
%  'brainFileFormat'      - String. The brain image filetype (.dcm or .nii)

% Outputs:
%   mainData              - Struct. Contains the main processed fMRI data
%                           as well as time stamps.



% Examples:

%{

% 1. rtMockScanner
% Run through a simulated scanner. Copy and paste the DICOMs from one
% directory to another to make sure all paths are set up appropriately.

% To run this, copy and paste the code below into Matlab. When you are
% notified that the script is waiting for registration, copy and paste the
% 'FakeFirstDICOM0000001.dcm' file from [subject]/run1_toCopy/ to [subject]/run1
% After registration, copy and paste a set of dicoms from that same pair of
% directories.

subject = 'TOME_3021_rtMockScanner';
run = '1';
atScanner = false;
sbref = '';
showFig = true;
checkForTrigger = false;
minFileSize = 1950000;
mainData = runpipeline(subject,run,atScanner,'sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger,'minFileSize',minFileSize);

% 2. Sanity check.
subject = 'test';
run = '0';
sbref = 'GKA_0806567_201914421414111_006_000001.dcm';
atScanner = true;
showFig = true;
checkForTrigger = false;
mainData = runpipeline(subject,run,atScanner,'sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger);

% 3. Q+.
subject = 'Ozzy_Test';
run = '1';
sbref = '';
atScanner = true;
showFig = false;
checkForTrigger = false;
mainData = runpipeline(subject,run,atScanner,'sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger);

% 4. UF
% Open command prompt
% Navigate to C:\Users\jacob.frank\Documents\drinDataDumper_tobeshared_UFlorida\drinDataDumper_tobeshared_UFlorida
% run python drinDumper.py -s 10.15.208.156 -o C:\Users\jacob.frank\Documents\blue\share\rtfmri_incoming\sub-102\simulatedScannerDirectory\run1 
subject = 'sub-102';
run = '1';
sbref = 'sbRef_RT-fMR_e1_d1.nii';
atScanner = false;
showFig = true;
checkForTrigger = true;
minFileSize = 2900000;
mainData = runpipeline(subject,run,atScanner,'sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger,'minFileSize',minFileSize);
  
%}
debug = 0;
%% Parse input
p = inputParser;

% Required input
% p.addRequired('subject',@isstr);
% p.addRequired('run',@isstr);
% p.addRequired('atScanner',@islogical);

% Optional params
p.addParameter('sbref', '', @isstr);
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('showFig', true, @islogical);
p.addParameter('checkForTrigger', true, @islogical);
p.addParameter('minFileSize',1950000,@isnumeric);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr);

% if not in debug mode, generate parameters
if ~debug
    varargin = getparams();
end

% Parse
% p.parse( subject, run, atScanner, varargin{:});
p.parse(varargin{:});

% Check to see if a minimum file size was not given
if any(strcmp(p.UsingDefaults, 'minFileSize'))
    warning('The minimum file size was set by default to: 1950000 bytes. Verify that this file size is sufficiently close to your actual DICOM file size');
end

% Prompt user for input
subject = input("Subject name: ",'s');
run = input("Run #: ",'s');
assert(~isnan(str2double(run)),"Run must be an integer");
atScanner = input("Are you at the scanner (y/n): ",'s');
if strcmp(atScanner,"y")
    atScanner = true;
elseif strcmp(atScanner,"n")
    atScanner = false;
else
    error("Invalid input");
end


%% Get Relevant Paths

[~, scannerPathStem, ~, scratchPath, ~, subjectProcessedPath] = getpaths(subject,p.Results.projectName);

runPath = [subjectProcessedPath filesep 'processed' filesep 'run' run];

% If we're at the scanner, get the most recently created folder on the scanner path.
if atScanner
    thisSessionPath = dir(scannerPathStem);
    thisSessionPathSorted = sortrows(struct2table(thisSessionPath),{'isdir','datenum'});
    scannerPath = strcat(table2cell(thisSessionPathSorted(end,'folder')), filesep, table2cell(thisSessionPathSorted(end,'name')));
    scannerPath = scannerPath{1};
else
    scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];
    if ~exist(scannerPath,'dir')
        mkdir(scannerPath)
    end
end
%% Register to First DICOM or SBREF

% If there is an sbref, register to that. Else register to first DICOM.
if ~isempty(p.Results.sbref)
    [initialDirSize,roiEpiName,scoutNifti] = registerfirstimage(subject,run,scannerPath,'sbref',p.Results.sbref,'brainFileFormat',p.Results.brainFileFormat,'roiName',p.Results.roiName);

    if p.Results.checkForTrigger
        firstTriggerTime = waitfortrigger;
    end
    
% If we are registering to the first DICOM, then we want to wait for the
% trigger first, then register.
else
    if p.Results.checkForTrigger
        firstTriggerTime = waitfortrigger;
    end

    [initialDirSize,roiEpiName,scoutNifti] = registerfirstimage(subject,run,scannerPath,'brainFileFormat',p.Results.brainFileFormat,'roiName',p.Results.roiName);
end

% Write json file containing information for other pipeline modules
globalVars.subject = subject;
globalVars.run = run;

fid = fopen(fullfile(runPath,'global.json'),'w');
fprintf(fid,jsonencode(globalVars));
fclose(fid);
%% Load the ROI

roiEpiName = strcat('epi_',p.Results.roiName);
scoutNifti = strcat(runPath,filesep,'new_epi.nii.gz');
initialDirSize = 1;
roiPath = fullfile(runPath, roiEpiName);

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
     checkfornewimage(subject,run,scannerPath,roiIndex,initialDirSize,p.Results.minFileSize,scoutNifti);

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
    writematrix(dataPlot,fullfile(runPath,strcat('fMRITimeseries_',run)));

    i = i + 1;

    pause(.01);

end
end
