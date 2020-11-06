# rtfMRI
# Documentation for UF HiPerGator pipeline to MRI Scanners

## This document will be updated regularly to reglect the currect protocols for connecting MRI scanners to the HiPerGator

### Last edited on 10/22/2020 by Zachary Boogaart

### Protocol written with guidance from Jacob Frank and Steve Weisberg

## **Protocol:**

1. Get onto HiPerGator with preferred access method
  - MobaXterm
  - Git Bash
  - Other SSH client
2. Type into the HiPerGator client the following commands in order:
  - ml fsl mricrogl
  - ml matlab
  - matlab
3. Make a folder in your home directory
  - clone repository to this local folder
  - repository found here:
4. Set local hook
5. Run simulations or connect to scanner
6. **IF SIMULATING**
  - Go back to HiPerGator
  - put in this directory:
    - /blue/stevenweisberg/rtQuest/TOME_3021_rtMockScanner/simulatedScannerDirectory
  - Remove all previous run folders
  - go back to MATLAB
    - run NeuroFeedback with desired specs (examples are in the code)
  - look for "waiting for DICOM" from the console
  - Run bash script rtsim.sh
    - Press Enter
  - Go back to MATLAB
    - Look for "Check registration" and press key
  - Press "Enter" in MobaXterm
  - Backup the data that you want
7. **IF SCANNING** (to be edited when we talk with HiPerGator people and MRI people)
  - Ensure connection to scanner through data transfer from DICOMS
  - Ensure that connection is terminated from HiPerGator and Scanner when complete
  - Backup all data to Google Drive
