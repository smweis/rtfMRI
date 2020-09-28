function [targetIm] = dicomToNiftiAndWorkspace(dicomName,dicomPath,scratchPath)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.


%fileName = dicomName(1:end-4); 
newNiftiPath = fullfile(scratchPath,'niftis');
if ~exist(newNiftiPath, 'dir')
    mkdir(newNiftiPath);
end


% Convert DICOM to NIFTI (.nii)
% Save it in the scratchPath. 
% TODO: convert to `-f %s_%r
command = horzcat('dcm2niix -s y -f %s_%r -o ',newNiftiPath,' ',fullfile(dicomPath,dicomName));
    [status,cmdout] = system(command);
if status ~= 0
    error('Could not convert dicom to nifti. Perhaps dcm2niix is not installed?\n %s',cmdout);
end

disp(cmdout)
% Parse output of NIFTI conversion and extract new filename
pattern = regexp(cmdout, strcat(newNiftiPath, '/.*'), 'match');
tokens = regexp(pattern{1}, '\s', 'split');
% filePath = regexp(tokens{1}, '/', 'split');
filePath = tokens{1};

% Load nifti into MATLAB
newNiftiName = dir(strcat(filePath,'*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = niftiinfo(newNiftiName);
targetIm = niftiread(targetNifti);



end
