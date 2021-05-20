#!/bin/bash

FSLDIR=/usr/local/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

# This script will take MPRAGE and a run of functional data from a subject, and register a parcel to the first image.
# kastner_v1_10.nii is a parcel taken from Sabine Kastner's probablistic maps of retinotopic cortex.
# It is the left/right hemisphere combined ROI for V1 that has been thresholded at 10 participants.



rawdir=/Users/nfuser/Documents/rtQuest/$1/raw;
templatedir=/Users/nfuser/Documents/rtQuest/KastnerParcels;
outputdir=/Users/nfuser/Documents/rtQuest/$1/processed;

cd $outputdir
##########################
# registration
##########################

# register MPRAGE to MNI space (where v1 parcel comes from)
flirt -in MPRAGE_bet.nii -ref /usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz -omat coreg2standard1.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12


declare -a arr=("AP" "PA")
for i in "${arr[@]}"
do

# register first volume of functional scan to MPRAGE
flirt -in "$i"_first_volume.nii -ref MPRAGE_bet.nii.gz -omat coreg2standard2"$i".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# concatenate these two registration matrices
convert_xfm -concat coreg2standard1.mat -omat coreg2standard"$i".mat coreg2standard2"$i".mat


# calculate the inverse, just in case
convert_xfm -omat standard2coreg"$i".mat -inverse coreg2standard"$i".mat


# apply registration to kastner parcel(s)
flirt -in $templatedir/kastner_v1_10.nii -ref "$i"_first_volume.nii -out ROI_to_"$i".nii -applyxfm -init standard2coreg"$i".mat -interp trilinear


#binarize mask
fslmaths ROI_to_"$i".nii -bin ROI_to_"$i"_bin.nii

done


# Spot check
fsleyes $outputdir/ROI_to_PA_bin.nii.gz
fsleyes $outputdir/ROI_to_AP_bin.nii.gz
