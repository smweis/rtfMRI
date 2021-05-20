#!/bin/bash

FSLDIR=/usr/local/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH



# Arguments:
sub_dir=$1
run_dir=$2
newEPI=$3
scoutEPI_masked=$4
roi_template=$5
roi_epi=$6
t1_masked=$7

# Calculate second registration matrix from T1 -> new EPI
flirt -in $newEPI -ref $t1_masked -omat ${run_dir}/newEpi2anat.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# Invert that matrices
convert_xfm -omat $run_dir/anat2newEpi.mat -inverse $run_dir/newEpi2anat.mat

# Concatenate these two registration matrices
convert_xfm -omat $run_dir/standard2newEpi.mat -concat $sub_dir/standard2anat.mat  $run_dir/anat2newEpi.mat

# Apply transform to ROI
flirt -in $roi_template -ref $newEPI -out $roi_epi -applyxfm -init $run_dir/standard2newEpi.mat -interp trilinear

# Binarize mask
fslmaths $roi_epi -bin $roi_epi
