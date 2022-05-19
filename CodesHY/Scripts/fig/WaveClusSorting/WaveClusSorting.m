clear;
data_path = 'D:\Ephys\ANMs\Russo\Sessions\20210821\';
trange = 1447;
trange(2) = trange(1)+10;
vrange1 = [-2400 500];
vrange2 = [-200 300];
chname = '4';
name=[];

save_filename_pdf = './WaveClusSorting.pdf';
save_filename_png = './WaveClusSorting.png';
% save_filename_eps = 'c:/Users/jiumao/Desktop/WaveClusSorting.eps';
save_resolution = 1200;

rand('seed',25);

% load data
rawchname =  [data_path,'chdat' chname '.mat'];
if isempty(dir(rawchname))
    rawchname = [data_path,'chdat_meansub' chname '.mat'];
end
raw = load(rawchname); % if chname is 2, then load('chdat2.mat')
Fs=30000;
tall =  length(raw.index)/30000; % in seconds. 
% spike detection
x=dir([data_path,'chdat' chname '_spikes.mat']);
if isempty(x)
    x=dir([data_path,'chdat_meansub' chname '_spikes.mat']);
    spkall = load([data_path,x.name]);
    spksort = load([data_path,'times_chdat_meansub' chname '.mat']);
else
    spkall = load([data_path,'chdat' chname '_spikes.mat']); % load spike times from detection, including all that pass thredhold
    spksort = load([data_path,'times_chdat' chname '.mat']);
end
spkall.index = spkall.index;
spksort.cluster_class(:, 2)= spksort.cluster_class(:, 2); % here correcting for the initial timestamp

clusters = unique(spksort.cluster_class(:, 1));
nclusters = length(clusters)-1;

allcolors = varycolor(nclusters*2);
allcolors = allcolors(1:2:2*nclusters-1, :);
%% Figure Configuration
margin_left = 1;
margin_right = 0.5;
margin_up = 1;
margin_bottom = 0.5;
space_bottom_LFP = 0.5;
space_col = 0.5;

width_spike = 3;
height_spike = 2;
space_row_spike = 0.1;

width_ac = 3;
height_ac = 2;
space_row_ac = space_row_spike;
margin_bottpm_ac = 0.5;

width_channel = 10;
height_channel = 3.5;

width_raster = width_channel;
height_raster = 1.3;

width_LFP = width_channel;
height_LFP = height_channel/diff(vrange1)*diff(vrange2)*4;

space_LFP_raster = 0.5;
space_raster_channel = 0.2;

h = figure('unit', 'centimeters', 'paperpositionmode', 'auto' );
h.Position = [2,2,margin_left+margin_right+width_spike+width_ac+space_col*2+width_channel,...
    margin_up+margin_bottom+space_bottom_LFP+height_channel+height_raster+height_LFP+space_LFP_raster+space_raster_channel];
haspkwaveover = axes(h,'unit', 'centimeters', 'position', [margin_left+space_col+width_channel, margin_bottom, width_spike,height_spike], 'nextplot', 'add', 'ylim', vrange1);
axis(haspkwaveover,'off')
line(haspkwaveover,[0 30], [vrange1(end) vrange1(end)], 'linewidth', 2, 'color', 'k')
text(haspkwaveover,7, vrange1(2)+0.13*diff(vrange1), '1 ms', 'fontsize', 10);

