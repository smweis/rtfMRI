function [maskFullFile,saveName] = makeMaskFromRetino(eccen, areas, angles, areaNum,eccenRange,anglesRange,savePath, varargin);
%makeMaskFromRetino -- Makes a mask from the intersect of areas and eccentrity 
%                      maps from the Benson template (NEUROPYTHY).
%
% Inputs:
%   eccen      -- The eccentricity map read in with MRIread (freesurfer)
%   areas      -- The visual area map read in with MRIread (freesurfer)
%   angles
%   areaNum    -- The visual area label number (V1 = 1, V2 = 2, V3 = 3)
%   eccenRange -- The ranage of ecctricity 
%   anglesRange 
%   savePath   -- Path to the directory where the mask will be saved
%
% Outputs:
%   maskFullFile -- Full file of the nifti mask saved by MRIwrite
%
% Key Value Pairs:
%   none
%
% Usage:
%   maskFullFile = makeMaskFromRetino(eccen,areas,areaNum,eccenRange,savePath);

% MAB 2018 -- wrote function

p = inputParser; p.KeepUnmatched = true;

p.addParameter('laterality',[], @isstruct);
p.addParameter('saveName',['mask_area_V', num2str(areaNum), '_ecc_', num2str(eccenRange(1)), '_to_', num2str(eccenRange(2)), '.nii.gz'], @ischar);


p.parse(varargin{:});


% check that the marticies are the same size 
% if this fails check the voxel resolutions
assert(all(size(eccen.vol) == size(areas.vol)))

% Restrict to voxel bewteen min and max eccentricity
eccMap = zeros(size(eccen.vol));
eccMap(eccen.vol >= eccenRange(1) & eccen.vol <= eccenRange(2)) =  1;

% Restrict to voxels between min and max polar angle
anglesMap = zeros(size(angles.vol));
anglesMap(angles.vol >= anglesRange(1) & angles.vol <= anglesRange(2)) =  1;

% Restrict to voxel of a particular visual area
areaMap = zeros(size(areas.vol));
areaMap(areas.vol == areaNum) =  1;

if ~isempty(p.Results.laterality)
    lateralityMap = zeros(size(p.Results.laterality.vol));
    lateralityMap(p.Results.laterality.vol == 1) = 1;
end


% Take the intercest of area and eccen
mask = zeros(size(eccMap));
if isempty(p.Results.laterality)
    mask(areaMap == 1 & eccMap == 1 & anglesMap) = 1;
else
    mask(areaMap == 1 & eccMap == 1 & anglesMap == 1 & lateralityMap ) = 1;
end


%% Save mask out as nifti

% get proper fields form a prior nifti
maskNii = eccen;


% set save name
saveName = p.Results.saveName;
maskFullFile = fullfile(savePath,saveName);

% set fileds with correct info
maskNii.fspec = maskFullFile;
maskNii.vol = mask;

% save file
MRIwrite(maskNii,maskFullFile,'float');

end