function Spike_Events16(NEV)
% from NEV, have an overal look at spikes: shape and time
% 16 wire version

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

%% This figure plots active channels and their spikes (16 wire array for now)
hf=figure(15);
set(hf, 'unit', 'centimeters', 'position',[3 3 25 10], 'paperpositionmode', 'auto' )

subplot(2, 1, 1)
bar(nspikes(:, 1));
xlabel ('Channel #')
ylabel ('Spike #')
set(gca, 'xlim', [0 16], 'xtick', [1:1:16])

nev_name = NEV.MetaTags.Filename;
title(nev_name)

subplot(2, 1, 2)
bar(nspikes(:, 2));
xlabel ('Channel #')
ylabel ('Spike #')
set(gca, 'xlim', [0 16], 'xtick', [1:1:16])

%% This figure plots spikes

figure(20); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )

waves = NEV.Data.Spikes.Waveform;
waves_allocated = cell(1, 32);

electrodes =[1:16];

for i =1:length(electrodes)
    
    ha(i)=subplot(4, 8, i);
    set(ha(i), 'nextplot', 'add', 'ylim', [-1000 1000]/1000);
    
    if ~isempty(find(fElectrode == electrodes(i)))
        
        waves_allocated{i} = double(waves(:, fElectrode == electrodes(i)))/1000;
        
        if size(waves_allocated{i}, 2)>125
            to_plot=randperm(size(waves_allocated{i}, 2), 125);
        else
            to_plot = [1:size(waves_allocated{i}, 2)];
        end;
        
        plot(waves_allocated{i}(:, to_plot), 'k')
        
    end;
    title(['#' num2str(electrodes(i))])
end;

waves = NEV.Data.Spikes.Waveform;

electrodes =[33:48];

for i =1:length(electrodes)
    
    ha(i+16)=subplot(4, 8, i+16);
    set(ha(i+16), 'nextplot', 'add', 'ylim', [-1000 1000]/1000);
    
    if ~isempty(find(fElectrode == electrodes(i)))
        n = i+16;
        waves_allocated{n} = double(waves(:, fElectrode == electrodes(i)))/1000;
        
        if size(waves_allocated{n}, 2)>125
            to_plot=randperm(size(waves_allocated{n}, 2), 125);
        else
            to_plot = [1:size(waves_allocated{n}, 2)];
        end;
        
        plot(waves_allocated{n}(:, to_plot), 'k')
        
    end;
    title(['#' num2str(electrodes(i))])
end;

% file name:
nev_name = NEV.MetaTags.Filename;

print (gcf,'-dpng', ['Spike_Events_' nev_name ])

