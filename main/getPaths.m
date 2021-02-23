function [subjectPath, scannerPath, codePath, scratchPath] = getPaths(subject,projectName)
% Get all relevant paths for experiment

% Path where new DICOMs will come in.
scannerPath = getpref(projectName,'scannerBasePath');

% Path to subject-relevant files (like their MPRAGE and scout images)
subjectPath = getpref(projectName, 'currentSubjectBasePath');
subjectPath = [subjectPath filesep filesep 'derivatives' filesep 'realTime' filesep subject];

% Path to the scratch directory for saving NIFTIs temporarily and locally.
scratchPath = getpref(projectName, 'analysisScratchDir');

% Path to the repository.
projectRootPath = getpref(projectName,'projectRootDir');

codePath = fullfile(projectRootPath,'..','toolboxes','rtfmri');

end
