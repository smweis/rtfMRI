function [subjectPath, scannerPath, codePath, scratchPath] = getPaths(subject)
% Get all relevant paths for experiment

% Path where new DICOMs will come in.
scannerPath = getpref('neurofeedback','scannerBasePath');

% Path to subject-relevant files (like their MPRAGE and scout images)
subjectPath = getpref('neurofeedback', 'currentSubjectBasePath');
subjectPath = [subjectPath filesep subject];

% Path to the scratch directory for saving NIFTIs temporarily and locally.
scratchPath = getpref('neurofeedback', 'analysisScratchDir');
mkdir(scratchPath);

% Path to the repository. 
codePath = getpref('neurofeedback','projectRootDir');
codePath = [codePath filesep 'code'];

end
