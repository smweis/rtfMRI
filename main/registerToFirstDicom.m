function [apOrPa,dirLengthAfterRegistration] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath,varargin)
% Register to the real time fmri sequence
%
%
%
%
% Syntax:
%  [apOrPa,dirLengthAfterRegistration] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath,varargin)
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
p.addRequired('subjectPath',@isstr);
p.addRequired('run',@isstr);
p.addRequired('scannerPath',@isstr);
p.addRequired('codePath',@isstr);

% Optional params
p.addParameter('sbref', '', @isstr);

% Parse
p.parse( subject, subjectPath, run, scannerPath, codePath, varargin{:});

if isempty(p.Results.sbref)
    % Wait for the initial dicom
    initial_dir = dir([scannerPath filesep '*00001.dcm']); % count all the FIRST DICOMS in the directory
    fprintf('Waiting for first DICOM...\n');

    while(1)
        % Check files in scannerPath
        new_dir = dir([scannerPath filesep '*00001.dcm']);
        % If there's a new FIRST DICOM
        if length(new_dir) > length(initial_dir)
          fprintf('Performing registration on first DICOM\n');

          %% Complete Registration to First DICOM
            % Save this to initialize the check_for_new_dicoms function
            reg_dicom_name = new_dir(end).name;
            reg_dicom_path = new_dir(end).folder;
            dirLengthAfterRegistration = length(dir(scannerPath));
            reg_dicom = fullfile(reg_dicom_path,reg_dicom_name);
            break
        else
            pause(0.01);
        end
    end
else
    % If there's an sbref, set that image as the one to register
    reg_dicom = p.Results.sbref;
    fprintf('Performing registration on SBREF\n');

    %% Complete Registration to First DICOM
    dirLengthAfterRegistration = length(dir(strcat(scannerPath,'*.dcm')));
end






% Create the directory on the local computer where the registered
% images will go
reg_image_dir = strcat(subjectPath,filesep,'processed',filesep,'run',run);
if exist(reg_image_dir,'dir')
    error(['Delete ' reg_image_dir ' then re-run']);
else
    mkdir(reg_image_dir);
end


% convert the first DICOM to a NIFTI
if isempty(p.Results.sbref)
    command = strcat('dcm2niix -z y -o ',reg_image_dir, ' ',reg_dicom);
    [status,cmdout] = system(command);
    if status ~= 0
        error('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout);
    end
    
    old_dicom_dir = dir(strcat(reg_image_dir,filesep,'*.nii*'));
    old_dicom_name = old_dicom_dir.name;
    old_dicom_folder = old_dicom_dir.folder;
else
    if strcmp(p.Results.sbref,'*dcm*')
        command = strcat('dcm2niix -z y -o ',reg_image_dir,' ',p.Results.sbref);
        [status,cmdout] = system(command);
        fprintf(cmdout);
        if status ~= 0
            error('Could not convert dicom to nifti. Perhaps dicm2niix is not installed?\n %s',cmdout);
        end
    end
    old_dicom_dir = dir(strcat(reg_image_dir,filesep,'*.nii*'));
    old_dicom_name = p.Results.sbref;
    old_dicom_folder = subjectPath;
    disp(['The name of the sbref file is' old_dicom_name]);
end

% Check if this is a PA sequence or an AP sequence (based on the
% name of the acquisition). If neither, return empty string.
ap_check = strfind(old_dicom_name,'AP');
pa_check = strfind(old_dicom_name,'PA');
if ap_check
    apOrPa = 'AP';
elseif pa_check
    apOrPa = 'PA';
else
    apOrPa = '';
end


copyfile(fullfile(old_dicom_folder,old_dicom_name),strcat(reg_image_dir,filesep,'new',apOrPa,'.nii.gz'));

% grab path to the bash script for registering to the new DICOM
pathToRegistrationScript = fullfile(codePath,'realTime','main','registerEpiToEpi.sh');

% run registration script name as: register_EPI_to_EPI.sh AP TOME_3040
cmdStr = [pathToRegistrationScript ' ' apOrPa ' ' subject ' run', run];
system(cmdStr);

fprintf('Registration Complete. \n');


end
