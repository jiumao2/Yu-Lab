function CheckWaveClusSortingMeanSub(chname, trange)
% chname can ben chdat2
 
% raw data
raw = load(['chdat' chname]); % if chname is 2, then load('chdat2.mat')
Fs=30000;
% spike detection

spkall = load(['chdat_meansub' chname '_spikes.mat']); % load spike times from detection, including all that pass thredhold
spkall.index = spkall.index;
% par: [1×1 struct]
% threshold: [151.8461 150.4016 150.6069 150.6656]
% spikes: [11979×64 double]
% index: [1×11979 double]
% psegment: [1×100000 double]
% sr_psegment: 1.6667e+03

spksort = load(['times_chdat_meansub' chname '.mat']);
spksort.cluster_class(:, 2)= spksort.cluster_class(:, 2); % here correcting for the initial timestamp

%            spikes: [953×64 double]
%     cluster_class: [953×2 double]
%               par: [1×1 struct]
%        gui_status: [1×1 struct]
%              Temp: 13
%            forced: [1×953 logical]
%             inspk: [953×11 double]
%           ipermut: [1×953 double]

% spksort.cluster_class(:, 1) is the class definition, 0 unsorted, 1 sorted


figure(23); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 30 15], 'paperpositionmode', 'auto' )

ha=axes;
tdur=1;

tmax = floor(length(raw.index)/30000-tdur);

toplot=1;

ha2 = subplot(3, 2, [5]);
set(ha2, 'nextplot', 'add')
% plot sorted spikes
clusters = unique(spksort.cluster_class(:, 1));
nclusters = length(clusters);
allcolors = varycolor(3);

allcolors = [
    0 0 0
    0 0 1
    1 0 0
    0 1 0
    allcolors];

for k =1:nclusters-1
    
    if k <4
    plot(spksort.spikes(spksort.cluster_class(:, 1)== k, :)')
    
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        spkwave_avg = mean(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1);
        plot(spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 1);
    end;
    end;
end;

axis tight

 
    tnew = [1:length(raw.index)]*1000/30000;
    
    ha1 = subplot(3, 2, [1 2]); cla;
    set(ha1, 'ylim', [-800 800], 'nextplot', 'add')
    xlabel('Time (s)')
    
    
    ha4 = subplot(3, 2, [3 4]); cla;
    set(ha4, 'ylim', [-500 500], 'nextplot', 'add'); % this is LFP
    xlabel('Time (s)')
    
    linkaxes([ha1 ha4], 'x')
    
    
    ha3 = subplot(3, 2, 6);
    set(ha3, 'xlim', [0 25], 'nextplot', 'add')
    
    xlabel('Inter-spike interval (ms)')
    ylabel ('Counts')

    tbeg = trange(1);
    tend = trange(2);
    
    index_raw=find(tnew>=tbeg*1000 & tnew<=tend*1000);
    
    [b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
    
    %
    %    Wp = [700 8000]*2/Fs;
    %     Ws = [500 10000]*2/Fs;
    %     [N, Wn] = buttord(Wp, Ws, 3, 20);
    %     [B, A]=butter(N, Wn);
    %
    
    data_plot_hp = filtfilt(b_detect, a_detect, raw.data(index_raw));   % high-pass filter data
    
    axes(ha1)
    plot(tnew(index_raw)/1000, data_plot_hp,  'k');
    
    % plot detection
    index_detection = find(spkall.index>=tbeg*1000 &  spkall.index<=tend*1000);
    spk_peaks = min(spkall.spikes(index_detection, :), [], 2);
    
    plot(spkall.index(index_detection)/1000, spk_peaks, 'mo','markersize', 3)
    %     Either way, wave_clus generates a file times_filename.mat, with a variable cluster_class of two columns: the first column is the class of the spike and the second one is the spike time in ms.
    
    spk_peaks_max = prctile(min(spksort.spikes(find(spksort.cluster_class(:, 1) ~= 0), :),[], 2),  1);
    
    for k =1:nclusters-1
        
        if k<4
        if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
            
            axes(ha1)
            
            spk_time_sort = (spksort.cluster_class(find(spksort.cluster_class(:, 1) == k), 2)); % in ms
            spk_peaks_sort = prctile(spksort.spikes(find(spksort.cluster_class(:, 1) == k), :)',  5);
            
            if ~isempty(find(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000))
                plot([spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000 spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000]', [spk_peaks_max-100 spk_peaks_max],...
                    'linewidth', 2, 'color', allcolors(k+1, :));
            end;
            % ISI histogram
            
            edges = [0:1:25];
            [ncounts{k}] = histcounts(diff(spk_time_sort), edges);
            
            axes(ha3)
            plot(edges(2:end), ncounts{k}, 'color',  allcolors(k+1, :), 'linewidth', 1)
        end;
        end;
    end;
    
    axes(ha1)
    set(ha1, 'ylim', [-800 800], 'nextplot', 'add', 'xlim', [tbeg tend])
    axis tight
    %% LFP channel
%     % remove line noise
%     d = designfilt('bandstopiir','FilterOrder',2, ...
%         'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
%         'DesignMethod','butter','SampleRate',30000);
%     data_plot2 = filtfilt(d,raw.data(index_raw));
%     [b_detect,a_detect] = butter(2, [2 200]*2/30000, 'bandpass');  % field potential
%     data_plot_band = filtfilt(b_detect, a_detect, data_plot2); % band pass 2-200 hz
%     
%     axes(ha4)
%     plot(tnew(index_raw)/1000, data_plot_band/4,  'k');
%      
%     for k =1:nclusters-1
%         if k<4
%         if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
%             axes(ha4)
%             spk_time_sort = (spksort.cluster_class(find(spksort.cluster_class(:, 1) == k), 2)); % in ms
%             spk_peaks_sort = prctile(spksort.spikes(find(spksort.cluster_class(:, 1) == k), :)',  5);
%             if ~isempty(find(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000))
%                 plot([spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000 spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000]',...
%                     [-450 -350],...
%                     'linewidth', 2, 'color', allcolors(k+1, :));
%             end;
%         end;
%         end;
%     end;
%     set(ha4, 'ylim', [-1000 1000], 'nextplot', 'add', 'xlim', [tbeg tend])
%     % %
%     % %     axis tight
%     % %     end;
%     
%    
% 
% linkaxes([ha1 ha4], 'x')

% reply = input('Save this pic? Y/N [Y]:', 's');
% if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
%     print (gcf,'-dpng', ['waveclus_chdat' chname '_t' num2str(round(tbeg)) 's'])
% end;

