function [targetIm] = dicomToNiftiAndWorkspace(dicomName,dicomPath,scratchPath)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.


fileName = dicomName(1:end-4); 
newNiftiPath = fullfile(scratchPath,'niftis');
mkdir(newNiftiPath);


% Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
% Save it in the scratchPath. 
command = horzcat('dcm2niix -f ',fileName,' -o ',newNiftiPath,' ',fullfile(dicomPath,dicomName));
    [status,cmdout] = system(command);
if status ~= 0
    error('Could not convert dicom to nifti. Perhaps dcm2niix is not installed?\n %s',cmdout);
end

newNiftiName = dir(strcat(newNiftiPath,'/',fileName,'*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = niftiinfo(newNiftiName);
targetIm = niftiread(targetNifti);



end
