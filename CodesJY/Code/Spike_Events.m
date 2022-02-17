function Spike_Events(NEV)
% from NEV, have an overal look at spikes: shape and time
% 

% NEV.Data
% 
%     SerialDigitalIO: [1×1 struct]
%              Spikes: [1×1 struct]
%            Comments: [1×1 struct]
%           VideoSync: [1×1 struct]
%            Tracking: []
%      TrackingEvents: [1×1 struct]
%      PatientTrigger: [1×1 struct]
%            Reconfig: [1×1 struct]
%            LogEvent: [1×1 struct]
% 
% NEV.Data.Spikes
% 
%        TimeStamp: [1×176912 uint32]
%        Electrode: [1×176912 uint16]
%             Unit: [1×176912 uint8]
%         Waveform: [48×176912 int16]
%     WaveformUnit: 'raw'


% live units
fElectrode = double(NEV.Data.Spikes.Electrode);
fElectrode_unique = unique(fElectrode);

edges = [0.5:1:64.5]
edgecenters = [1:64];
nspikes = histcounts(fElectrode,edges);
nspikes=reshape(nspikes, 32, 2); % two electrode arrays
hf=figure(15);
set(hf, 'unit', 'centimeters', 'position',[2 2 10 10], 'paperpositionmode', 'auto' )

subplot(2, 1, 1)
bar(nspikes(:, 1));
xlabel ('Channel #')
ylabel ('Spike #')

subplot(2, 1, 2)
bar(nspikes(:, 2));
xlabel ('Channel #')
ylabel ('Spike #')



figure(20); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )

dim = [4, 16];









