function CheckNEVSpikesRaw(NEV, ich, trange, sortunit)

if nargin<4
    sortunit =1;
end;

allcolors = {'b', 'r', 'c', 'm', 'g'};

spktag = NEV.Data.Spikes;
nchns = [1:16];

try
load(['chdat' num2str(ich) '.mat']);
vdata = data;
end;

load(['chdat_meansub' num2str(ich), '.mat']);
vdata_sub = data;

t = index;

% get spike times
ind_electrodes = find(NEV.Data.Spikes.Electrode == ich);
units_all = NEV.Data.Spikes.Unit(ind_electrodes);
units_sorted = setdiff(units_all, 0);
if ~isempty(units_sorted)
    sorted_waves = cell(1, length(units_sorted));
    for k =sortunit
        iunit = units_sorted(k)
        ind_spk = intersect(ind_electrodes, find(NEV.Data.Spikes.Unit==iunit));
        spktime = NEV.Data.Spikes.TimeStamp(ind_spk)/30;
        
        spktime(1:10)/1000
         kwaves = NEV.Data.Spikes.Waveform(:, ind_spk);
    end;
end;

index_plot = find(t>=trange(1)*1000 & t<=trange(2)*1000);
try
    vplot = vdata(index_plot);
end;
vsubplot = vdata_sub(index_plot);

spkwaveplot = kwaves(:, spktime>=trange(1)*1000 & spktime<=trange(2)*1000);
spktimeplot = spktime(spktime>=trange(1)*1000 & spktime<=trange(2)*1000);

[b_detect,a_detect] = ellip(4,0.1,40,[250 8000]*2/30000);  % high pass
try
    vplotfilt  = filtfilt(b_detect, a_detect, vplot); % band pass 2-200 hz
end;

hf=figure(100); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto' )
subplot(2, 2, 1)
try
plot(t(index_plot), vplotfilt, 'k')
hold on

plot(spktimeplot, 200, 'ro')
set(gca, 'ylim', [-800 800])
end;
subplot(2, 2, 2)
plot(t(index_plot), vsubplot, 'm')
hold on
plot(spktimeplot, 200, 'ro')
set(gca, 'ylim', [-800 800])

subplot(2, 2, 3)
plot(spkwaveplot)
 