# EphysDLCApp
- Manually curate DeepLabCut output for video tracking.
- Label the hand that presses the lever.
- Label the lift-start frames.

## Usage
- Change directory to `./VideoFrame_camview/`
- Run `EphysDLCApp.mlapp` to start the app.
![](./doc/EphysDLCApp_side.png)
![](./doc/EphysDLCApp_top.png)
- Instructions:
  - Load Video: start this app by load a video in `./VideoFrame_camview/RawVideo`
  - Next Video: save data to mat and load next "Correct" video
  - Fill Start: pick the frame number when the rat starts to lift its hand
  - Fill Highest: pick the frame number when the rat's hand is highest
  - Hand: choose the hand that the rat first lifts
  - Manual Check: manually modify the tracking by clicking on the image
  - Save data to mat: save to `./VideoFrame_camview/MatFile/`
  - Skip: save the data but set the isGoodTracking to false and move to next "Correct" video
- The curated information is stored in the corresponding `.mat` file.
- Copy the `updateVideoInfos.m` to the video folder. Edit the `camview` and run to update `r`.

# EphysDLCAppTwoViews
- Manually curate DeepLabCut output for two-view videos.
