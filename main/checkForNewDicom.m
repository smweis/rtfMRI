function [acqTime,dataTimepoint,roiSignal,initialDirSize,dicomNames] = checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath)
% Check scanner path for new DICOM(s)

%% To do 
% Add scannerFunction anonymous function handle as a required input
%
% Syntax:
%  [acqTime,dataTimepoint,roiSignal,initialDirSize,dicomNames] = checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath)

% Description:
%  This function will check a scannerPath for new DICOMs. It does so by
%  taking in the initialDirSize of the scannerPath and comparing it to the current
%  size of the directory (newDir).
%
%  When there is no new DICOM, the function will be called after .01 seconds.
%  When there is (are) new DICOM(s), it will process the last X DICOMS
%  in the scannerPath by saving them to the scratchPath as NIFTIs and
%  putting them in the workspace as targetIm with extractSignal.
%
%  Finally, this function will compute a function (scannerFunction), which will
%  extract the roi (from roiIndex) and compute whatever function you want.
%  The default function is a mean over the ROI.
%
%  The last step is computed in a parallel for loop, which will save computation time.

% Inputs:
%   scannerPath           - path to directory where new DICOMs will appear.
%                           set as part of the localHook
%   roiIndex              - logical 3D matrix that indexes the desired ROI(s)
%   initialDirSize        - the size of scannerPath when the function is
%                           first called.
%
%   scratchPath           - path to a scratch directory on the local computer.
% Outputs:
%   acqTime               - time at which checkForNewDicom detected a new DICOM
%   dataTimePoint         - time after scannerFunction completed its computation.
%   roiSignal             - 1xN vector where N is the number of DICOMs found
%                           in this iteration. Each entry is the output of
%                           scannerFunction for each new DICOM.
%  intialDirSize          - as an ouput, the length of scannerPath
%  dicomNames             - file names of the new DICOMs.

% Dependencies:
%   scannerFunction, dicomToNiftiAndWorkspace



% Save an initial time stamp.
acqTime = datetime;

% Check files in scannerPath.
newDir = dir(strcat(scannerPath,filesep,'*.dcm'));

% If no new files, call the function again
if length(newDir) == initialDirSize
    pause(0.01);
    [acqTime,dataTimepoint,roiSignal,initialDirSize,dicomNames] = checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath);


% If there are new files, check for the number of DICOMs missed (missedDicomNumber)
% then reset the number of files in the directory (initialDirSize)
% and then get the info of the new DICOMs (newDicoms).
elseif length(newDir) > initialDirSize
    missedDicomNumber = length(newDir) - initialDirSize;
    initialDirSize = length(newDir);
    newDicoms = newDir(end + 1 - missedDicomNumber:end);



% Process the DICOMs into NIFTIs in a parallel computing loop.
% For each new DICOM, dicomToNiftiAndWorkspace will save it as a NIFTI in the
% scratchPath and as a targetIm in the workspace. Then it will computed
% scannerFunction, and return the signal in the ROI (roiSignal) and a timestamp (dataTimePoint).
% Each loop will also save the dicomName.

    % tic
    parfor j = 1:length(newDicoms)
    %for j = 1:length(newDicoms)
        thisDicomName = newDicoms(j).name;
        thisDicomPath = newDir(j).folder;

        targetIm = dicomToNiftiAndWorkspace(thisDicomName,thisDicomPath,scratchPath);

        [roiSignal(j),dataTimepoint(j)] = scannerFunction(targetIm,roiIndex);

        dicomNames{j} = thisDicomName;
    end
    %toc

end

end
