# Code for generateing topview videos

## Step1_createMaskSeqAll.m

- Draw the ROI of the LED in the sideview video for alignment of the time sequences.

## Step2_AlignSEQVideosAll.m

- Load the timestamps of each frame
- Align the timestampes of videos to the MED timeline
- The output is saved in `timestamps.mat`

## Step3_MakeAllVideoClips.m

- Generate video clips from the original video files from -2400 ms to 3000 ms relative to lever-press
- The videos (`Pressxxx.avi`) and meta info (`Pressxxx.mat`) are saved in the folder `VideoFrames_top`

## Step4_updateTrackingTopAll.m

- This script is used to extract the DLC data to `VideoInfos.mat` after DLC labeling is done

## plotTracking.m

- A function to plot the tracking results of the topview videos to `TopviewTracking_RatName_Session.png`
