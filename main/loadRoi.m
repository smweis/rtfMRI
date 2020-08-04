function ROIIndex = loadRoi(roiPath)
% Load the NIFTI located at roiPath, and turn it into a logical index
roiNiftiInfo = niftiinfo(roiPath);
roiNifti = niftiread(roiNiftiInfo);
ROIIndex = logical(roiNifti);
