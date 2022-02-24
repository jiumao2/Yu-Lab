function PlotWaveClusSorting(chname, varargin)
% e.g., PlotWaveClusSorting('5', 'trange', [123 130], 'spkrange', [-800 500], 'lfprange', [-500 500])
% 8/28/2021 modified by HY
trange = [123 130];
vrange1 = [-800 500];
vrange2 = [-500,500];
name=[];
for i =1:2:nargin-1
    switch varargin{i}
        case 'trange'
            trange = varargin{i+1};
        case 'spkrange'
            vrange1 = varargin{i+1};
        case 'lfprange'
            vrange2 = varargin{i+1};
        case 'name'
            name = varargin{i+1};
    end;
end;
%%
% raw data
tic
rawchname =  ['chdat' chname '.mat'];

if length(dir(rawchname)) ==0
    rawchname = ['chdat_meansub' chname '.mat'];
end

raw = load(rawchname); % if chname is 2, then load('chdat2.mat')
toc
Fs=30000;
tall =  length(raw.index)/30000; % in seconds. 
% spike detection

x=dir(['chdat' chname '_spikes.mat']);
if length(x)==0;
    x=dir(['chdat_meansub' chname '_spikes.mat']);
    spkall = load(x.name);
    spksort = load(['times_chdat_meansub' chname '.mat']);
else
    spkall = load(['chdat' chname '_spikes.mat']); % load spike times from detection, including all that pass thredhold
    spksort = load(['times_chdat' chname '.mat']);
end;

spkall.index = spkall.index;
spksort.cluster_class(:, 2)= spksort.cluster_class(:, 2); % here correcting for the initial timestamp
%%
figure(23); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 15.5 10.5], 'paperpositionmode', 'auto' )

% haspkwaveavg = axes('unit', 'centimeters', 'position', [.5, 8, 2 2], 'nextplot', 'add', 'ylim', vrange1); axis off

% plot sorted spikes
clusters = unique(spksort.cluster_class(:, 1));
nclusters = length(clusters);

allcolors = varycolor(nclusters*2);
allcolors = allcolors(1:2:2*nclusters-1, :);

 
haspkwaveover = axes('unit', 'centimeters', 'position', [.5, 0.5, 3 2], 'nextplot', 'add', 'ylim', vrange1); axis off

for k =1:nclusters-1
    haspkwave(k) = axes('unit', 'centimeters', 'position', [.5, 3+1.9*(k-1), 3 1.5], 'nextplot', 'add', 'ylim', vrange1); axis off
    spk_indx = find(spksort.cluster_class(:, 1)== k);
    rate_k = length(spk_indx)/tall;
    if length(spk_indx)>100
        spk_indx = spk_indx(randperm(length(spk_indx), 100));
    end;
    plot(spksort.spikes(spk_indx, :)', 'color', [0.5 0.5 0.5])
    title(sprintf('%2.1f spk/s', rate_k)) 
end;

for k =1:nclusters-1
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        spkwave_avg = mean(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1);
        
        axes(haspkwave(k))
        plot(spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 2);
        
        axes(haspkwaveover)
        plot(spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 1);
        
    end;
end;

line([0 30], [vrange1(end) vrange1(end)], 'linewidth', 2, 'color', 'k')
text(0, vrange1(2)+0.1*diff(vrange1), '1ms', 'fontsize', 8);

tnew = [1:length(raw.index)]*1000/30000;

ha1 = axes('unit', 'centimeters', 'position', [5 6 10 3.5], 'nextplot', 'add', 'ylim', vrange1,...
   'ytick', [vrange1(1):200:vrange1(2)],'xlim', trange, 'xtick', []); 
title([name  ' Ch' chname], 'fontsize', 14)
% line([trange(1) trange(1)], [vrange1(1) vrange1(1)+100], 'color', 'k', 'linewidth', 2)
% % line([trange(1) trange(1)+1], [vrange1(1) vrange1(1)], 'color', 'k', 'linewidth', 2)
% text(trange(1), vrange1(1)+100, '1s')

ha1s = axes('unit', 'centimeters', 'position', [5 4.5 10 1.3], 'nextplot', 'add',  'ylim', [0.5  max(4, nclusters)],  'xlim', trange); axis off
axis off

% LFP channel
ha4 = axes('unit', 'centimeters', 'position', [5 1.5 10 2.5],'ytick', [vrange2(1):200:vrange2(2)], 'nextplot', 'add', 'ylim', vrange2, 'xlim', trange, 'xtick', [trange(1):trange(2)]);
xlabel('Time (s)')
title('LFP (2-150 Hz)')
tbeg=trange(1);
tend = trange(2);

index_raw=find(tnew>=tbeg*1000 & tnew<=tend*1000);

[b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
data_plot_hp = filtfilt(b_detect, a_detect, raw.data(index_raw));   % high-pass filter data
axes(ha1)
plot(tnew(index_raw)/1000, data_plot_hp,  'color','k', 'linewidth', 0.5);
hold on

t_spikes = tnew(index_raw);
spike_index = spksort.cluster_class(:,2)>=tbeg*1000 & spksort.cluster_class(:,2)<=tend*1000;
for k =1:nclusters-1
    cluster_index = spksort.cluster_class(:,1)==k;
    spike_time = spksort.cluster_class(spike_index & cluster_index,2);
    for j = 1:length(spike_time)
        [~,temp_index] = min(abs(t_spikes-spike_time(j)));
        temp_index = max(0,temp_index-32):min(temp_index+32,length(t_spikes));
        plot(t_spikes(temp_index)/1000, data_plot_hp(temp_index),  'color', allcolors(k+1, :), 'linewidth', 0.5);
    end
end

% plot detection
index_detection = find(spkall.index>=tbeg*1000 &  spkall.index<=tend*1000);
spk_peaks = min(spkall.spikes(index_detection, :), [], 2);

if ~isempty(index_detection)
    plot(spkall.index(index_detection)/1000, 0, 'm.','markersize', 5, 'linewidth', 2)
end;
%     Either way, wave_clus generates a file times_filename.mat, with a variable cluster_class of two columns: the first column is the class of the spike and the second one is the spike time in ms.

spk_peaks_max = prctile(min(spksort.spikes(find(spksort.cluster_class(:, 1) ~= 0), :),[], 2),  1);

for k =1:nclusters-1
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        axes(ha1s)
        spk_time_sort = (spksort.cluster_class(find(spksort.cluster_class(:, 1) == k), 2)); % in ms
        spk_peaks_sort = prctile(spksort.spikes(find(spksort.cluster_class(:, 1) == k), :)',  5);
        if ~isempty(find(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000))
            plot([spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000 spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000]', [k k+0.8],...
                'linewidth', 2, 'color', allcolors(k+1, :));
        end;
    end;
end;

%% LFP channel
% remove line noise
d = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
    'DesignMethod','butter','SampleRate',30000);

data_plot2 = filtfilt(d,raw.data(index_raw));

[b_detect,a_detect] = butter(2, [2 100]*2/30000, 'bandpass');  % field potential
data_plot_band = filtfilt(b_detect, a_detect, data_plot2); % band pass 2-200 hz

axes(ha4)
plot(tnew(index_raw)/1000, data_plot_band/4,  'k', 'linewidth', 1)

line([0 0], [vrange2(1) vrange2(1)+100], 'color', 'k', 'linewidth', 2)

linkaxes([ha1, ha1s, ha4], 'x')


thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['waveclus_chdat' chname name]);

print (gcf,'-dpng', tosavename)

 
