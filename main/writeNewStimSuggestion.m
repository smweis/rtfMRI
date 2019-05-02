function writeNewStimSuggestion(newStimSuggestion,pathToNewStimTextFiles)
% Writes a newStimSuggestion (an integer) to a text file, (name of which is 
% specified in pathToNewStimTextFile. 

if ~isnumeric(newStimSuggestion)
    error('newStimSuggestion is an unsupported type');
end

% How many text files exist in the directory?
nextStimNum = length(dir(horzcat(pathToNewStimTextFiles,'/nextStimuli*.txt'))) + 1;
% Title this stim suggestion 1 after the last one. 
nextStimFileName = horzcat('nextStimuli',num2str(nextStimNum),'.txt');
nextStimFullPath = fullfile(pathToNewStimTextFiles,nextStimFileName);
fid = fopen(nextStimFullPath,'w');
fprintf(fid,'%2.2f',newStimSuggestion);
fclose(fid);

end