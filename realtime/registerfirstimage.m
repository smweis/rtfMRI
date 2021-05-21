function [dirLengthAfterRegistration,roiEPIName,newEPI] = registerfirstimage(subject,run,scannerPath,varargin)
% Register to the real time fmri sequence
%
% Syntax:
% [dirLengthAfterRegistration,oldDicomName] = registerfirstimage(subject,run,scannerPath,varargin)
%
% Description:
% Part of the real-time fmri pipeline. Will apply a pre-calculated
% registration matrix to new fmri data. This will either be based on a
% single-band reference (sbref) image. Or, it will register to the
% first DICOM collected. It will return whether the scan is AP or PA
% direction based on whether PA or AP is present in the NIFTI file name.
%
% Inputs:
%   subject                     - string specifying subject ID
%   subjectPath                 - string specifying subject path (local)
%   run                         - integer specifying run number
%   scannerPath                 - string specifying path to dicoms
%                                 (scanner)
%   codePath                    - string specifying path to neurofeedback
%                                 scripts
% Optional Input:
%   sbref                       - path and file name to the sbref image dicom
%
% Outputs:
%   apOrPa                      - string specifying whether run is in the
%                                 AP direction or the PA direction. Will
%                                 return an empty string if not applicable.
%   dirLengthAfterRegistration  - integer, specifying the number of files
%                                 in the directory after registration
%% Parse input
p = inputParser;

% Required input
p.addRequired('subject',@isstr);
p.addRequired('run',@isstr);
p.addRequired('scannerPath',@isstr);

% Optional params
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('sbref', '', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr)

% Parse
p.parse( subject, run, scannerPath, varargin{:});

[bidsPath, ~,codePath,~, ~,subjectProcessedPath] = getpaths(subject,p.Results.projectName);

% Create the directory on the local computer where the registered
% images will go
runPath = strcat(subjectProcessedPath,filesep,'processed',filesep,'run',run);
if exist(runPath,'dir')
    warning(['Delete ' runPath ' then re-run']);
else
    mkdir(runPath);
end

if isempty(p.Results.sbref) % Block of code runs if NO SBREF is passed.
    % Wait for the initial dicom
    firstDicomFoundInit = dir([scannerPath filesep strcat('*',p.Results.brainFileFormat)]); % count all the FIRST DICOMS in the directory
    fprintf('Waiting for first %s...\n',p.Results.brainFileFormat);
    firstDicomFound = false;

    while(~firstDicomFound)
        % Check files in scannerPath
        imageDir = dir([scannerPath filesep strcat('*',p.Results.brainFileFormat)]);
        % If there's a new FIRST DICOM
        if length(imageDir) > length(firstDicomFoundInit)
          fprintf('Performing registration on first %s...\n',p.Results.brainFileFormat);
          firstDicomFound = true;

          % Complete Registration to First DICOM
          % Save this to initialize the check_for_new_dicoms function
          registrationDicomName = imageDir(end).name;
          registrationDicomPath = imageDir(end).folder;
          dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'*',p.Results.brainFileFormat,'*')));
          registrationDicom = fullfile(registrationDicomPath,registrationDicomName);
          %break;
        else
            pause(0.01);
        end
    end
else
    % If there's an sbref, set that image as the one to register
    registrationDicom = p.Results.sbref;
    fprintf('Performing registration on SBREF\n');

    % Complete Registration to First DICOM
    dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'/*',p.Results.brainFileFormat,'*')));
end

% convert the first DICOM to a NIFTI
if isempty(p.Results.sbref)
  if contains(p.Results.brainFileFormat,'dcm')
    command = horzcat('dcm2niix -z y -s y -o ',scannerPath, ' ',registrationDicom);
    [status,cmdout] = system(command);
    if status ~= 0
        error('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout);
    end
  end
    oldDicomDir = dir(strcat(scannerPath,filesep,'*.nii*'));
    oldDicomName = oldDicomDir.name;
else
    if contains(p.Results.sbref,'*dcm*')
        command = horzcat('dcm2niix -z y -s y -o ',scannerPath,' ',p.Results.sbref);
        [status,cmdout] = system(command);
        fprintf(cmdout);
        if status ~= 0
            error('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout);
        end
    end
    oldDicomDir = dir(strcat(scannerPath,filesep,'*.nii*'));
    oldDicomName = p.Results.sbref;
    disp(['The name of the sbref file is ' oldDicomName]);
end


% Copy sbref into the run directory
newEPI = strcat(runPath,filesep,'new_epi.nii.gz');
copyfile(fullfile(scannerPath,oldDicomName),newEPI);
roiEPIName = strcat('epi_',p.Results.roiName);

% Determine paths
[~,subjectProcessedPath] = system(sprintf('wsl --exec wslpath %s',subjectProcessedPath));
[~,bidsPath] = system(sprintf('wsl --exec wslpath %s',bidsPath));
[~,runPath] = system(sprintf('wsl --exec wslpath %s',runPath));
subjectProcessedPath = subjectProcessedPath(1:end-1);
bidsPath = bidsPath(1:end-1);
runPath = runPath(1:end-1);

maskedScoutEPI = [subjectProcessedPath '/scoutEPI_masked.nii.gz'];
roiTemplate = [bidsPath '/derivatives/templates/' p.Results.roiName];
roiEPI = [runPath '/' roiEPIName];
newEPI = [runPath '/new_epi.nii.gz'];
maskedT1 = [subjectProcessedPath '/T1_masked.nii.gz'];

cd(codePath);

% Run registration script
[error,output] = system(sprintf('wsl --exec ./realtime/registerepitoepi.sh %s %s %s %s %s %s %s',...,
subjectProcessedPath, runPath, newEPI, maskedScoutEPI, roiTemplate, roiEPI, maskedT1),'-echo');

% Spot check
if error==0
    fprintf('Registration completed successfully. View results before continuing:\n');
    cmd = sprintf('mricron %s -o %s',newEPI,roiEPI);
    fprintf('Open WSL, then paste:\n%s\n',cmd);
else
    fprintf('Registration failed.')
    disp(output);
end
end