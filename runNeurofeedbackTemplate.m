


%% Either edit these variables here, or input them each time.
%subject = input('Subject number?','s');
%run = input('Which run?','s');
%sbrefQuestion = input('Is there an sbref (y or n)?','s');
realOrTest = input('At SC3T (y or n)?','s');
subject = ['TOME_3021_rtSim' filesep 'rawDicomIncoming'];
run = '1';
sbrefQuestion = 'n';

% set flags
if strcmp(sbrefQuestion,'y')
    registerToFirst = false;
    registerToSbref = true;
else
    registerToFirst = true;
    registerToSbref = false;
end

if strcmp(realOrTest,'y')
    atScanner = true;
else
    atScanner = false;
end

showFig = false;
checkForTrigger = true;


% initialize figure
if showFig
    figure;
end

%% Get Relevant Paths

[subjectPath, scannerPathStem, codePath, scratchPath] = getPaths(subject);

% If we're at the scanner, get the most recently created folder on the scanner path.
if atScanner
    thisSessionPath = dir(scannerPathStem); 
    thisSessionPathSorted = sortrows(struct2table(thisSessionPath),{'isdir','datenum'});
    scannerPath = strcat(table2cell(thisSessionPathSorted(end,'folder')), filesep, table2cell(thisSessionPathSorted(end,'name')));
else
    scannerPath = scannerPathStem;
end

%% Check for trigger

if checkForTrigger
    first_trigger_time = waitForTrigger;
end

%% Register to First DICOM or SBREF

if registerToSbref
    sbrefInput = input('Input the filename of the sbref including file type\n for example: 001_000013_000001.dcm','s');
    sbref = [scannerPath filesep sbrefInput];
    [ap_or_pa,initialDirSize] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath,sbref);
end

if registerToFirst
    [ap_or_pa,initialDirSize] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath);
end

%% Load the ROI

roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
roiPath = fullfile(subjectPath,roiName);
roiIndex = loadRoi(roiPath);


%% Main Neurofeedback Loop

% Initialize the main data struct;
mainData = struct;
mainData.acqTime = {}; % time at which the DICOM hit the local computer
mainData.dataTimepoint = {}; % time at which the DICOM was processed
mainData.dicomName = {}; % name of the DICOM
mainData.roiSignal = {}; % whatever signal is the output (default is mean)


% This script will check for a new DICOM, then call scripts that will
% convert it to NIFTI, and do some processing on the NIFTI.
% (Extract ROI, compute mean signal of the ROI).

i = 0;
j = 1;
while i < 10000000000
    i = i + 1;

    [mainData(j).acqTime,mainData(j).dataTimepoint,mainData(j).roiSignal,...
     initialDirSize, mainData(j).dicomName] = ...
     checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath);
    
    % write out a file each time a new one comes in
    save(fullfile(scratchPath,'mainData'),'mainData');
 
 
    j = j + 1;

    pause(0.01);
end
