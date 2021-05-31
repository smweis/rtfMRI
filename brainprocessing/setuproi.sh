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
#scout_epi_masked=$5
mni=$5
roi_template=$6
roi_epi=$7

# Brain extract t1 and scout EPI
bet $t1 $t1_masked -R

# bet $scout_epi $scout_epi_masked -R


# Calculate first registration between T1 and standard (MNI)
flirt -ref $mni -in $t1_masked -omat $sub_dir/highres2standard.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12

# Calculate second registration matrix from T1 -> scout EPI
flirt -ref $t1_masked -in $scout_epi -omat $sub_dir/func2highres.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# Concatenate these two registration matrices then invert it
convert_xfm -concat $sub_dir/highres2standard.mat -omat $sub_dir/func2standard.mat $sub_dir/func2highres.mat
convert_xfm -omat $sub_dir/standard2func.mat -inverse $sub_dir/func2standard.mat

# Apply transform to ROI
flirt -in $roi_template -ref $scout_epi -out $roi_epi -applyxfm -init $sub_dir/standard2func.mat -interp trilinear

# Binarize mask
fslmaths $roi_epi -bin $roi_epi
