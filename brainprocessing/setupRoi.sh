#!/bin/bash

FSLDIR=/usr/local/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH


# Arguments:
sub_dir=$1
t1=$2
t1_masked=$3
scout_epi=$4
scout_epi_masked=$5
mni=$6
roi_template=$7
roi_epi=$8



# Brain extract t1 and scout EPI
bet $t1 $t1_masked -R

bet $scout_epi $scout_epi_masked -R


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
