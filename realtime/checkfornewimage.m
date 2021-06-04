function [acqTime,dataTimepoint,roiSignal,initialDirSize,imageNames] = checkfornewimage(subject,run, scannerPath,runPath,roiIndex,initialDirSize,minFileSize,scoutNifti,saveMatrix,varargin)
%% Check scanner path for new image(s)

% Syntax:
%  [acqTime,dataTimepoint,roiSignal,initialDirSize,imageNames] = checkfornewimage(subject,run, scannerPath,roiIndex,initialDirSize,scratchPath,minFileSize,scoutNifti,varargin)

% Description:
%  This function will check a scannerPath for new images. It does so by
%  taking in the initialDirSize of the scannerPath and comparing it to the current
%  size of the directory (imageDir).
%
%  When there is no new image, the function will be called after .01 seconds.
%  When there is (are) new image(s), it will process the last N images
%  in the scannerPath by saving them to the scratchPath as NIFTIs and
%  putting them in the workspace as targetImage with roiSignal.
%
%  Finally, this function will
%  extract the ROI (from roiIndex) and compute whatever function you want.
%  The default function is a mean over the ROI.

% Inputs:
%   scannerPath           - path to directory where new DICOMs will appear.
%                           set as part of the localHook
%   roiIndex              - logical 3D matrix that indexes the desired ROI(s)
%   initialDirSize        - the size of scannerPath when the function is
%                           first called.
%
%   scratchPath           - path to a scratch directory on the local computer.
%   minFileSize           - minimum DICOM file size in bytes
% Outputs:
%   acqTime               - time at which checkForNewDicom detected a new DICOM
%   dataTimePoint         - time after scannerFunction completed its computation.
%   roiSignal             - 1xN vector where N is the number of DICOMs found
%                           in this iteration. Each entry is the output of
%                           scannerFunction for each new DICOM.
%  intialDirSize          - as an ouput, the length of scannerPath
%  imageNames             - file names of the new DICOMs.
%% Parse input
p = inputParser;

% Required input
p.addRequired('subject');
p.addRequired('run');
p.addRequired('scannerPath',@isstr);
p.addRequired('roiIndex');
p.addRequired('initialDirSize');
%p.addRequired('scratchPath');
p.addRequired('minFileSize');
p.addRequired('scoutNifti');

% Optional params
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('sbref', '', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr)

% Parse
p.parse(subject, run, scannerPath, roiIndex, initialDirSize, minFileSize, scoutNifti, varargin{:});

% [~, ~, ~, scratchPath, ~, ~] = getpaths(subject,p.Results.projectName);


%% Start loop
newImageFound = false;

while ~newImageFound
    % Save an initial time stamp.
    acqTime = datetime;

    % Check files in scannerPath.
    imageDir = dir(strcat(scannerPath,filesep,'*',p.Results.brainFileFormat,'*'));
    imageDir = table2struct(sortrows(struct2table(imageDir),'datenum'));

    % If no new files, keep looping
    if length(imageDir) == initialDirSize
        pause(0.01);

    % If there are new files, check for the number of images missed (nMissedImages)
    % then reset the number of files in the directory (initialDirSize)
    % and then get the info of the new images (newImageArray).
    elseif length(imageDir) > initialDirSize
        nMissedImages = length(imageDir) - initialDirSize;
        initialDirSize = length(imageDir);
        newImageArray = imageDir(initialDirSize-nMissedImages+1:initialDirSize);
        newImageFound = true;
        fprintf('New file found\n');
        
        % Wait for file transfer to complete
        fileWait = true;
        initialFileSize = newImageArray(1).bytes;
        while fileWait
            pause(0.2);
            newFileSize = dir(strcat(scannerPath,filesep,newImageArray(1).name)).bytes;
            
            % If no new bytes have been written AND file size is over
            % threshold, then we say that the file transfer has finished
            if newFileSize == initialFileSize && newFileSize > minFileSize
                fileWait = false;
            else
                initialFileSize = newFileSize;
            end
        end
        
        % For each new image, convertimage() will save it as a NIFTI in the
        % scratchPath and as a targetImage in the workspace. 
        % Each loop will also save the imageName.
        tic;
        % Note: newImageArray is in ascending order according to DICOM age
        for iImage = length(newImageArray):-1:1
            imageName = newImageArray(iImage).name;
            disp(imageName);
            imagePath = imageDir(iImage).folder;
            
            % get the mean of the roi voxels
            % TODO: vectorize and write targetImage
            targetImage = convertimage(subject,run,imageName,imagePath,scoutNifti);
            roiSignal(iImage) = mean(targetImage(roiIndex));
            
            dataTimepoint(iImage) = datetime;
            imageNames{iImage} = imageName;
            
            if saveMatrix
                writematrix(targetImage(:),fullfile(runPath,strcat('roiMVPATimeseries_',run)));
            end

        end
        toc;
    end
end

end
