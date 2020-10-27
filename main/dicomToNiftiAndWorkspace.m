function [targetIm] = dicomToNiftiAndWorkspace(dicomName,dicomPath,scratchPath,scoutNifti,runPath,ap_or_pa,subjectPath)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.


newNiftiPath = fullfile(scratchPath,'niftis');
if ~exist(newNiftiPath, 'dir')
    mkdir(newNiftiPath);
end


% Convert DICOM to NIFTI (.nii)
% Save it in the scratchPath. 
command = horzcat('dcm2niix -s y -f %s_%r -o ',newNiftiPath,' ',fullfile(dicomPath,dicomName));
    [status,cmdout] = system(command);
if status ~= 0
    error('Could not convert dicom to nifti. Perhaps dcm2niix is not installed?\n %s',cmdout);
end

% Parse output of NIFTI conversion to extract filename
pattern = regexp(cmdout, strcat(newNiftiPath, '/.*'), 'match');
tokens = regexp(pattern{1}, '\s', 'split');
% filePath = regexp(tokens{1}, '/', 'split');
filePath = tokens{1};
niftiPath = strcat(filePath,'.nii');

% system(horzcat('bet ',niftiPath,' ',filePath,'_bet.nii'));

% register first volume of old functional scan to new functional scan
system(horzcat('mcflirt -in ',niftiPath,' -refvol ',scoutNifti,' -cost leastsquares -out ',niftiPath));
% apply registration to v1 parcel(s
% system(horzcat('flirt -in ',subjectPath,'/processed/ROI_to_',ap_or_pa,'_bin.nii.gz -ref ',filePath,'.nii -out ',runPath,'/ROI_to_new',ap_or_pa,'.nii.gz -applyxfm -init ',runPath,'/new2old',ap_or_pa,'.mat -interp trilinear'));
% binarize mask again
system(horzcat('fslmaths ',runPath,'/ROI_to_new',ap_or_pa,'.nii.gz -bin ',runPath,'/ROI_to_new',ap_or_pa,'_bin.nii.gz'));

%cmd = ['fsleyes ', runPath,filesep,'new',ap_or_pa,'.nii.gz ',roiPath ' &'];
%system(cmd);

% Load nifti into MATLAB
targetNifti = niftiinfo(niftiPath);
targetIm = niftiread(targetNifti);
disp(niftiPath);

end
