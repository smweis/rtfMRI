# This script will take a participant's AP/PA bold scans and register a parcel to a sample scan.
# Step 1. Execute this (run from matlab script) with required variables, scan direction (AP or PA) and subj. number
#           bash register_EPI_to_EPI.sh AP [subjectDir] [runDir relative to subjectDir]




#Where are the processed pre-scan data?
subject_dir=${2}
run_dir=${2}/${3}


newNifti=new"$1".nii.gz

#extract brain new file; Robust to make sure it works.

bet $run_dir/$newNifti $run_dir/${newNifti}_bet -R


##########################
# registration
##########################

# register first volume of old functional scan to new functional scan
flirt -in $subject_dir/"$1"_first_volume.nii.gz -ref $run_dir/${newNifti}_bet -omat $run_dir/new2old"$1".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# apply registration to v1 parcel(s)
flirt -in $subject_dir/ROI_to_"$1"_bin.nii.gz -ref $run_dir/${newNifti}_bet -out $run_dir/ROI_to_new"$1".nii.gz -applyxfm -init $run_dir/new2old"$1".mat -interp trilinear

#binarize mask again
fslmaths $run_dir/ROI_to_new"$1".nii.gz -bin $run_dir/ROI_to_new"$1"_bin.nii.gz
