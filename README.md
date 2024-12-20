# Electrophysiology Data Analysis Pipeline
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Overview](#overview)
  - [Necessary Files](#necessary-files)
- [Pipeline of Analyzing Data From Single Session](#pipeline-of-analyzing-data-from-single-session)
  - [Spike Sorting](#spike-sorting)
    - [Kilosort](#kilosort)
    - [Wave clus](#wave-clus)
      - [Place Files Properly](#place-files-properly)
      - [Spike Detection](#spike-detection)
      - [Simple Clust](#simple-clust)
      - [Double Checking](#double-checking)
      - [PSTH](#psth)
      - [how is R array built?](#how-is-r-array-built)
  - [Video Analysis](#video-analysis)
    - [Place Files Properly](#place-files-properly-1)
    - [Get Timestamps Of Each Frame](#get-timestamps-of-each-frame)
    - [Extracting Frames When Neuron Bursts (high firing rate)](#extracting-frames-when-neuron-bursts-high-firing-rate)
    - [Extracting Frames With Raster Plot](#extracting-frames-with-raster-plot)
    - [PCA](#pca)
    - [Encoding Analysis: Generalized Linear Model](#encoding-analysis-generalized-linear-model)
  - [Trajectory Analysis](#trajectory-analysis)
    - [DeepLabCut](#deeplabcut)
    - [EphysDLCapp: Manually Check the Trackings](#ephysdlcapp-manually-check-the-trackings)
    - [Define Trajectories And Generate Figures](#define-trajectories-and-generate-figures)
    - [Lift trajectories analysis](#lift-trajectories-analysis)
- [Pipeline of Analyzing Data From Multiple Sessions](#pipeline-of-analyzing-data-from-multiple-sessions)
  - [Combine All The Units](#combine-all-the-units)
  - [PSTH](#psth-1)
  - [Tracking Analysis](#tracking-analysis)
- [Preliminary Results](#preliminary-results)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Overview
### Necessary Files
- Ephys: datafile00x.ccf & datafile00x.nev & datafile00x.ns2 & datafile00x.ns6
- MED: xxx.txt (SRT_Step7_FR1_TwoFPsMixedBpod)
- Bpod: xxx.mat (MedOptoRecording)
- Video: xxx.seq & xxx.seq.idx


## Pipeline of Analyzing Data From Single Session

### Spike Sorting  
#### Kilosort  
- See [here](./CodesHY/kilosort/readme.md)

#### Wave clus
##### Place Files Properly  
- Include all [Ephys/Med/Bpod file](#necessary-files), `DetectSpikesGeneral.m` and `BuildArray_MedOpto.m` in a single folder  
- `DetectSpikesGeneral.m` and `BuildArray_MedOpto.m` can be found in `.\CodesHY\Scripts`
![](./readme/SpikeDectectionFiles.jpg)

##### Spike Detection  
- `openNEV` open xxx.nev  
- `CheckNEVSpikes(NEV)` check waveforms and choose good channels  
- Edit the variable `LiveChs` (line 22) based on online sorting and the chosen channels  
- Edit the variable `pos_detection` (line 158) based on online sorting  
- Run `DetectSpikesGeneral.m`. It need a few hours.  
- Gernerated Files:
  - `chdatx.mat`: the raw recording from channel x
  - `ForceSensor.mat`: the raw recording about the lever pressure. It is not the real force on the lever.
  - `CommonAvgData.mat`: mean recording of all `LiveChs` channels
  - `chdat_meansubx.mat`: raw recording from channel x is subtracted by mean recording `CommonAvgData.mat`, and then passed through a 4th-order Elliptic band-pass filter which passes frequencies between 250Hz and 8000Hz, and with 0.1 dB of ripple in the passband, and 40 dB of attenuation in the stopband (`ellip(4,0.1,40,[250 8000]*2/Fs);`)  
  - `chdat_meansubx_spikes.mat`: Spike detection data, the result from `chdat_meansubx.mat` going through `Get_spikes`. Saves spikes, spike times (in ms), used parameters and a sample segment of the continuous data.
  - `times_chdat_meansubx.mat`: Auto-clustering data, the result from `chdat_meansubx_spikes.mat` going through `Do_clustering`. Saves spikes, spike times (in ms), coefficients used (inspk), used parameters, random spikes selected for clustering (ipermut) and results (cluster_class)  
  - `mua_x.mat`: unclustered data converted from `times_chdat_meansubx.mat`, which can be opened by SimpleClust. Run `mua2wave_clust('x')` or `wave_clust2mua('x')` to convert these 2 kinds of data  
##### Simple Clust  
- Run `jsimpleclust`
![](./readme/SimpleClustManual.png)
  - open `mua_x.mat`
  - select all points that are noise or not spikes of interest  
  ![](./readme/SimpleClust1.png)
  - click '+wavelet'. This step takes about 3 minutes  
  ![](./readme/SimpleClust2.png)
  - select different waveforms based on multiple features  
  ![](./readme/SimpleClust3.png)
  - removing "bad" waveforms  based on multiple features
  - save and exit
  - tips:
    - Since '+wavelet' step need a few time, you can open more MATLAB for efficiency
    - You can open `chx_simpleclust.mat` to check your previously clustered data
##### Double Checking
- Run `mua2wave_clust('x')` to converted `chx_simpleclust.mat` back to `times_chdat_meansubx.mat` and `chdat_meansubx_spikes.mat`
- Run `wc` and `celestina`
  - load `chdat_meansubx_spikes.mat`
  - manually clear the abnormal waveforms and reject the noisy clustered
  ![](./readme/wc1.jpg)
  - click 'Save clusters' !!!
  - click 'load from GUI' in celestina. Check whether a cluster is a single unit and whether 2 clusters are the same
  - run `PlotWaveClusSorting('4', 'trange', [220 230], 'spkrange', [-1800 500], 'lfprange', [-800 500])` to plot the spikes from channel 4, time from 220s to 230s, spike y axis ranging from -1800mV to 500mV and LFP y-axis ranging from -800mV to 500mV  
  ![](./readme/PlotWaveClusSorting.jpg)  

##### PSTH
- Open `BuildArray_MedOpto.m`. Edit `name`, `blocks` and `units`. Determine whether a unit is a single unit by ISIH (Interspike Interval Histogram) in wc (usually less than 1% in < 3ms).
- Run `BuildArray_MedOpto.m`. Select the thresholds as instructed. And then PSTH of all units will be plot and saved in `./Fig/`
  ![](./readme/Ch4_Unit3.png)  
- `RTarrayAll.mat` will save all the behavioral and electrophysiological data.  
![](./readme/r2.jpg)
- The meaning of fields in `r`:  
  - Meta: the meta information of each block
  - Behavior: behavioral data
    - Labels: the meaning of each label marker
    - CorrectIndex/PrematureIndex/LateIndex/DarkIndex: the index of correct/premature/late/dark trial. Each trial corresponds to each press.
    - Foreperiod: the forperiod of each trial
    - EventMarkers/EventTimings: the timings of each event
  - Units: electrophysilogical data
    - Profile: the units in each channel
    - SpikeNotes/Definition: `Definition` defines the `SpikeNotes`
    - SpikeTimes: the spike time and the waveform of each spike
  - BehaviorClass: a class generated from `MED` files  
##### how is R array built?
1. Make unit table: channel id, unit quality (single/multi unit)
2. Read NS6 file and get the timestamps when each block starts and compute `dt` (the time interval between blocks)
3. Use function `track_training_progress_advanced` to read data from MED files. A `B_Animal_Date_Time.mat` file will be generated. It contains a variable `b`: the information of each trial and the timings of each event. The time is according to the MED system.
![](./readme/MED.png)  
4. Load Bpod file. It contains a struct `SessionData` which contains the information of each trial and the timings of each event. The time is according to the Bpod system.  
![](./readme/Bpod.png)  
The most important information is in `SessionData.RawEvents.Trial{1, trialNumber}.States`.  
![](./readme/BpodStates.png)  
5. Do alignment in each block. The final timeline is according to the BlackRock system.  
(1) Load NEV data. Use function `DIO_Events4` or `DIO_Events5` to extract the data out and form `EventOut`.  
![](./readme/NEV.png) 
![](./readme/EventOut_EventsLabels.png)
![](./readme/EventOut_TimeEvents.png)
6. Combines all `EventOut` using `dt` to generate `EventOutCombined`.
7. Use function `Bpod_Events_MedOptoRecording` to extract data from `SessionData`. `BpodEvents` will be generated, which will be used to update 'poke' events using function `UpdatePokeFromBpodEvents`.
![](./readme/BpodEvents.png)  
8. Align MED events to BlackRock events using function `AlignBehaviorClassToBR` to update `EventOutCombined`. Add FP, outcome, cue and trigger information to `EventOutCombined`. Note that the press times in BlackRock should be always contains in the press times in MED.    
9. Use the information in `EventOutCombined` and electrophysiological information to construct `r`.


### Video Analysis
#### Place Files Properly  
- Include all [Video files](#necessary-files), `MakeVideoClips.m` and `updateVideoTracking.m` in a single folder  
- `MakeVideoClips.m` and `updateVideoTracking.m` can be found in `.\CodesHY\Scripts`
![](./readme/VideoAnalysisFiles.jpg)
#### Get Timestamps Of Each Frame
- Open `MakeVideoClips.m`. Edit `topviews` and `sideviews`.
- Run `MakeVideoClips.m`. The ROI of LED and threshold should be manually selected. Then the light-on timestamps will be extracted.
- Map the frame times to the times in `r` using LED signals.
- Edit this line `ExtractEventFrameSignalVideo(r, ts, [], 'events', 'Press', 'time_range', [2100 2400], 'makemov', 1, 'camview', 'top', 'make_video_with_spikes', false, 'sort_by_unit',true,'frame_rate',10,'start_trial',1);` in the last section according to your request
- A new directory `./VideoFrame_top/` or `./VideoFrame_side/` will be generated.  
  - `./VideoFrame_top/MatFile/`: the information about each video clip
  - `./VideoFrame_top/RawVideo`: all the raw video clips  
  A New `r` will be saved. `r.VideoInfos_top` merge the information in `./VideoFrame_top/MatFile/`
#### Extracting Frames When Neuron Bursts (high firing rate)
- `ExtractBurstFrame(r,1,'view','top')` it will generate `./VideoFrame_top/BurstFrame/Unit1.avi`, which contains the 1000 (or more) frames when the unit has highest firing rate  
  - Urey 2021.11.24 Unit 3  
![](./readme/Unit3.gif)
#### Extracting Frames With Raster Plot
- Copy `.\CodesHY\Scripts\MakeRasterPlotVideo.m` to the current directory (xxx_video)
- Edit `camview`.
- Run `MakeRasterPlotVideo.m`. Raw video with raster plot will be generated in `./VideoFrame_camview/Video`  
  - Urey 2021.11.24 Unit 3 Trail 200  
![](./readme/Press200.gif)
#### PCA
- Run `pca_video_with_tracking()`
  - `bodypart`: if you have tracking data, this function would do cross correlation with firing rate and label the trackings to videos
  - `make_video`: map the principle components to video clips
  - `camview`: `side` default
  - `unit_of_interest`: choose the units to be included to PCA analysis
  - `only_single_unit`: true if you only want to include single units
- Principle Components
- Eli 2021.9.23  
![PC](./readme/PC.png)
- Video Output  
  - Eli 2021.9.23 Trial 19  
![PCA](./readme/Press019_PC1.gif)  
#### Encoding Analysis: Generalized Linear Model  
- Copy `.\CodesHY\glm_SRT\glm_main.m` to the current directory (xxx_video)
- Choose the kernels and set the parameters of each kernel
- Run `.\CodesHY\glm_SRT\glm_main.m`
- Output will be saved in `.\Fig\GLM` and in `r`  
- Four Kernels of generalized linear model
  - Urey 2021.11.24 Unit 3  
![PSTH](./readme/kernel_Unit3.png)
- Reconstructed PSTH (Urey 2021.11.24 Unit 3)  
![PSTH](./readme/PSTH_Unit3.png)

### Trajectory Analysis
#### DeepLabCut
- Use DeepLabCut and analyze the videos in `./VideoFrame_camview/RawVideo`, .csv files should be generated
- Run `UpdateTracking.m` to update mat files in `./VideoFrame_camview/MatFile` and include tracking data to `r`. The tracking information will be saved in `r.VideoInfos_camview.Tracking`
#### EphysDLCapp: Manually Check the Trackings
- See [EphysDLCApp](./CodesHY/EphysDLCApp/README.md)

#### Define Trajectories And Generate Figures
- Copy `.\CodesHY\TrackingAnalysis\scripts\trackingAnalysis.m` to the current directory (xxx_video)
- Set the parameters and run. Follow the instructions  
- <text id='Traj_classification'>Traj_classification.png  </text>  
![Traj_classification](./readme/Traj_classification.png)  
- Traj1.png (Urey 2021.11.24)  
![Traj1](./readme/Traj1.png)  
- Traj2.png (Urey 2021.11.24)  
![Traj2](./readme/Traj2.png)  
- PSTH of an example unit (Urey 2021.11.24 Unit 1, the color corresponds to [Traj_classification.png](#Traj_classification))  
![PSTH](./readme/TrajComparing_Unit1_Press.png)  
#### Lift trajectories analysis
- To find out at which stage lift-related neurons  
- Run `TrajectoryCell(r,unit_num,'trajectory',traj_num)`
![](./readme/LiftPETH.png)   

## Pipeline of Analyzing Data From Multiple Sessions

### Combine All The Units
- See [findSameNeurons.mlapp](./CodesHY/findSameNeurons/README.md) 

### PSTH  
- `SRTSpikesV6(r_all,unit_num)`  
  - Russo 20210906~20210910  
![](./readme/Ch14_Unit1.png)
### Tracking Analysis
`.\CodesHY\TrackingAnalysis\scripts\trackingAnalysisAll.m`
  - Russo 20210906~20210910  
![](./readme/TrajComparing_Unit13_Press.png)

## Preliminary Results
- See [here](https://jianingyulab2019.yuque.com/org-wiki-jianingyulab2019-it6r8i/hlwgkm/pdz5s9dszfpg79so)
- Video analysis:  [here](https://github.com/jiumao2/VideoAnalysisDataset) or [here](https://jianingyulab2019.yuque.com/org-wiki-jianingyulab2019-it6r8i/hlwgkm/emw04igwvauf2nuh)  
