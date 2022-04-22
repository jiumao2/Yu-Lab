function PlotWaveClusSortingPoly(chname, varargin)
% e.g., PlotWaveClusSorting_v2('5', 'trange', [123 130], 'spkrange', [-800 500], 'lfprange', [-500 500])
% 3/20/2021
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

ChPoly = {};
fid = fopen(['polytrode' chname '.txt']);
tline = fgetl(fid);
while ischar(tline)
    disp(tline)
    ChPoly{end+1} = tline;
    tline = fgetl(fid);
end
fclose(fid);

tic
 
raw_vol = [];
for i =1:length(ChPoly)
     load(ChPoly{i});
     raw_vol = [raw_vol; data];
end;

toc
Fs=30000;
tall =  length(index)/30000; % in seconds. 
% spike detection
spkall = load(['polytrode' chname '_spikes.mat']);
spksort = load(['times_polytrode' chname '.mat']);

spksort.cluster_class(:, 2)= spksort.cluster_class(:, 2); % here correcting for the initial timestamp
%%
figure(23); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 12], 'paperpositionmode', 'auto' )

% haspkwaveavg = axes('unit', 'centimeters', 'position', [.5, 8, 2 2], 'nextplot', 'add', 'ylim', vrange1); axis off

% plot sorted spikes
clusters = unique(spksort.cluster_class(:, 1));
nclusters = length(clusters);

allcolors = varycolor(nclusters*2);
allcolors = allcolors(1:2:2*nclusters-1, :);

haspkwaveover = axes('unit', 'centimeters', 'position', [.5, 0.5, 3 6.5], 'nextplot', 'add', 'ylim', vrange1-mean(vrange1)); axis off

for k =1:nclusters-1
    haspkwave(k) = axes('unit', 'centimeters', 'position', [.5, 3+1.9*(k-1), 3 6.5], 'nextplot', 'add', 'ylim', vrange1-mean(vrange1)); axis off
    spk_indx = find(spksort.cluster_class(:, 1)== k);
    rate_k = length(spk_indx)/tall;
    if length(spk_indx)>100
        spk_indx = spk_indx(randperm(length(spk_indx), 100));
    end;
    plot(spksort.spikes(spk_indx, :)'/4, 'color', [0.5 0.5 0.5]);
    text(10, 70, sprintf('%2.1f spk/s', rate_k), 'fontsize', 10, 'color', allcolors(k+1, :));
%     title(sprintf('%2.1f spk/s', rate_k)) 
end;

for k =1:nclusters-1
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        spkwave_avg = mean(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)/4;
        
        axes(haspkwave(k))
        plot(spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 2);
        
        axes(haspkwaveover)
        plot(spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 1);
        
    end;
end;

line([0 30]+5, [vrange1(2) vrange1(2)], 'linewidth', 2, 'color', 'k')
text(0, vrange1(2)-40, '1ms', 'fontsize', 10);

tnew = [1:length(index)]*1000/30000;

ha1 = axes('unit', 'centimeters', 'position', [5 4 15 6.5], 'nextplot', 'add', 'ylim', vrange1,...
   'ytick', [vrange1(1):500:vrange1(2)],'xlim', trange, 'xtick', []); 

title([name  ' Tetrode #' chname], 'fontsize', 14)
% line([trange(1) trange(1)], [vrange1(1) vrange1(1)+100], 'color', 'k', 'linewidth', 2)
% % line([trange(1) trange(1)+1], [vrange1(1) vrange1(1)], 'color', 'k', 'linewidth', 2)
% text(trange(1), vrange1(1)+100, '1s')

ha1s = axes('unit', 'centimeters', 'position', [5 4.5 15 1.3], 'nextplot', 'add',  'ylim', [0.5  max(4, nclusters)],  'xlim', trange); axis off
axis off

% LFP channel
ha4 = axes('unit', 'centimeters', 'position', [5 1 15 2],'ytick', [vrange2(1):200:vrange2(2)], 'nextplot', 'add', 'ylim', vrange2, 'xlim', trange, 'xtick', [trange(1):trange(2)]);
xlabel('Time (s)')
title('LFP (2-150 Hz)')
tbeg=trange(1);
tend = trange(2);

index_raw=find(tnew>=tbeg*1000 & tnew<=tend*1000);
[b_detecthp,a_detecthp] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass

% remove line noise
d = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
    'DesignMethod','butter','SampleRate',30000);
