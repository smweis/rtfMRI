function neurofeedbackLocalHook
%  neurofeedbackLocalHook
%
% Configure things for working on the neurofeedback project.
%
% For use with the toolboxToolbox.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localHookFolder/neurofeedbackLocalHook.m
%
% Each time you run tbUseProject('neurofeedback'), ToolboxToolbox will
% execute your local copy of this file to do setup.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


%% Say hello.
fprintf('neurofeedback local hook.\n');
projectName = 'neurofeedback';

%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify base paths for materials and data
% currentSubjectBasePath: current subject directory on the local machine. 
% projectBasePath: directory containing neurofeedback toolbox code and data

[~, userID] = system('whoami');
userID = strtrim(userID);
switch userID
    case {'iron'}
        currentSubjectBasePath = [filesep 'Users' filesep, userID filesep 'Documents' filesep 'rtQuest'];
        projectBasePath = [filesep 'Users' filesep userID filesep 'Documents' filesep 'MATLAB' filesep 'projects' filesep projectName];
    case {'stevenweisberg'}
        currentSubjectBasePath = [filesep 'blue' filesep, userID filesep 'rtQuest'];
        projectBasePath = [filesep 'blue' filesep userID filesep userID filesep 'MATLAB' filesep 'projects' filesep projectName];
        analysisScratchDir = [filesep 'blue' filesep 'stevenweisberg' filesep userID filesep 'analysisScratch'];
    otherwise
        currentSubjectBasePath = [filesep 'blue' filesep, 'stevenweisberg' filesep 'rtQuest'];
        projectBasePath = [filesep 'blue' filesep 'stevenweisberg' filesep userID filesep 'MATLAB' filesep 'projects' filesep projectName];
        analysisScratchDir = [filesep 'blue' filesep 'stevenweisberg' filesep userID filesep 'analysisScratch'];
end


%% Generate a parallel pool of workers, based on the number of logical cores on your system
% To find out how many you have look at logical cores: 
% feature('numCores'); 

% first check if one is running, then create one if not
nfPool = gcp('nocreate');
if size(nfPool) == 0
    nfPool = parpool(8);
end

%% Try to log into the scanner computer
% At Penn, get this information from Mark Elliot
username = 'dummy';
password = 'dummy';
serverIP = 'dummy';

mountPoint = '/tmp/realTime';
mkdir(mountPoint);
command = ['mount -t smbfs //' username ':' password '@' serverIP filesep 'rtexport ' mountPoint];

status = system(command);
if status == 0
    fprintf(strcat('Success, server mounted at: ',mountPoint));
    scannerBasePath = [mountPoint filesep 'RTexport_Current' filesep];
  
else
    fprintf('No server access. Test data path enabled.');
    scannerBasePath = currentSubjectBasePath;
end


%% Specify where output goes
% These prefs are used by the real-time fMRI pipeline and are all on the
% local machine. 

if ismac
    % Code to run on Mac plaform
    setpref(projectName,'analysisScratchDir',[filesep 'tmp' filesep 'neurofeedback']);
    setpref(projectName,'projectRootDir',projectBasePath);
    setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
    setpref(projectName,'scannerBasePath',scannerBasePath);
    
    % SET FSL Directory
    fsl_path = [filesep 'usr' filesep 'local' filesep 'fsl' filesep];
    setenv('FSLDIR',fsl_path);
    setenv('FSLOUTPUTTYPE','NIFTI_GZ');
    curpath = getenv('PATH');
    setenv('PATH',sprintf('%s:%s',fullfile(fsl_path,'bin'),curpath));

elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'analysisScratchDir',analysisScratchDir);
    setpref(projectName,'projectRootDir',projectBasePath);
    setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
    setpref(projectName,'scannerBasePath',scannerBasePath);
    
    % Load packages for data analysis on Hipergator. 
    system('module load mricrogl');
    system('module load fsl');
    
elseif ispc
    % Code to run on Windows platform
    warning('No support for PC')
else
    disp('What are you using?')
end
