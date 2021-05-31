function setuproi(subject,projectName,varargin)
%
% Syntax:
%   setuproi(subject,projectName,varargin)
%
% Description:
%	Takes pre-processed data and an ROI in a specified
%   space and prepares all data for the pre-real-time fMRI scan. Will 
%   first register the ROI from its space to subject's EPI space.
%
% Inputs:
%   subject               - String. The name/ID of the subject.
%   projectName           - String. The name of the project
%   machine               - String. The name of the machine running the
%                                   script (local or hpg) **optional**
%
% Example: 
%    setuproi('test','neurofeedback','local');
%

%% Parse input
p = inputParser;

% Required input
% p.addRequired('roiName',@isstr);
p.addRequired('subject',@isstr);
p.addRequired('projectName',@isstr);
% p.addRequired('scoutEPIName',@isstr);

p.addParameter('machine','local',@isstr);
% Parse
p.parse(subject,projectName,varargin{:});

% % Set up paths
[bidsPath, ~,codePath,~, ~, subjectProcessedPath] = getpaths(subject,projectName);

if strcmp(p.Results.machine,'local')
    % Convert Windows paths to Linux paths for WSL
    [~,wslSubjectProcessedPath] = system(sprintf('wsl --exec wslpath %s',subjectProcessedPath));
    [~,wslBidsPath] = system(sprintf('wsl --exec wslpath %s',bidsPath));
    wslSubjectProcessedPath = wslSubjectProcessedPath(1:end-1);
    wslBidsPath = wslBidsPath(1:end-1);
    
    % Get files
    
    % Newly-acquired T1 scan. Experimenters can select it at the scanner.
    [t1File,t1Path] = uigetfile(fullfile(subjectProcessedPath,'*.nii*'),'Select T1'); 
    [~,T1] = system(sprintf('wsl --exec wslpath %s', fullfile(t1Path,t1File)));
    
    % Masked T1 image
    T1_masked = [wslSubjectProcessedPath '/T1_masked.nii.gz'];
    
    % SBREF. Experimenters should select it at the scanner.
    [scoutFile,scoutPath] = uigetfile(fullfile(subjectProcessedPath,'*.nii*'),'Select Scout EPI');
    [~,scoutEPI] = system(sprintf('wsl --exec wslpath %s',fullfile(scoutPath,scoutFile)));
    
    % MNI image. Experimenters should also be able to select this - the file should be whatever space the ROI is in.
    [refFile, refPath] = uigetfile(fullfile(bidsPath,'derivatives','templates','*.nii*'),'Select MNI');
    [~,referenceImage] = system(sprintf('wsl --exec wslpath %s', fullfile(refPath,refFile)));
    
    % ROI (same space as the MNI file). Experimenters should select this (or these). 
    [refSpaceFile, refSpacePath] = uigetfile(fullfile(bidsPath,'derivatives','templates','*.nii*'),'Select ROI template');
    [~,roiReferenceSpace] = system(sprintf('wsl --exec wslpath %s', fullfile(refSpacePath,refSpaceFile)));
    
    % ROI in EPI space
    roiEpiSpace = [wslSubjectProcessedPath strcat('/epi_',refSpaceFile)];
    
    cd(codePath)
    
    % compose WSL command and run registration script
    cmd = strcat('wsl --exec ./brainprocessing/setuproi.sh ');
    args = [' ' wslSubjectProcessedPath ' ' T1 ' ' T1_masked ' ' scoutEPI ' ' referenceImage ' ' roiReferenceSpace ' ' roiEpiSpace];
    exec = regexprep(strcat(cmd,args),'\s+',' '); % replace all newline characters with spaces
    system(exec,'-echo');
    
    %system(sprintf('wsl --exec ./brainprocessing/setupRoi.sh %s %s %s %s %s %s %s %s',...,
    %wslSubjectProcessedPath, T1, T1_masked, scoutEPI, scoutEPI_masked, MNI, roiTemplate, roiEPI),'-echo');

elseif strcmp('machine','hpg')
    % Hipergator version:
    % Load in ants, fsl, mricron
    % If it's in subject's space, it should go to MNI space.
    system('ml ants');
    system('ml fsl');
    system('ml mricron');
    system('ml afni');
    
    % % Where is the scout MPRAGE data?
    T1 = fullfile(subjectAnatPath,strcat(subject,'_desc-preproc_T1w.nii.gz'));
    T1_brain_mask = fullfile(subjectAnatPath,strcat(subject,'_desc-brain_mask.nii.gz'));
    
    MNI_anat = fullfile(subjectAnatPath,strcat(subject,'_space-',p.Results.space,'_desc-preproc_T1w.nii.gz'));
    
    % % The template and realTime data is separate
    roiTemplate = fullfile(bidsPath,'derivatives','templates',roiName);
    
    % % Mask brain
    T1_masked = fullfile(subjectProcessedPath,'T1_masked.nii.gz');
    command = sprintf('fslmaths %s -mul %s %s',T1,T1_brain_mask,T1_masked);
    system(command);
    
    % % Register ROI to from MNI space to MPRAGE space.
    transformMat = sprintf('%s_from-%s_to-T1w_mode-image_xfm.h5',subject,p.Results.space);
    transformMat = fullfile(subjectAnatPath,transformMat);
    
    % % What to name the ROI?
    roiT1 = sprintf('%s_%s.gz',subject,roiName);
    roiT1 = fullfile(subjectProcessedPath,roiT1);
    command = sprintf('antsApplyTransforms -i %s -t %s -o %s -r %s -v',...,
        roiTemplate, transformMat, roiT1, MNI_anat);
    system(command);
    
    % % View anatomical ROI.
    command=sprintf('mricron %s -o %s', T1_masked, roiT1);
    system(command);
    
    
    % Spot check
    system(sprintf('mricron %s -o %s',scoutEPI_masked,roiEPI));

else
    error('Invalid machine');
end
end
