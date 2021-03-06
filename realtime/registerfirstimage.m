function [dirLengthAfterRegistration,roiEPIName,newEPI] = registerfirstimage(subject,run,scannerPath,runPath,varargin)
% Register to the real time fmri sequence
%
% Syntax:
% [dirLengthAfterRegistration,roiEPIName,newEPI] = registerfirstimage(subject,run,scannerPath,runPath,varargin)
%
% Description:
% Part of the real-time fmri pipeline. Will apply a pre-calculated
% registration matrix to new fmri data. This will either be based on a
% single-band reference (sbref) image. Or, it will register to the
% first image collected.
%
% Inputs:
%   subject                     - string specifying subject ID
%   run                         - integer specifying run number
%   scannerPath                 - string specifying path to dicoms
%                                 (scanner)
%   runPath                    - string specifying path to run-specific dir
% Optional Input:
%   sbref                       - path and file name to the sbref image
%
% Outputs:
%   dirLengthAfterRegistration  - integer, specifying the number of files
%                                 in the directory after registration
%   roiEPIName                  - string. name of ROI in EPI space
%   roiEPI                      - string. path to ROI in EPI space
%% Parse input
p = inputParser;

% Required input
p.addRequired('subject',@isstr);
p.addRequired('run',@isstr);
p.addRequired('scannerPath',@isstr);
p.addRequired('runPath',@isstr);

% Optional params
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('sbref', '', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr)

% Parse
p.parse( subject, run, scannerPath, runPath, varargin{:});

[bidsPath, ~,codePath,~, ~,subjectProcessedPath] = getpaths(subject,p.Results.projectName);

if isempty(p.Results.sbref) % Block of code runs if NO SBREF is passed.
    % Wait for the initial dicom
    firstImageFoundInit = dir([scannerPath filesep strcat('*',p.Results.brainFileFormat)]); % count all the FIRST DICOMS in the directory
    fprintf('Waiting for first %s...\n',p.Results.brainFileFormat);
    firstImageFound = false;

    while(~firstImageFound)
        % Check files in scannerPath
        imageDir = dir([scannerPath filesep strcat('*',p.Results.brainFileFormat)]);
        % If there's a new FIRST DICOM
        if length(imageDir) > length(firstImageFoundInit)
          fprintf('Performing registration on first %s...\n',p.Results.brainFileFormat);
          firstImageFound = true;

          % Complete Registration to First DICOM
          % Save this to initialize the check_for_new_dicoms function
          registrationImageName = imageDir(end).name;
          registrationImagePath = imageDir(end).folder;
          dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'*',p.Results.brainFileFormat,'*')));
          registrationImage = fullfile(registrationImagePath,registrationImageName);
        else
            pause(0.01);
        end
    end
else
    % If there's an sbref, set that image as the one to register
    registrationImage = p.Results.sbref;
    fprintf('Performing registration on SBREF\n');

    % Complete Registration to First DICOM
    dirLengthAfterRegistration = length(dir(strcat(scannerPath,filesep,'/*',p.Results.brainFileFormat,'*')));
end

% convert the first DICOM to a NIFTI
if isempty(p.Results.sbref)
  if contains(p.Results.brainFileFormat,'dcm')
    command = horzcat('dcm2niix -z y -s y -o ',scannerPath, ' ',registrationImage);
    [status,cmdout] = system(command);
    assert(status == 0, sprintf('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout));
  end
    regsitrationImageDir = dir(strcat(scannerPath,filesep,'*.nii*'));
    registrationImage = regsitrationImageDir.name;
else
    if contains(p.Results.sbref,'*dcm*')
        command = horzcat('dcm2niix -z y -s y -o ',scannerPath,' ',p.Results.sbref);
        [status,cmdout] = system(command);
        fprintf(cmdout);
        assert(status == 0, sprintf('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout));
    end
    %regsitrationImageDir = dir(strcat(scannerPath,filesep,'*.nii*'));
    registrationImage = p.Results.sbref;
    disp(['The name of the sbref file is ' registrationImage]);
end

setuproi(subject,run,'neurofeedback',fullfile(registrationImageDir.
% Copy sbref into the run directory
newEPI = strcat(runPath,filesep,'new_epi.nii.gz');
copyfile(fullfile(scannerPath,registrationImage),newEPI);
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