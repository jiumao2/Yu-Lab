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

disp(spikeTable)
%% extract waveform from temp_wh.dat
fid = fopen(ops.fproc, 'r');
ch_last = 0;
waveforms_tbl = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    ch = spikeTable(k,:).ch;
    if ch ~= ch_last
        disp(['Channel ',num2str(ch),' start!']);
        tic
        dat_this = [];
        buffsize = ops.NT+ops.ntbuff;

        i = 0;
        fseek(fid, 0, 'bof');
        while ~feof(fid)
            offset = 2*ops.Nchan*buffsize*i;
            fseek(fid, offset, 'bof');
            dat = fread(fid, [ops.Nchan buffsize], '*int16');
            dat_this = [dat_this, dat(ch,:)];
            i = i+1;
        end
    end
    ch_last = ch;

    spike_times_this = spikeTable(k,:).spike_times{1};
    waveform_this = zeros(length(spike_times_this),64);

    for j = 1:length(spike_times_this)
        waveform_this(j,:) = dat_this(spike_times_this(j)-31:spike_times_this(j)+32);
    end
    waveforms_tbl{k} = waveform_this;
    
    toc
    disp(['Channel ',num2str(ch),' done!']);
end
fclose(fid);

spikeTable.waveforms = waveforms_tbl;
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
            index_k = [0:length(double(NS6.Data{j}(1, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp(j)*1000/Fs+dBlockOnset;
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
        index = [index [0:length(double(NS6.Data(1, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset];
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


