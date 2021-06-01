% A script to simulate an MRI scanner

disp("This script will simulate the expected behavior of an MRI scanner");
disp("Currently, this script assumes that you will be using an SBREF. Be sure to specify its name in your parameters (i.e. getparams)");

subject = 'test';
run = '0';

% Set up paths
[~,scannerPathStem,~,~,~,~] = getpaths(subject,'neurofeedback');
scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];

if ~exist(scannerPath,'dir')
    mkdir(scannerPath);
end

rawImagePath = "tests\imgs\functional\";
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
    disp("Start the pipeline, then press any key to register the first dicom");
    copyfile(strcat(rawImagePath,rawImageDir(iImage).name),scannerPath);
    iImage = iImage + 1;
end

disp("Press any key to begin");
pause;

for i = iImage:length(rawImageDir)
    copyfile(strcat(rawImagePath,rawImageDir(i).name),scannerPath);
    disp(strcat("Copied ",rawImageDir(i).name));
    pause(0.8);
end
    
    
