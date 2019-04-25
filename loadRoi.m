function ROIIndex = loadRoi(roiPath)
% Load the NIFTI located at roiPath, and turn it into a logical index
roiNifti = load_untouch_nii(roiPath);
ROIIndex = roiNifti.img;
ROIIndex = logical(ROIIndex);
