function [targetIm] = dicomToNiftiAndWorkspace(niftiName,dicomPath,scratchPath)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.


newNiftiPath = fullfile(scratchPath,'niftis',niftiName);

% Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
% Save it in the scratchPath. 
command = strcat('dcm2niix -z y -o ',newNiftiPath,' ',fullfile(dicomPath,niftiName));
    [status,cmdout] = system(command);
if status ~= 0
    error('Could not convert dicom to nifti. Perhaps dcm2niix is not installed?\n %s',cmdout);
end

newNiftiName = dir(strcat(newNiftiPath,'/*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = niftiinfo(newNiftiName);
targetIm = niftiread(targetNifti);



end
