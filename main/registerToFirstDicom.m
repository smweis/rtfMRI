function [apOrPa,dirLengthAfterRegistration] = registerToFirstDicom(subject,subjectPath,whichRun,scannerPath,codePath,sbref)
% Register to the real time fmri sequence
%
%
%
%
% Syntax:
%  [apOrPa,dirLengthAfterRegistration] = registerToFirstDicom(subject,subjectPath,whichRun,scannerPath,codePath,sbref)
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
%   whichRun                    - integer specifying run number
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


    if nargin < 6
        % Wait for the initial dicom
        initial_dir = dir([scannerPath filesep '*00001.dcm']); % count all the FIRST DICOMS in the directory
        fprintf('Waiting for first DICOM...\n');
        
        while(1)
            % Check files in scannerPath
            new_dir = dir([scannerPath filesep '*00001.dcm']); 
            % If there's a new FIRST DICOM
            if length(new_dir) > length(initial_dir) 
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
        reg_dicom = sbref;
        dirLengthAfterRegistration = 0;
    end
    
    
    
    
        fprintf('Performing registration on first DICOM\n');
        
        %% Complete Registration to First DICOM
        
        % Create the directory on the local computer where the registered
        % images will go
        reg_image_dir = strcat(subjectPath,filesep,'processed',filesep,'run',whichRun);
        mkdir(reg_image_dir);
        
        % convert the first DICOM to a NIFTI
        if strcmp(reg_dicom,'dcm')
            dicm2nii(reg_dicom,reg_image_dir);
            old_dicom_dir = dir(strcat(reg_image_dir,filesep,'*.nii*'));
            old_dicom_name = old_dicom_dir.name;
            old_dicom_folder = old_dicom_dir.folder;
        else
            old_dicom_name = sbref;
            old_dicom_folder = '';
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
        cmdStr = [pathToRegistrationScript ' ' apOrPa ' ' subject ' run', whichRun];
        system(cmdStr);
        
        fprintf('Registration Complete. \n');

    
end
