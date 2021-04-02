function setupRoi(roiName,subject,projectName,scoutEPIName,varargin)
%setupRoi will take pre-processed data and an ROI in a specified
%space to preparing all data for the pre-real-time fMRI scan. 

% setupRoi will first register the ROI from its space to subject's EPI
% space. 

%% Parse input
p = inputParser;

% Required input
p.addRequired('roiName',@isstr);
p.addRequired('subject',@isstr);
p.addRequired('projectName',@isstr);
p.addRequired('scoutEPIName',@isstr);

% Parse
p.parse( roiName,subject,projectName,scoutEPIName,varargin{:});

%% Load in ants, fsl, mricron
% If it's in subject's space, it should go to MNI space. 
system('ml ants');
system('ml fsl');
system('ml mricron');
system('ml afni');

% % Set up paths
%[bidsPath, ~,~,~, subjectAnatPath, subjectProcessedPath] = getPaths(subject,projectName);
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



% Where are all the files
T1 = fullfile(subjectAnatPath,strcat(subject,'_desc-preproc_T1w.nii.gz'));
T1_masked = fullfile(subjectProcessedPath,'T1_masked.nii.gz');
scoutEPI = fullfile(subjectProcessedPath,'scoutEPI.nii.gz');
scoutEPI_masked = fullfile(subjectProcessedPath,'scoutEPI_masked.nii.gz');
MNI = fullfile(bidsPath,'derivatives','templates','MNI152lin_T1_1mm_brain.nii.gz');
roiTemplate = fullfile(bidsPath,'derivatives','templates',roiName);
roiEPI = fullfile(subjectProcessedPath,strcat('epi_',roiName));


if ~isfile(T1_masked)
    % Extract T1 brain
    command = sprintf('bet %s %s -R', T1, T1_masked);
    fprintf(command);
    fprintf('\n');
    system(command);
end

command = sprintf('bet %s %s',scoutEPI, scoutEPI_masked);
system(command);

if ~isfile(sprintf('%s/anat2standard.mat',subjectProcessedPath))
    % Calculate first registration matrix from MNI -> T1
    command = sprintf('flirt -in %s -ref %s -omat %s/anat2standard.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12',T1_masked, MNI,subjectProcessedPath);
    fprintf(command);
    fprintf('\n');
    system(command);
end

if ~isfile(sprintf('%s/coreg2anat.mat',subjectProcessedPath))
    % Calculate second registration matrix from T1 -> scout EPI
    command = sprintf('flirt -in %s -ref %s -omat %s/coreg2anat.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6',...,
        scoutEPI_masked,T1_masked,subjectProcessedPath);
    fprintf(command);
    fprintf('\n');
    system(command);
end

% Invert those matrices
command = sprintf('convert_xfm -omat %s/standard2anat.mat -inverse %s/anat2standard.mat',subjectProcessedPath,subjectProcessedPath);
system(command);
command = sprintf('convert_xfm -omat %s/anat2coreg.mat -inverse %s/coreg2anat.mat',subjectProcessedPath,subjectProcessedPath);
system(command);


% Concatenate these two registration matrices
command = sprintf('convert_xfm -omat %s/standard2coreg.mat -concat %s/standard2anat.mat  %s/anat2coreg.mat',subjectProcessedPath,subjectProcessedPath,subjectProcessedPath);
fprintf(command);
fprintf('\n');
system(command);

% Apply transform to ROI
command = sprintf('flirt -in %s -ref %s -out %s -applyxfm -init %s/standard2coreg.mat -interp trilinear',roiTemplate,scoutEPI_masked,roiEPI,subjectProcessedPath); 
fprintf(command);
fprintf('\n');
system(command);

% Binarize mask
command = sprintf('fslmaths %s -bin %s',roiEPI,roiEPI);
fprintf(command);
fprintf('\n');
system(command);

% Spot check
system(sprintf('mricron %s -o %s',scoutEPI_masked,roiEPI));


end

