function setupRoi(roiName,subject,projectName,scoutEPIName,varargin)
%setupRoi will take pre-processed data and an ROI in a specified
%space to preparing all data for the pre-real-time fMRI scan.

% setupRoi will first register the ROI from its space to subject's EPI
% space.

%% Example: 
%{

setupRoi('kastner_v1lh_10.nii','sub-102','neurofeedback','scoutEPI.nii');

%}

%% Parse input
p = inputParser;

% Required input
p.addRequired('roiName',@isstr);
p.addRequired('subject',@isstr);
p.addRequired('projectName',@isstr);
p.addRequired('scoutEPIName',@isstr);

% Parse
p.parse( roiName,subject,projectName,scoutEPIName,varargin{:});

% % Set up paths
[bidsPath, ~,codePath,~, ~, subjectProcessedPath] = getPaths(subject,projectName);


% Where are all the files

[~,subjectProcessedPath] = system(sprintf('wsl --exec wslpath %s',subjectProcessedPath));
[~,bidsPath] = system(sprintf('wsl --exec wslpath %s',bidsPath));
subjectProcessedPath = subjectProcessedPath(1:end-1);
bidsPath = bidsPath(1:end-1);

T1 = [subjectProcessedPath strcat('/',subject,'_desc-preproc_T1w.nii.gz')];
T1_masked = [subjectProcessedPath '/T1_masked.nii.gz'];
scoutEPI = [subjectProcessedPath '/scoutEPI.nii.gz'];
scoutEPI_masked = [subjectProcessedPath '/scoutEPI_masked.nii.gz'];
MNI = [bidsPath '/derivatives/templates/MNI152_T1_1mm_brain.nii.gz'];
roiTemplate = [bidsPath '/derivatives/templates/' roiName];
roiEPI = [subjectProcessedPath strcat('/epi_',roiName)];


cd(codePath)


system(sprintf('wsl --exec ./brainProcessing/setupRoi.sh %s %s %s %s %s  %s %s %s',...,
subjectProcessedPath, T1, T1_masked, scoutEPI, scoutEPI_masked, MNI, roiTemplate, roiEPI)'-echo');



% Hipergator version:
%% Load in ants, fsl, mricron
% If it's in subject's space, it should go to MNI space.
% system('ml ants');
% system('ml fsl');
% system('ml mricron');
% system('ml afni');
%
% % Where is the scout MPRAGE data?
% T1 = fullfile(subjectAnatPath,strcat(subject,'_desc-preproc_T1w.nii.gz'));
% T1_brain_mask = fullfile(subjectAnatPath,strcat(subject,'_desc-brain_mask.nii.gz'));
%
% MNI_anat = fullfile(subjectAnatPath,strcat(subject,'_space-',p.Results.space,'_desc-preproc_T1w.nii.gz'));
%
% % The template and realTime data is separate
% roiTemplate = fullfile(bidsPath,'derivatives','templates',roiName);
%
%
% % Mask brain
% T1_masked = fullfile(subjectProcessedPath,'T1_masked.nii.gz');
% command = sprintf('fslmaths %s -mul %s %s',T1,T1_brain_mask,T1_masked);
% system(command);
%
% % Register ROI to from MNI space to MPRAGE space.
% transformMat = sprintf('%s_from-%s_to-T1w_mode-image_xfm.h5',subject,p.Results.space);
% transformMat = fullfile(subjectAnatPath,transformMat);
%
% % What to name the ROI?
% roiT1 = sprintf('%s_%s.gz',subject,roiName);
% roiT1 = fullfile(subjectProcessedPath,roiT1);
% command = sprintf('antsApplyTransforms -i %s -t %s -o %s -r %s -v',...,
%                    roiTemplate, transformMat, roiT1, MNI_anat);
% system(command);
%
% % View anatomical ROI.
% command=sprintf('mricron %s -o %s', T1_masked, roiT1);
% system(command);
%
%
% Spot check
% system(sprintf('mricron %s -o %s',scoutEPI_masked,roiEPI));




end
