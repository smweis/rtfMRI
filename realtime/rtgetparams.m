function c = rtgetparams()
%% Set parameter values
% Comment out variables if you wish to use the default value
disp('Selecting SBREF');
[file,path] = uigetfile('*.nii*','Select SBREF');
p.sbref=[path file];

%p.roiName='';
p.showFig=true;
p.checkForTrigger=true;
p.minFileSize=2900000;
p.projectName='neurofeedback';
p.brainFileFormat='.nii';

% Formatting
f = fieldnames(p);
p = struct2cell(p);
d = [f(:),p(:)].';
c = rot90(d(:));
end