[b_detectbp,a_detectbp] = butter(2, [4 100]*2/30000, 'bandpass');  % field potential

data_plot_hp = [];

dstep = 200;

for i = 1:size(raw_vol, 1)
    data_plot_hp(i, :) = filtfilt(b_detecthp, a_detecthp, raw_vol(i, index_raw))/4;   % high-pass filter data
    data_plot2 = filtfilt(d, raw_vol(i, index_raw));
    data_plot_band(i, :) = filtfilt(b_detectbp, a_detectbp, data_plot2)/4; % band pass 2-200 hz
    axes(ha1)
    plot(tnew(index_raw)/1000, data_plot_hp(i, :)-dstep*(i-1),  'color',[0.6 0.6 0.6], 'linewidth', 0.5);
    hold on
end;

t_spikes = tnew(index_raw);
spike_index = spksort.cluster_class(:,2)>=tbeg*1000 & spksort.cluster_class(:,2)<=tend*1000;
for i =1:4
    for k =1:nclusters-1
        cluster_index = spksort.cluster_class(:,1)==k;
        spike_time = spksort.cluster_class(spike_index & cluster_index,2);
        for j = 1:length(spike_time)
            [~,temp_index] = min(abs(t_spikes-spike_time(j)));
            temp_index = max(1,temp_index-32):min(temp_index+32,length(t_spikes));
            plot(t_spikes(temp_index)/1000, data_plot_hp(i, temp_index)-dstep*(i-1),  'color', allcolors(k+1, :), 'linewidth', 0.5);
        end
    end
end;

% plot detection
index_detection = find(spkall.index>=tbeg*1000 &  spkall.index<=tend*1000);
spk_peaks = min(spkall.spikes(index_detection, :), [], 2);

for i =1:4
    if ~isempty(index_detection)
        plot(spkall.index(index_detection)/1000, -dstep*(i-1), 'm.','markersize', 5, 'linewidth', 2)
    end;
end

% %     Either way, wave_clus generates a file times_filename.mat, with a variable cluster_class of two columns: the first column is the class of the spike and the second one is the spike time in ms.
% spk_peaks_max = prctile(min(spksort.spikes(find(spksort.cluster_class(:, 1) ~= 0), :),[], 2),  1);
% 
% for k =1:nclusters-1
%     if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
%         axes(ha1s)
%         spk_time_sort = (spksort.cluster_class(find(spksort.cluster_class(:, 1) == k), 2)); % in ms
%         spk_peaks_sort = prctile(spksort.spikes(find(spksort.cluster_class(:, 1) == k), :)',  5);
%         if ~isempty(find(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000))
%             plot([spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000 spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000]', [k k+0.8],...
%                 'linewidth', 2, 'color', allcolors(k+1, :));
%         end;
%     end;
% end;

%% LFP channel
% remove line noise
d = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
    'DesignMethod','butter','SampleRate',30000);

axes(ha4)
for i=1:size(data_plot_band, 1)
    plot(tnew(index_raw)/1000, data_plot_band(i, :)-20*(i-1), 'Color', [0.1 0.1 0.1]*(i-1), 'linewidth', 1);
end;

line([0 0], [vrange2(1) vrange2(1)+100], 'color', 'k', 'linewidth', 2)
linkaxes([ha1, ha1s, ha4], 'x')

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['waveclus_poly' chname name]);

print (gcf,'-dpng', tosavename)