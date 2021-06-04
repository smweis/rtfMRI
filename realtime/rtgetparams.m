function c = rtgetparams()
%% Set parameter values
% Comment out variables if you wish to use the default value


loadParams = input('Choose params file [1] or generate one [2]: ','s');
if strcmp(loadParams,'1')
    % Load  parameters
    [file,path] = uigetfile('.json');
    fid = fopen(fullfile(path,file),'rt');
    raw = fread(fid,inf);
    str = char(raw');
    fclose(fid);
    p = jsondecode(strrep(str,'\','\\')); % add escape chars
    
    disp(horzcat('Imported ',file));
    
    % determine which sbref to use
    chooseSbref = input('Would you like to choose a new sbref? [y/n]: ','s');
    if strcmpi(chooseSbref,'y')
        disp('Selecting SBREF...');
        [file,path] = uigetfile('*.nii*','Select SBREF');
        if file ~= 0
            p.sbref=[path file];
        end
    elseif strcmpi(chooseSbref,'n')
        disp('Using imported SBREF');
    else
        warning('Invalid input. Please select an SBREF.');
        disp('Selecting SBREF...');
        [file,path] = uigetfile('*.nii*','Select SBREF');
        if file ~= 0
            p.sbref=[path file];
        end
    end
elseif strcmp(loadParams,'2')
    disp('Selecting SBREF...');
    [file,path] = uigetfile('*.nii*','Select SBREF');
    if file ~= 0
        p.sbref=[path file];
    end
    %p.roiName='';
    p.showFig=true;
    p.checkForTrigger=true; % flag for waiting on scanner trigger to begin
    p.minFileSize=2900000; % minimum image file size expected (rought underestimate)
    p.projectName='neurofeedback'; % name of project (for use in paths)
    p.brainFileFormat='.nii'; % expected image file format (dcm or nii)
    p.saveMatrix=false; % flag for saving MVPA vector to file
    
    disp('Choose a location to save the params file [subjectProcessedPath/]');
    selPath = uigetdir;
    fid = fopen(fullfile(selPath,'rtParams.json'),'wt');
    fprintf(fid,jsonencode(p));
    fclose(fid);
else
    error('Invalid input');
end

% Formatting
f = fieldnames(p);
p = struct2cell(p);
d = [f(:),p(:)].';
c = rot90(d(:));
end
