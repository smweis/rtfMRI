function [actualStimuli] = readActualStimuli(pathToActualStimuliTextFile)
% readActualStimuli takes in a path, which is the location of the
% actualStimuli.txt file, written out by the stimulus instance, and outputs
% an array of the actual stimuli presented. 
%
% Syntax:
% 
% actualStimuli = readActualStimuli('/path/ending/in/actualStimuli.txt');
% 
% Inputs:
%   path                  - string that is the path to the
%                           actualStimuli.txt file
%   
% Outputs:
%   actualStimuli          - 1xn vector where n is the number of stimuli.
%

% First, check if the file exists and has content. If it doesn't exist or
% it does exist but is empty (zero bytes), then actualStimuli = [].
% Otherwise, if it does exist and has content, then read out the content as
% integers to actualStimuli. 

if(~exist(pathToActualStimuliTextFile))
    actualStimuli = [];
else
    dirStruct = dir(pathToActualStimuliTextFile);
    if dirStruct.bytes == 0
        actualStimuli = [];
    else
        fid = fopen(pathToActualStimuliTextFile,'r');
        actualStimuli = fscanf(fid,'%d');
        fclose(fid);
    end

end