function c = params()

% p.subject='sub-102';
% p.run=2;
% p.atScanner=false;
p.sbref='';
p.roiName='';
p.showFig=true;
p.checkForTrigger=true;
p.minFileSize=2900000;
p.projectName='neurofeedback';
p.brainFileFormat='.nii';

% if not(ischar(p.subject)); error('subject must be a string'); end
% if not(isnumeric(p.run)); error('run must be an integer'); end
% if not(islogical(p.atScanner)); error('atScanner must be logical'); end
if not(ischar(p.sbref)); error('sbref must be a string'); end
if not(ischar(p.roiName)); error('roiName must be a string'); end
if not(islogical(p.showFig)); error('showFig must be logical'); end
if not(islogical(p.checkForTrigger)); error('checkForTrigger must be logical'); end
if not(isnumeric(p.minFileSize)); error('minFileSize must be an integer'); end
if not(ischar(p.projectName)); error('projectName must be a string'); end
if not(ischar(p.brainFileFormat)); error('brainFileFormat must be a string'); end
f = fieldnames(p);
p = struct2cell(p);
d = [f(:),p(:)].';
c = rot90(d(:));
% for i = 1:length(p)*2:2
%     c{end+1} = f{i};
%     c{end+2} = p{i};
% end
end
