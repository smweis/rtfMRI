% A script to test the functionality of the pipeline


disp("This script will provide a test for the functionality of rtfmri.");
disp("Currently, this script assumes that you have an SBREF file. Be sure to specify its name in your parameters (i.e. getparams)");
disp("You will need two MATLAB instances open for this test. One will be running this test, while the other runs rtfmri.");
subject = 'test';
run = '0';

% Set up paths
[~,scannerPathStem,~,~,~,~] = getpaths(subject,'neurofeedback');
scannerPath = [scannerPathStem filesep subject filesep 'simulatedScannerDirectory' filesep 'run' run];

if ~exist(scannerPath,'dir')
    mkdir(scannerPath);
end

rawImagePath = "tests\imgs\";
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
    pause(1);
end
    
    