haspkwave = zeros(nclusters-1,1);
for k =1:nclusters-1
    haspkwave(k) = axes(h,'unit', 'centimeters',...
        'position', [margin_left+space_col+width_channel, margin_bottom+(space_row_spike+height_spike)*k,width_spike,height_spike],...
        'nextplot', 'add',...
        'ylim', vrange1);
    axis(haspkwave(k),'off')
    spk_indx = find(spksort.cluster_class(:, 1)== k);
    rate_k = length(spk_indx)/tall;
    if length(spk_indx)>100
        spk_indx = spk_indx(randperm(length(spk_indx), 100));
    end
    plot(haspkwave(k),spksort.spikes(spk_indx, :)', 'color', [0.5 0.5 0.5])
    title(haspkwave(k),sprintf('%2.1f spk/s', rate_k),'FontSize',10) 
end

ax_ac = zeros(nclusters-1,1);
for k =1:nclusters-1
    ax_ac(k) = axes(h,'unit', 'centimeters',...
        'position', [margin_left+space_col*2+width_channel+width_spike, margin_bottpm_ac+margin_bottom+(space_row_spike+height_spike)*k,width_ac,height_ac-margin_bottpm_ac],...
        'nextplot', 'add',...
        'ylim', vrange1);

    spk_time = spksort.cluster_class(find(spksort.cluster_class(:, 1)== k),2);
    kutime2 = zeros(1, max(round(spk_time)));
    kutime2(round(spk_time))=1;

    [c, lags] = xcorr(kutime2, 25); % max lag 100 ms
    c(lags==0)=0;
    bar(ax_ac(k),lags,c,'facecolor', allcolors(k+1,:))
    set(ax_ac(k), 'nextplot', 'add', 'xtick', [], 'ytick', [0 max(c)]) 
    ylim(ax_ac(k),[0,max(c)+10])
    if k == 1
        xlabel(ax_ac(k),'Lag (ms)');
        ylim(ax_ac(k),[0,max(c)+1])
        set(ax_ac(k),'xtick', [-50:10:50]) 
    end
    
end


ax_channel = axes('unit', 'centimeters',...
    'position', [margin_left,margin_bottom+space_bottom_LFP+height_LFP+height_raster+space_LFP_raster+space_raster_channel,width_channel,height_channel],...
    'nextplot', 'add',...
    'ylim', vrange1/4,...
    'ytick', vrange1(1)/4:200:vrange1(2)/4,...
    'xlim', trange,...
    'xtick', []); 
axis(ax_channel,'off')
line(ax_channel,[trange(1) trange(1)+1], [vrange1(1)/4 vrange1(1)/4], 'linewidth', 2, 'color', 'k')
text(ax_channel,trange(1)+0.02*diff(trange), vrange1(1)/4-0.07*diff(vrange1)/4, '1 s', 'fontsize', 10);
line(ax_channel,[trange(1) trange(1)], [vrange1(1)/4 vrange1(1)/4+200], 'linewidth', 2, 'color', 'k')
text(ax_channel,trange(1)-0.04*diff(trange), vrange1(1)/4+0.00*diff(vrange1)/4, '200 \muV', 'fontsize', 10,'Rotation',90);
plot(ax_channel,trange(1),vrange1(1)/4,'.k')

ax_raster = axes(h,'unit', 'centimeters',...
    'position', [margin_left,margin_bottom+space_bottom_LFP+height_LFP+space_LFP_raster,width_raster,height_raster],...
    'nextplot', 'add',...
    'ylim', [0.5  max(4, nclusters)],...
    'xlim', trange);
axis(ax_raster,'off')

ax_LFP = axes(h,'unit', 'centimeters', 'position', [margin_left,margin_bottom+space_bottom_LFP,width_LFP,height_LFP],...
    'ytick', vrange2(1):200:vrange2(2),...
    'nextplot', 'add',...
    'ylim', vrange2,...
    'xlim', trange,...
    'xtick', trange(1):trange(2));
xlabel(ax_LFP,'Time (s)')
title(ax_LFP,'LFP (2-150 Hz)','fontsize', 10)
ax_LFP.XAxis.Visible = 'off';
axis(ax_LFP,'off');
% line(ax_LFP,[0 0], [vrange2(1) vrange2(1)+100], 'color', 'k', 'linewidth', 2)

%% Plotting
tnew = (1:length(raw.index))*1000/30000;
tbeg=trange(1);
tend = trange(2);
index_raw=find(tnew>=tbeg*1000 & tnew<=tend*1000);

% plot sorted spikes
for k =1:nclusters-1
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        spkwave_avg = mean(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1);
        
        plot(haspkwave(k),spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 2);
        
        plot(haspkwaveover,spkwave_avg, 'color', allcolors(k+1, :), 'linewidth', 1);
        
    end
end

[b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
data_plot_hp = filtfilt(b_detect, a_detect, raw.data(index_raw));   % high-pass filter data
plot(ax_channel,tnew(index_raw)/1000, data_plot_hp/4,  'color','k', 'linewidth', 0.5);

t_spikes = tnew(index_raw);
spike_index = spksort.cluster_class(:,2)>=tbeg*1000 & spksort.cluster_class(:,2)<=tend*1000;
for k =1:nclusters-1
    cluster_index = spksort.cluster_class(:,1)==k;
    spike_time = spksort.cluster_class(spike_index & cluster_index,2);
    for j = 1:length(spike_time)
        [~,temp_index] = min(abs(t_spikes-spike_time(j)));
        temp_index = max(0,temp_index-32):min(temp_index+32,length(t_spikes));
        plot(ax_channel,t_spikes(temp_index)/1000, data_plot_hp(temp_index)/4,  'color', allcolors(k+1, :), 'linewidth', 0.5);
    end
end

% plot detection
index_detection = find(spkall.index>=tbeg*1000 &  spkall.index<=tend*1000);
spk_peaks = min(spkall.spikes(index_detection, :), [], 2);

if ~isempty(index_detection)
    plot(ax_channel,spkall.index(index_detection)/1000, 0, 'm.','markersize', 5, 'linewidth', 2)
end
%     Either way, wave_clus generates a file times_filename.mat, with a variable cluster_class of two columns: the first column is the class of the spike and the second one is the spike time in ms.

spk_peaks_max = prctile(min(spksort.spikes(find(spksort.cluster_class(:, 1) ~= 0), :),[], 2),  1);

for k =1:nclusters-1
    if size(spksort.spikes(spksort.cluster_class(:, 1)== k, :), 1)>20
        spk_time_sort = (spksort.cluster_class(find(spksort.cluster_class(:, 1) == k), 2)); % in ms
        spk_peaks_sort = prctile(spksort.spikes(find(spksort.cluster_class(:, 1) == k), :)',  5);
        if ~isempty(find(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000, 1))
            plot(ax_raster,[spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000 spk_time_sort(spk_time_sort>=tbeg*1000 & spk_time_sort<=tend*1000)/1000]', [k k+0.8],...
                'linewidth', 2, 'color', allcolors(k+1, :));
        end
    end
end

%% LFP channel
% remove line noise
d = designfilt('bandstopiir','FilterOrder',2, ...
    'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
    'DesignMethod','butter','SampleRate',30000);

data_plot2 = filtfilt(d,raw.data(index_raw));

[b_detect,a_detect] = butter(2, [2 100]*2/30000, 'bandpass');  % field potential
data_plot_band = filtfilt(b_detect, a_detect, data_plot2); % band pass 2-200 hz

plot(ax_LFP,tnew(index_raw)/1000, data_plot_band/4,  'k', 'linewidth', 1)
linkaxes([ax_channel, ax_raster, ax_LFP], 'x')

%% Annotation
h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'A'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[0.5,8.8,1,1]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'B'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[11,8.8,1,1]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'C'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[14.5,8.8,1,1]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'D'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[0.5,3.2,1,1]);

%% Save Figure
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])
% print(h,save_filename_eps,'-depsc2',['-r',num2str(save_resolution)]) 
