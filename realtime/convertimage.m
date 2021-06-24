function [targetImage] = convertimage(subject,run,imageName,imagePath,scoutNifti,varargin)
% Converts DICOMs to NIFTIs
%
% Syntax:
%   targetImage = convertimage(subject,run,imageName,imagePath,scoutNifti,varargin)
%
% Inputs:
%   subject               - String. The name/ID of the subject.
%   run                   - String. The run or acquisition number. Will
%                           generate a folder with the string 'run' before
%                           it.
%   imageName             - String. Name of image to convert
%   imagePath             - String. Path to unconverted image
%   scoutNifti            - String. Path to scout NIFTI image
%
% Outputs:
%   targetImage           - Matrix. The converted NIFTI volume 
%
% NOTE: NIFTIs passed to this function will not undergo conversion
%% Parse input
p = inputParser;

% Required input
p.addRequired('subject');
p.addRequired('run');
p.addRequired('imageName',@isstr);
p.addRequired('imagePath');
% p.addRequired('scratchPath');
p.addRequired('scoutNifti');


% Optional params
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('sbref', '', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr)

% Parse
p.parse( subject, run, imageName, imagePath, scoutNifti, varargin{:});

[~,~,~,scratchPath,~,subjectProcessedPath] = getpaths(subject,p.Results.projectName);
runPath = strcat(subjectProcessedPath,filesep,'processed',filesep,'run',run);


if contains(p.Results.brainFileFormat,'dcm')
    newNiftiPath = fullfile(scratchPath,'niftis');
    if ~exist(newNiftiPath, 'dir')
        mkdir(newNiftiPath);
    end

    % Convert DICOM to NIFTI (.nii)
    % Save it in the scratchPath. 
    command = horzcat('dcm2niix -s y -f %s_%r -o ',newNiftiPath,' ',fullfile(imagePath,imageName));
        [status,cmdout] = system(command);
    assert(status == 0,sprintf('Could not convert dicom to nifti. Perhaps dcm2niix is not installed?\n %s',cmdout));

    % Parse output of NIFTI conversion to extract filename
    pattern = regexp(cmdout, strcat(newNiftiPath, '/.*'), 'match');
    tokens = regexp(pattern{1}, '\s', 'split');
    filePath = tokens{1};
    niftiIn = strcat(filePath,'.nii');
    niftiOut = strcat(filePath,'_out.nii.gz');
    
else
    % NIFTI files do not need to be converted
    niftiIn = fullfile(imagePath,imageName);
    niftiOut = fullfile(runPath,imageName);
end

% Register first volume of old functional scan to new functional scan
system(join(['3dvolreg -base ',scoutNifti,' -input ',niftiIn,' -prefix ',niftiOut]));

% roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
% roiPath = [subjectPath filesep 'processed' filesep 'run1' filesep roiName];
% cmd = ['fsleyes ', niftiIn,' ',roiPath, ' ', niftiOut, ' &'];
% system(cmd);
% pause;

% Load nifti into MATLAB
targetNifti = niftiinfo(niftiIn);
targetImage = niftiread(targetNifti);
disp(niftiIn);

end
