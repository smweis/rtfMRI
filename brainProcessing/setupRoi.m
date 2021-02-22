function setupRoi(roiName,subject,varargin)
%setupRoi will take fmriprep pre-processed data and an ROI in a specified
%space to preparing all data for the pre-real-time fMRI scan. 

% setupRoi will first register the ROI from its space to subject's EPI
% space. 

% To Do - add optional args for ROI name and space (MNI or other)
% Check if fmriprep has been done. 


% Minimally, we need: 

% 1 - SCOUT MPRAGE in subject's space
% 2 - SCOUT MPRAGE in MNI space
% 3 - SCOUT EPI in MPRAGE space.
% 4 

%% Parse input
p = inputParser;

% Required input
p.addRequired('roiName',@isstr);
p.addRequired('subject',@isstr);

% Optional params
p.addParameter('fmriprep',true,@islogical);
p.addParameter('space', 'MNI152NLin2009cAsym', @isstr);
p.addParameter('projectName','neurofeedback',@isstr);

% Parse
p.parse( roiName,subject,projectName, varargin{:});

%% Load in ants and fsl
% If it's in subject's space, it should go to MNI space. 
system('ml ants');
system('ml fsl');

% Right now only fmriprep supported results for this script
if ~p.Results.fmriprep
    error('Run fmriprep first');
end


% Set up paths
subjectPath = getPaths(subject,projectName);

% Where is the scout data?
T1path = fullfile(subjectPath,'derivatives',...,
                'fmriprep',subject,'anat');

T1 = strcat(subject,'_desc-preproc_T1w.nii.gz');
T1 = fullfile(T1path,T1);
T1_brain_mask = strcat(subject,'_desc-brain_mask.nii.gz');
T1_brain_mask = fullfile(T1path,T1_brain_mask);

% The template and realTime data is separate
realTimePath = fullfile(subjectPath,'derivatives','realTime',subject);                
roiTemplate = fullfile(realTimePath,'templates',roiName);


% Mask brain
T1_masked = fullfile(realTimePath,'T1_masked');
command = sprintf('fslmaths %s -mul %s %s',T1,T1_brain_mask,T1_masked);
system(command);

% Register ROI to from MNI space to MPRAGE space.
transformMat = sprintf('%s_from-%s_to-T1w_mode-image_xfm.h5',subject,p.Results.space);
transformMat = fullfile(T1path,transformMat);
% What to name the ROI?
roiTransformed = sprintf('%s_%s',subject,roi);
roiTransformed = fullfile(realTimePath,roiTransformed);
command = sprintf('antsApplytransforms -i %s -t %s -o %s -r %s -v',...,
                   roiTemplate, transformMat, roiTransformed, T1);
system(command);

% Mask ROI

% 
% system(sprintf('flirt -in %s -ref %s -omat coreg2standard2%s.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6',SCOUT_SCAN,T1_masked,i{:}));
%     
%     
% # concatenate these two registration matrices
% convert_xfm -concat coreg2standard1.mat -omat coreg2standard"$i".mat coreg2standard2"$i".mat
% 
% 
% # apply registration to kastner parcel(s)
% flirt -in $templatedir/kastner_v1_10.nii -ref "$i"_first_volume.nii -out ROI_to_"$i".nii -applyxfm -init standard2coreg"$i".mat -interp trilinear 
% 
% 
% #binarize mask
% fslmaths ROI_to_"$i".nii -bin ROI_to_"$i"_bin.nii
% 
% done
% 
% 
% # Spot check
% fsleyes $outputdir/ROI_to_PA_bin.nii.gz
% fsleyes $outputdir/ROI_to_AP_bin.nii.gz

end

