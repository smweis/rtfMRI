function [targetIm] = dicomToNiftiAndWorkspace(niftiName,dicomPath,scratchPath)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.


newNiftiPath = fullfile(scratchPath,'niftis',niftiName);

% Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
% Save it in the scratchPath. 
dicm2nii(fullfile(dicomPath,niftiName),newNiftiPath,0);
newNiftiName = dir(strcat(newNiftiPath,'/*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = load_untouch_nii(newNiftiName);
targetIm = targetNifti.img;



end
