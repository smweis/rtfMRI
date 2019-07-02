# This script will take a participant's AP/PA bold scans and register a parcel to a sample scan.
# Step 1. Execute this (run from matlab script) with required variables, scan direction (AP or PA) and subj. number
#           bash register_EPI_to_EPI.sh AP TOME_3040 run1




#Where are the processed pre-scan data?
subject_dir="/Users/nfuser/Documents/rtQuest/${2}/processed"
run_dir="/Users/nfuser/Documents/rtQuest/${2}/processed/${3}"


newNifti=new"$1".nii

#extract brain new file

bet $run_dir/$newNifti $run_dir/$newNifti


##########################
# registration
##########################

# register first volume of old functional scan to new functional scan
flirt -in $subject_dir/"$1"_first_volume.nii.gz -ref $run_dir/$newNifti -omat $run_dir/new2old"$1".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# apply registration to v1 parcel(s)
flirt -in $subject_dir/ROI_to_"$1"_bin.nii.gz -ref $run_dir/$newNifti -out $run_dir/ROI_to_new"$1".nii.gz -applyxfm -init $run_dir/new2old"$1".mat -interp trilinear

#binarize mask again
fslmaths $run_dir/ROI_to_new"$1".nii.gz -bin $run_dir/ROI_to_new"$1"_bin.nii.gz
