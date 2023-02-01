dir_output = 'kilosort2_5_output';
addpath(dir_output)
spikeTable = phy2mat(dir_output);
load ops.mat
%% update spike table
% channel index start from 1
spikeTable.ch = spikeTable.ch+1;

% Only save labeled clusters and clear noise
k = 1;
while k <= height(spikeTable)
    if isempty(spikeTable(k,:).group{1}) || strcmp(spikeTable(k,:).group{1},'noise')
        spikeTable(k,:) = [];
    else
        k=k+1;
    end
end
spikeTable = sortrows(spikeTable,{'ch','group'});

% read and add spike times
spike_times = readNPY('spike_times.npy');
spike_clusters = readNPY('spike_clusters.npy');

tbl_spike_times = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tbl_spike_times{k} = spike_times(spike_clusters==spikeTable(k,:).cluster_id);
end
spikeTable.spike_times = tbl_spike_times;

%% extract waveform from temp_wh.dat
waveforms_tbl = cell(height(spikeTable),1);
waveforms_mean_tbl = cell(height(spikeTable),1);
ch_tbl = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tic
    [filepath,name,ext] = fileparts(ops.fproc);
    gwfparams.dataDir = filepath;    % KiloSort/Phy output folder
    gwfparams.fileName = [name, ext];         % .dat file containing the raw 
    gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = length(spikeTable(k,:).spike_times{1});                    % Number of waveforms per unit to pull out
    gwfparams.spikeTimes =    spikeTable(k,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters = ones(length(spikeTable(k,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

    wf = getWaveforms(gwfparams);
    
    amp_ch = max(squeeze(wf.waveFormsMean),[],2)-min(squeeze(wf.waveFormsMean),[],2);
    [~, ch_amp_largest] = max(amp_ch);
    ch_tbl{k} = ch_amp_largest;
    
    waveforms_tbl{k} = squeeze(wf.waveForms(:,:,ch_amp_largest,:));
    waveforms_mean_tbl{k} = squeeze(wf.waveFormsMean);
    
    toc
end

spikeTable.waveforms = waveforms_tbl;
spikeTable.waveforms_mean = waveforms_mean_tbl;
spikeTable.ch = ch_tbl;
spikeTable = sortrows(spikeTable,{'ch','group'});
%% Get real spike time
% Read NS6 file.
ns6_files = dir('*.ns6');
if ~isempty(ns6_files)
    for i =1:length(ns6_files)
        if i == 1
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all= NS6;
        else
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all(i)= NS6;
        end
    end
else
    return
end

% Define channels
EphysChs = 1:ops.Nchan;
Fs = ops.fs; % this is the sampling rate

% Extract ephys data

index =[];
for k = 1:length(NS6all)
    NS6 = NS6all(k);
    if k>1
        dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
        dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % convert time to ms
    else
        dBlockOnset=0; % define the starting time of the first session as 0
    end
    if iscell(NS6.Data)
        for j =1:length(NS6.Data)
            % this is time in ms
            index_k = (0:length(double(NS6.Data{j}(1, :)))-1)*1000/Fs+NS6.MetaTags.Timestamp(j)*1000/Fs+dBlockOnset;
            % skip first 102 frame (zeropad by blackrock?)
            index_k(1:102) = [];
            if k==1
                index = [index index_k];
            else
                % this is to take care of an old issue
                index_k = index_k(index_k> index(end)+0.03);
                index = [index index_k];
            end
        end
    else
        index_k = (0:length(double(NS6.Data(1, :)))-1)*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset;
        % skip first 102 frame (zeropad by blackrock?)
        index_k(1:102) = [];        
        index = [index index_k];
    end
end

savefile = 'index.mat'; % name of raw data files
save(savefile, 'index');
%%
% first 102 frame in Kilosort is skipped (Blackrock zeropad the data)
% kilosort add 0 at the end of data

spike_times_r = cell(height(spikeTable),1);

for k = 1:height(spikeTable)
    spike_times_r{k} = index(spikeTable(k,:).spike_times{1});
end

spikeTable.spike_times_r = spike_times_r;


%%
save spikeTable spikeTable

%%
chanMap = load('chanMap.mat');
KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
KilosortOutput.save();

