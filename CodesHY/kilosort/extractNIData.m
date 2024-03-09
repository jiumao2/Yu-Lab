binName = 'Exp_g0_t0.nidq.bin';
path = '../Exp_g0';

% Parse the corresponding metafile
meta = SGLX_readMeta.ReadMeta(binName, path);

nChan = str2double(meta.nSavedChans);
nFileSamp = str2double(meta.fileSizeBytes) / (2 * nChan);

dataArray = SGLX_readMeta.ReadBin(0, nFileSamp, meta, binName, path);
dataArray = SGLX_readMeta.GainCorrectNI(dataArray, 1, meta);

sample_rate = str2double(meta.niSampRate);

%%
TimeEvents = double(SGLX_readMeta.ExtractDigital(dataArray, meta, 1, 0:6));

%%
event_labels = {'LeverPress', 'Poke', 'Valve', 'GoodRelease', 'Frame', 'BadPoke', 'Trigger'};
n_events = length(event_labels);

EventOnset_sec = cell(1, n_events);
EventOffset_sec = cell(1, n_events);
for k = 1:n_events
    rising = find(diff(TimeEvents(k,:))>0.5)+1; % index of rising
    falling = find(diff(TimeEvents(k,:))<-0.5)+1; % index of falling
    
    EventOnset_sec{k} = rising./sample_rate;  % in sec
    EventOffset_sec{k} = falling./sample_rate;  % in sec
    if ~isempty(EventOnset_sec{k}) && ~isempty(EventOffset_sec{k}) && EventOnset_sec{k}(1)>EventOffset_sec{k}(1)  % caught after onset
        EventOffset_sec{k}(1)=[];
    end
end

% in some protocols, 'MEDTTL' sends two pulses to Bpod to trigger low or
% high rewards (low, one pulse; high, two pulses). It is necessary to
% remove the second pulses. 
ind_MEDTTL = find(strcmpi(event_labels, 'GoodRelease')); % 'GoodRelease',
IndShortPulses = 1+find(diff(EventOnset_sec{ind_MEDTTL})<23);

EventOnset_sec{ind_MEDTTL}(IndShortPulses) = [];
EventOffset_sec{ind_MEDTTL}(IndShortPulses) = [];

%%
dir_out = dir('./Exp_*_tcat.imec0.ap.xd_384_*_500.txt');
if isempty(dir_out)
    error('Sync file in Imec not found!');
end
filename_imec = dir_out.name;

dir_out = dir('.\Exp_*_tcat.nidq.xa_*_500.txt');
if isempty(dir_out)
    error('Sync file in NI not found!');
end
filename_NI = dir_out.name;

cmd = ['TPrime -syncperiod=1.0 -tostream='...
    filename_imec, ...
    ' -fromstream=1,',...
    filename_NI,...
    ' '];

for k = 1:length(event_labels)
    writeNPY(EventOnset_sec{k},['event',num2str(k),'_onset.npy']);
    writeNPY(EventOffset_sec{k},['event',num2str(k),'_offset.npy']);
    cmd = [cmd, '-events=1,.\event',num2str(k),'_onset.npy,.\event',num2str(k),'_onset_Tprime.npy '];
    cmd = [cmd, '-events=1,.\event',num2str(k),'_offset.npy,.\event',num2str(k),'_offset_Tprime.npy '];
end
%%
system(cmd);
%% save the output for phy
event_labels_for_phy = {'LeverPress', 'Valve', 'GoodRelease', 'Trigger'};
idx_for_phy = zeros(1, length(event_labels_for_phy));
for k = 1:length(idx_for_phy)
    idx_for_phy(k) = find(strcmpi(event_labels, event_labels_for_phy{k}));
end

events_onset_Tprime_ms = cell(n_events, 1);
events_offset_Tprime_ms = cell(n_events, 1);
for k = 1:length(event_labels)
    events_onset_Tprime_ms{k} = readNPY(['event',num2str(k),'_onset_Tprime.npy'])*1000;
    events_offset_Tprime_ms{k} = readNPY(['event',num2str(k),'_offset_Tprime.npy'])*1000;
end

event_onset_sec = events_onset_Tprime_ms(idx_for_phy);
for k = 1:length(event_onset_sec)
    event_onset_sec{k} = event_onset_sec{k}./1000;
end

writecell(event_onset_sec,'events.csv');
writecell(event_labels(idx_for_phy)','event_labels.csv');

%% save EventOut
EventOut.Meta = meta;
EventOut.TimeEvents = TimeEvents';
EventOut.EventsLabels = event_labels;
EventOut.Onset = events_onset_Tprime_ms';
EventOut.Offset = events_offset_Tprime_ms';

save ../EventOut.mat EventOut
%% Clear all .npy files
dir_out = dir('./event*.npy');
filenames_npy = {dir_out.name};
for k = 1:length(filenames_npy)
    delete(fullfile('./', filenames_npy{k}));
end