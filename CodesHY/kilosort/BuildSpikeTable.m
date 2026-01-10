dir_output = 'kilosort2_5_output';
spikeTable = phy2mat(dir_output);
load(fullfile(dir_output, 'ops.mat'));
load(fullfile(dir_output, 'Wrot.mat'));
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
waveforms_tbl = cell(height(spikeTable),1);
waveforms_mean_tbl = cell(height(spikeTable),1);
ch_tbl = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tic
    [~,name,ext] = fileparts(ops.fproc);
    gwfparams.dataDir = dir_output;    % KiloSort/Phy output folder
    gwfparams.fileName = [name, ext];         % .dat file containing the raw 
    gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = length(spikeTable(k,:).spike_times{1});                    % Number of waveforms per unit to pull out
    gwfparams.spikeTimes =    spikeTable(k,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters = ones(length(spikeTable(k,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

    wf = getWaveforms(gwfparams);

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

    toc
end

spikeTable.waveforms = waveforms_tbl;
spikeTable.waveforms_mean = waveforms_mean_tbl;
spikeTable.ch = ch_tbl;
spikeTable = sortrows(spikeTable,{'ch','group'});
%% Get real spike time
if exist('NS6all.mat', 'file') && exist('index.mat','file') 
    load NS6all.mat;
    load index.mat;
else
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
        error('No .ns6 files!')
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

    %% save NS6all
    for k = 1:length(NS6all)
        NS6all(k).Data = [];
    end
    
    save NS6all NS6all
end
%%
% first 102 frame in Kilosort is skipped (Blackrock zeropad the data)
% kilosort add 0 at the end of data

spike_times_r = cell(height(spikeTable),1);

for k = 1:height(spikeTable)
    spike_times_r{k} = index(spikeTable(k,:).spike_times{1});
end

spikeTable.spike_times_r = spike_times_r;
disp(spikeTable)

%%
chanMap = load(fullfile(dir_output, 'chanMap.mat'));
KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
KilosortOutput.save();

%% Uncommenented correspoding segment to build R

% KilosortOutput.buildRMultiSessions( ...
%     {'Max_MedOptoRecording_20220726_153709.mat','Max_MedOptoRecording_20220726_204005.mat'},...
%     {'2022-07-26_15h32m_Subject Max.txt','2022-07-26_20h34m_Subject Max.txt'},...
%     {[1,2],3},...
%     'KornblumStyle', false,...
%     'Subject', 'Max',...
%     'blocks', {'datafile001.nev','datafile002.nev','datafile003.nev'},...
%     'Version', 'Version4',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'ZQ',...
%     'NS6all', NS6all,...
%     'saveWaveMean', true);
% 
% % For 2FPs (750/1500): 
% KilosortOutput.buildR(...
%     'KornblumStyle', false,...
%     'Subject', 'Frank',...
%     'blocks', {'datafile001.nev','datafile002.nev','datafile003.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY',...
%     'NS6all', NS6all,...
%     'saveWaveMean', true);
% 
% % For 2FPs (500/1000): 
% KilosortOutput.buildR(...
%     'KornblumStyle', false,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY',...
%     'NS6all', NS6all,...
%     'saveWaveMean', true);
% 
% % For Kormblum: 
% KilosortOutput.buildR(...
%     'KornblumStyle', true,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY',...
%     'NS6all', NS6all,...
%     'saveWaveMean', true);
% 
% % For Self time: 
% KilosortOutput.buildR(...
%     'KornblumStyle', true,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev','datafile003.nev','datafile004.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecordingSelfTimed',...
%     'Experimenter', 'HY',...
%     'NS6all', NS6all,...
%     'saveWaveMean', true);

%% Uncommenented correspoding segment to plot PSTHs
clear
output = dir("*RTarray*.mat");
load(output.name);

% % For SRT:
% Spikes.SRT.SRTSpikes(r,[]);
% load(output.name);
% Spikes.SRT.PopulationActivity(r);

% % For Kornblum:
% Spikes.Timing.KornblumSpikes(r,[], 'CombineCueUncue', false);
% Spikes.Timing.KornblumSpikesPopulation(r);

if isfield(r, 'PSTH')
    r = rmfield(r, 'PSTH');
end
if isfield(r, 'PopPSTH')
    r = rmfield(r, 'PopPSTH');
end
save(output.name, 'r', '-nocompression');
