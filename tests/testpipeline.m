% A script to simulate the functionality of an MRI scanner

disp("This script will simulate the expected behavior of an MRI scanner");
disp("Currently, this script assumes that you have an SBREF file.");

subject = 'test';
run = '0';

% Set up paths
[~,scannerPathStem,~,~,~,~] = getpaths(subject,'neurofeedback');
scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];

if ~exist(scannerPath,'dir')
    mkdir(scannerPath);
end

rawImagePath = "tests\imgs\functional";
rawImageDir = dir(rawImagePath);
rawImageDir = rawImageDir(3:end);

% sort struct by aquisition time
rawImageDir = table2struct(sortrows(struct2table(rawImageDir),'datenum'));

iImage = 2;
try
    copyfile(strcat(rawImagePath,"sbRef*"),scannerPath);
    disp("Copied SBREF");
catch
    warning("No SBREF found.");
    copyfile(strcat(rawImagePath,rawImageDir(iImage).name),scannerPath);
    iImage = iImage + 1;
end

disp("Press any key to begin");
pause;

for i = iImage:length(rawImageDir)
    copyfile(strcat(rawImagePath,rawImageDir(i).name),scannerPath);
    disp(strcat("Copied ",rawImageDir(i).name));
    pause(1);
end
    
    
