function [mainData,firstTriggerTime] = runNeurofeedback(subject,run,atScanner,varargin)

% The main function for the real-time fMRI pipeline on the scanner. 
%
% Syntax:
%   mainData = runNeurofeedback(subject,run,atScanner,varargin)
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
% Outputs:
%   mainData              - Struct. Contains the main processed fMRI data
%                           as well as time stamps. 



% Examples:

%{

% 1. rtMockScanner
% Run through a simulated scanner. Copy and paste the DICOMs from one
% directory to another to make sure all paths are set up appropriately. 

subject = 'TOME_3021_rtMockScanner';
run = '1';
atScanner = false;
sbref = ['raw' filesep 'PA_run1_SBRef.nii'];
showFig = true;
checkForTrigger = false;
mainData = runNeurofeedback(subject,run,atScanner,'sbref',sbref,'showFig',showFig,'checkForTrigger',checkForTrigger);

% 2. rtSim
% 
%}

%% Parse input
p = inputParser;

% Required input
p.addRequired('subject',@isstr);
p.addRequired('run',@isstr);
p.addRequired('atScanner',@islogical);

% Optional params
p.addParameter('sbref', 'raw/PA_run1_SBRef.nii', @isstr);
p.addParameter('showFig', true, @islogical);
p.addParameter('checkForTrigger', true, @islogical);

% Parse
p.parse( subject, run, atScanner, varargin{:});




%% Get Relevant Paths

[subjectPath, scannerPathStem, codePath, scratchPath] = getPaths(subject);

runPath = [subjectPath filesep 'processed' filesep 'run' run];

% If we're at the scanner, get the most recently created folder on the scanner path.
if atScanner
    thisSessionPath = dir(scannerPathStem); 
    thisSessionPathSorted = sortrows(struct2table(thisSessionPath),{'isdir','datenum'});
    scannerPath = strcat(table2cell(thisSessionPathSorted(end,'folder')), filesep, table2cell(thisSessionPathSorted(end,'name')));
else
    scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];
end





%% Register to First DICOM or SBREF

% If there is an sbref, register to that. Else register to first DICOM.
if ~isempty(p.Results.sbref)
    sbrefFullPath = [subjectPath filesep p.Results.sbref];
    [ap_or_pa,initialDirSize] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath,sbrefFullPath);
    
    if p.Results.checkForTrigger
        firstTriggerTime = waitForTrigger;
    end


% If we are registering to the first DICOM, then we want to wait for the
% trigger first, then register. 

else
    if p.Results.checkForTrigger
        firstTriggerTime = waitForTrigger;
    end
    
    [ap_or_pa,initialDirSize] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath);
end




%% Load the ROI

roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
roiPath = [subjectPath filesep 'processed' filesep 'run' run filesep roiName];
roiIndex = loadRoi(roiPath);



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

dataPlot = [];

fprintf('Starting real-time processing sequence. To stop press CTRL+C.');

i = 0;
j = 1;
while i < 10000000000
    i = i + 1;

    % Check for a new dicom, do some processing. 
    % TO DO HERE IS TO REQUIRE checkForNewDicom to take in an anonymous
    % scannerFunction. Right now scannerFunction is an actual function that
    % just takes the mean of all voxels in the ROI. 
    [mainData(j).acqTime,mainData(j).dataTimepoint,mainData(j).roiSignal,...
     initialDirSize, mainData(j).dicomName] = ...
     checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath);
    

    % Vectorize data for plotting
    dataPlot(end+1:end+length(mainData(j).roiSignal)) = mainData(j).roiSignal;
   
    % Simple line plot. 
    plot(dataPlot,'black');
 
    % Write out a file to the run directory each time a new mainData struct is written.
    save(fullfile(runPath,'mainData'),'mainData');
 
 
    j = j + 1;
    
    pause(.01);
    
end
