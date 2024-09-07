%% you need to change most of the paths in this block
dir_output = './catgt_Exp_g0';

if exist(fullfile(dir_output, 'ops.mat'), 'file') && exist(fullfile(dir_output, 'chanMap.mat'), 'file')
    disp('ops.mat and chanMap.mat found!');
    load(fullfile(dir_output, 'ops.mat'));
else
    disp('ops.mat not found. Extracting ops from rez.mat...');
    load(fullfile(dir_output, 'rez.mat'));
    ops = rez.ops;
    
    save(fullfile(dir_output, 'ops.mat'), 'ops');
    
    disp('Extracting chanMap from rez.mat...');
    kcoords = ops.kcoords;
    xcoords = rez.xcoords;
    ycoords = rez.ycoords;
    chanMap = ops.chanMap;
    chanMap0ind = chanMap-1;
    connected = ones(1, length(chanMap));

    save(fullfile(dir_output, 'chanMap.mat'), 'chanMap', 'chanMap0ind', 'connected', 'kcoords', 'xcoords', 'ycoords');

    clear rez
end

% extract Imec meta
dir_out = dir(fullfile(dir_output, '*.ap.bin'));
if isempty(dir_out)
    error('No raw data found!');
end
data_filename = dir_out.name;
meta = SGLX_readMeta.ReadMeta(data_filename, dir_output);

spikeTable = phy2mat(dir_output);
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
spike_times = readNPY(fullfile(dir_output, 'spike_times.npy'));
spike_clusters = readNPY(fullfile(dir_output, 'spike_clusters.npy'));

tbl_spike_times = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tbl_spike_times{k} = spike_times(spike_clusters==spikeTable(k,:).cluster_id);
end
spikeTable.spike_times = tbl_spike_times;

%% extract waveform from temp_wh.dat
if exist('./Wrot.mat', 'file')
    load('./Wrot.mat');
else
    load(fullfile(dir_output, 'Wrot.mat'));
end
waveforms_tbl = cell(height(spikeTable),1);
waveforms_mean_tbl = cell(height(spikeTable),1);
ch_tbl = cell(height(spikeTable),1);
spike_ID_tbl = cell(height(spikeTable),1);

n_waveform_max = 1000;
for k = 1:height(spikeTable)
    tic
    n_waveform = length(spikeTable(k,:).spike_times{1});
    spikeID = 1:n_waveform;

    % only extract 1000 waveforms to save time and space
    if n_waveform > n_waveform_max
        rnd = sort(randperm(n_waveform, n_waveform_max));
        spikeID = spikeID(rnd);
    end

    [~,name,ext] = fileparts(ops.fproc);
    gwfparams.dataDir = dir_output;    % KiloSort/Phy output folder
    gwfparams.fileName = [name, ext];         % .dat file containing the raw 
    gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = length(spikeID);                    % Number of waveforms per unit to pull out
    gwfparams.spikeTimes = spikeTable(k,:).spike_times{1}(spikeID); % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters = ones(length(spikeID),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

    wf = getWaveforms(gwfparams);
    % change the gain to 4 to fit with BlackRock recordings
    % gain of NP: https://billkarsh.github.io/SpikeGLX/Sgl_help/Metadata_30.html
    gain_NP = str2double(meta.imAiRangeMax)./str2double(meta.imMaxInt)./500*1e6; % in uV

    wf.waveForms = wf.waveForms*gain_NP.*4;
    wf.waveFormsMean = wf.waveFormsMean*gain_NP.*4;

    raw_waveforms = permute(squeeze(wf.waveForms), [2,1,3]);
    n_spikes = size(raw_waveforms, 2);
    raw_waveforms_reshaped = reshape(raw_waveforms, size(raw_waveforms, 1), []);

    % Unwhittening the data to get the raw and real waveforms
    raw_waveforms_reshaped = (raw_waveforms_reshaped' / Wrot)';
    raw_waveforms = reshape(raw_waveforms_reshaped, size(raw_waveforms));
    raw_waveforms_mean = squeeze(mean(raw_waveforms, 2));
    
    amp_ch = max(raw_waveforms_mean,[],2)-min(raw_waveforms_mean,[],2);
    [~, ch_amp_largest] = max(amp_ch);
    ch_tbl{k} = ch_amp_largest;
    
    waveforms_tbl{k} = squeeze(raw_waveforms(ch_amp_largest,:,:));
    waveforms_mean_tbl{k} = squeeze(raw_waveforms_mean);
    spike_ID_tbl{k} = spikeID;

    toc
end

spikeTable.waveforms = waveforms_tbl;
spikeTable.waveforms_mean = waveforms_mean_tbl;
spikeTable.ch = ch_tbl;
spikeTable.spike_ID = spike_ID_tbl;
spikeTable = sortrows(spikeTable,{'ch','group'});
%%
% https://billkarsh.github.io/SpikeGLX/help/syncEdges/Sync_edges/
% Loads array spike_times.npy.
% Parses value imSampRate from the metadata file.
% Divides the rate into each array element.
% Writes the times out in same folder as spike_seconds.npy.
im_sample_rate = str2double(meta.imSampRate);

spike_times_r = cell(height(spikeTable),1);

for k = 1:height(spikeTable)
    spike_times_r{k} = double(spikeTable(k,:).spike_times{1})/im_sample_rate*1000;
end

spikeTable.spike_times_r = spike_times_r;
disp(spikeTable)

%%
chanMap = load(fullfile(dir_output, 'chanMap.mat'));
KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
KilosortOutput.save();

%% build R
KilosortOutput.buildRNeuropixels(...
    'KornblumStyle', false,...
    'ProbeStyle', true,...
    'Subject', 'Oscar',...
    'BpodProtocol', 'OptoRecording',...
    'Experimenter', 'HY');

KilosortOutput.plotChannelActivity();

output = dir("*RTarray*.mat");
load(output.name);

% For SRT:
Spikes.SRT.SRTSpikes(r,[]);
load(output.name);
Spikes.SRT.PopulationActivity(r);

% % For Kornblum:
% Spikes.Timing.KornblumSpikes(r,[], 'CombineCueUncue', false);
% load(output.name);
% Spikes.Timing.KornblumSpikesPopulation(r);


