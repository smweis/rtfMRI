#!/bin/bash

FSLDIR=/usr/local/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH



# Arguments:
sub_dir=$1
newEPI=$2
scoutEPI_masked=$3
roi_epi=$4



# Calculate first registration between T1 and standard (MNI)
flirt -in $t1_masked -ref $mni -omat $sub_dir/anat2standard.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12

# Calculate second registration matrix from T1 -> scout EPI
flirt -in $scout_epi_masked -ref $t1_masked -omat $sub_dir/coreg2anat.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# Invert those matrices
convert_xfm -omat $sub_dir/standard2anat.mat -inverse $sub_dir/anat2standard.mat
convert_xfm -omat $sub_dir/anat2coreg.mat -inverse $sub_dir/coreg2anat.mat

# Concatenate these two registration matrices
convert_xfm -omat $sub_dir/standard2coreg.mat -concat $sub_dir/standard2anat.mat  $sub_dir/anat2coreg.mat

# Apply transform to ROI
flirt -in $roi_template -ref $scout_epi_masked -out $roi_epi -applyxfm -init $sub_dir/standard2coreg.mat -interp trilinear

# Binarize mask
fslmaths $roi_epi -bin $roi_epi


newEPI_masked=${newEPI}_masked
bet $newEPI ${newEPI}_masked -R

##########################
# registration
##########################

# register first volume of old functional scan to new functional scan
flirt -in $newEPI_masked -ref $run_dir/${newNifti}_bet -omat $run_dir/new2old"$1".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# apply registration to v1 parcel(s)
flirt -in $subject_dir/ROI_to_"$1"_bin.nii.gz -ref $run_dir/${newNifti}_bet -out $run_dir/ROI_to_new"$1".nii.gz -applyxfm -init $run_dir/new2old"$1".mat -interp trilinear

#binarize mask again
fslmaths $run_dir/ROI_to_new"$1".nii.gz -bin $run_dir/ROI_to_new"$1"_bin.nii.gz
