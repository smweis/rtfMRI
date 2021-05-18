function [targetIm] = dicomToNiftiAndWorkspace(subject,run,dicomName,dicomPath,scratchPath,scoutNifti,varargin)
% Function will take in a the name for NIFTI folder (from the file name of the DICOM)
% a path to where the DICOM is, and a subject's path
% and output the target image in the form of a 3d matrix.
%% Parse input
p = inputParser;

% Required input
p.addRequired('subject');
p.addRequired('run');
p.addRequired('dicomName',@isstr);
p.addRequired('dicomPath');
p.addRequired('scratchPath');
p.addRequired('scoutNifti');


% Optional params
p.addParameter('roiName','kastner_v1lh_10.nii.gz',@isstr);
p.addParameter('sbref', '', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);
p.addParameter('brainFileFormat','.nii',@isstr)

% Parse
p.parse( subject, run, dicomName, dicomPath, scratchPath, scoutNifti, varargin{:});

[~,~,~,~,~,subjectProcessedPath] = getPaths(subject,p.Results.projectName);
runPath = strcat(subjectProcessedPath,filesep,'processed',filesep,'run',run);


if contains(p.Results.brainFileFormat,'dcm')
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
    niftiIn = strcat(filePath,'.nii');
    niftiOut = strcat(filePath,'_out.nii.gz');
    
else
    niftiIn = fullfile(dicomPath,dicomName);
    niftiOut = fullfile(runPath,dicomName);
end

% register first volume of old functional scan to new functional scan
system(horzcat('3dvolreg -base ',scoutNifti,' -input ',niftiIn,' -prefix ',niftiOut));

% roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
% roiPath = [subjectPath filesep 'processed' filesep 'run1' filesep roiName];
% cmd = ['fsleyes ', niftiIn,' ',roiPath, ' ', niftiOut, ' &'];
% system(cmd);
% pause;

% Load nifti into MATLAB
targetNifti = niftiinfo(niftiIn);
targetIm = niftiread(targetNifti);
disp(niftiIn);

end
