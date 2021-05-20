function [bidsPath, scannerPath, codePath, scratchPath, subjectAnatPath, subjectProcessedPath] = getpaths(subject,projectName)
% Get all relevant paths for experiment

% Path where new DICOMs will come in.
scannerPath = getpref(projectName,'scannerBasePath');

% Path to subject-relevant files (like their MPRAGE and scout images)
bidsPath = getpref(projectName, 'currentSubjectBasePath');
subjectAnatPath = fullfile(bidsPath,'derivatives','fmriprep',subject,'anat');

subjectProcessedPath = fullfile(bidsPath,'derivatives','realTime',subject);

if ~isfolder(subjectProcessedPath)
    mkdir(subjectProcessedPath)
end

% Path to the scratch directory for saving NIFTIs temporarily and locally.
scratchPath = getpref(projectName, 'analysisScratchDir');

% Path to the repository.
projectRootPath = getpref(projectName,'projectRootDir');

codePath = fullfile(projectRootPath,'..','..','toolboxes','rtfmri');

end
