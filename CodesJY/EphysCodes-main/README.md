# Ephys-analysis
1. To plot a polytrode example trace: 
PlotWaveClusSortingPoly('1', 'trange', [209 211], 'spkrange', [-800 100], 'lfprange', [-200 200], 'name', '')
2. Detect spikes from defined tetrode channels (script to be placed in a directory): 
DetectSpikesTetrodes4.m


Pipeline:

# For regular multiwire array 

1. Use this script to extract raw data, detect spikes, and perform spike sorting in wave-clus
	DetectSpikesGeneral.m

	Edit here to match your experimental condition (e.g., 16 vs 32 chs)
	
	Nch = 16;
	
	EphysChs =[1:Nch];
	
	LiveChs =EphysChs; % all live channels for 32-ch arrays (one can choose only a subset of these channels if not all channels have good data)	
	
	AllChs = [LiveChs 33:39];

2. Use wave_clus to check sorted spikes (download wave_clus here: https://github.com/csn-le/wave_clus)

3. One can use simpleclust to perform quick sorting (original simpleclust can be found here: https://github.com/open-ephys/simpleclust. I did some edit to fit our data structure). 

	convert wave_clus to mua:  e.g., wave_clust2mua('12') 
	
	sort spikes in simple clust
	
	convert back to wave_clus: e.g., mua2wave_clust('12') # This is no longer necessary as of 3/12/2022. It is now integrated into "sc_save_dialog"
	
	Download Voigts' codes and add(update)these files:
	
	sc_save_dialog | mua2wave_clust | mua2wave_clustpoly | wave_clust2muapoly | wave_clust2muapoly | wave_clust2mua | jsimpleclust

	
	
	
4. SpikeCuration is a spike sorting app
![Single7Cluster1Sorting](https://user-images.githubusercontent.com/67672878/157672845-66fb0ba8-30d0-4229-9781-77b35d7c8ebc.png)


	


