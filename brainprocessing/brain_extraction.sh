# This script will extract the brains from all relevant files
# It is recommended to do registration with an SBRef before real-time scanner acquisition. 
# bash brain_extraction.sh TOME_3040


rawdir=/Users/nfuser/Documents/rtQuest/$1/raw;
outputdir=/Users/nfuser/Documents/rtQuest/$1/processed;



##########################
# extract brains
#########################

#extract brain from MPRAGE 
bet $rawdir/MPRAGE.nii $outputdir/MPRAGE_bet.nii

# In case the image is not an SBRef and is a series of images, we will select just the first image. 
# If you skip this step, be sure to rename your nifti as in the bet command. 
fslroi $rawdir/AP_run2_SBRef.nii $outputdir/AP_first_volume.nii 0 104 0 104 0 72 0 1
bet $outputdir/AP_first_volume.nii $outputdir/AP_first_volume.nii

fslroi $rawdir/PA_run1_SBRef.nii $outputdir/PA_first_volume.nii 0 104 0 104 0 72 0 1
bet $outputdir/PA_first_volume.nii $outputdir/PA_first_volume.nii
