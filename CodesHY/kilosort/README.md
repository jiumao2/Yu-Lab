# Kilosort with BlackRock Recording

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
- [Kilosort with BlackRock Recording](#kilosort-with-blackrock-recording)
  - [Installation](#installation)
    - [prerequesite:](#prerequesite)
    - [Steps](#steps)
  - [Data process pipeline](#data-process-pipeline)
    - [About Phy output files](#about-phy-output-files)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
## Installation
### prerequesite:
- [Visual studio community 2017](https://visualstudio.microsoft.com/zh-hans/vs/older-downloads/) with 'C++桌面开发' (compatatible to MATLAB version)
- MATLAB 2021a-2022b + necessory toolboxes + MEX
- [kilosort3](https://github.com/MouseLand/Kilosort) or [kilosort2_5](https://github.com/MouseLand/Kilosort/releases/tag/v2.5) (place in a proper directory)
- [npy-matlab](https://github.com/kwikteam/npy-matlab) (place in a proper directory and better save it in MATLAB path)
- Anaconda

### Steps
#### Install phy
- New conda environment with python 3.8 `conda create -n phy python=3.8`
- Install phy `pip install phy --pre --upgrade`
- Deal with numpy version error `pip uninstall numpy`, `pip install numpy==1.23`
#### Install spike interface
- New conda environment with python 3.8 `conda create -n spikeinterface python=3.8`
- Install spikeinterface `pip install spikeinterface[full,widgets]`
#### Install kilosort
- Install kilosort. If visual studio is properly installed, run `mex -setup C++` in MATLAB and run the file `Kilosort\CUDA\mexGPUall.m`.
#### Install kilosort plugins
- See [here](https://github.com/jiumao2/PhyWaveformPlugin)

## Data process pipeline
- Move the directory with your data to SSD. (faster)
- Move the file `kilosort.ipynb` to your data directory.
- Open `kilosort.ipynb` in VS Code and set the kernal to `spikeinterface`. Modify the codes by following the instructions.
- Do munual curation with [Phy](https://phy.readthedocs.io/en/latest/clustering/). Open 'Anaconda prompt'. First enter the output directory and run `phy template-gui params.py`.
- Following the pipeline. Watch phy tutorial [here](https://www.youtube.com/watch?v=czdwIr-v5Yc). ![](phy_pipeline.png)
- Copy `BuildSpikeTable.m` to data folder, edit key parameters and run. A new class object `KilosortOuput` will be generated. 
- Run `KilosortOutput.BuildR()` to build `r`.


### [About Phy output files](https://github.com/cortex-lab/phy/blob/master/docs/sorting_user_guide.md#datasets)
| Filename | Type | Notes |
| :------------- | :---------- | :------------ |
|spike_clusters.npy|	nx1 vector 	                                    |Each spike's cluster (0:n_cluster-1) after manual curation |
|spike_templates.npy| 	nx1 vector 		                                |Each spike's cluster (0:n_cluster-1) before manual curation|
|spike_times.npy| 		nx1 vector 		                                |Unit: 1/30000 sec (1/sampling_frequency)|
|templates.npy| 		n_clusterxlength_waveform(82)xn_channel matrix.||
|templates_ind.npy| 	n_clusterxn_channel matrix 	                    |templates_ind(1,:) -> [0:31]|
|amplitudes.npy| 		nx1 vector 		                                |Unit: 40*mV?|
|channel_map.npy| 		n_channelx1 vector 	                            |0:31|
|channel_positions.npy| n_channelx2 vector 	                            |Position of each channel. Unit: μm|
|similar_templates.npy| n_clusterxn_cluster matrix 	                    |Similarity matrix|
|cluster_group.tsv|		mx2 table		                                |The manually modified info about the group (good/MUA/noise)|
|cluster_info.tsv|		n_clusterxn_property table	                    |Raw cluster info. Cluster info (cluster_idx, group) will be changed by manual curation|
|cluster_KSLabel.tsv|	n_clusterx2 table		                        |Raw group info|
|chanMap.mat|           struct                                          |Information about the probe|
|ops.mat|               struct                                          |Kilosort parameters|
|recording.dat|         binary data                                     |Raw recording data|
|temp_wh.dat|           binary data                                     |Filtered recording data|
