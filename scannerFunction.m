function [roiSignal, dataTimepoint] = scannerFunction(targetIm,roiIndex)
% A filler function. Right now it will take a targetIm (a DICOM just loaded)
% and and a pre-loaded roiIndex (see extractSignal) and return the mean
% of the target area along with a timepoint at which it was computed.

roiSignal = mean(targetIm(roiIndex));

dataTimepoint = datetime;



end
