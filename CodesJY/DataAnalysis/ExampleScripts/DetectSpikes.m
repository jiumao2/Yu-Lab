% generate NS6 file.
filename = 'datafile002.ns6'
openNSx(filename, 'read', 'report') 

allchs = [1:16 33:48];
live_ch = [6 8 11]; % all live channels for 2 16-wire arrays

[~, ind_live]=intersect(allchs, live_ch);

Fs = 30000;
% This is raw data of c13
% chdat = cell(1, length(live_ch));
pardata = 1;
if pardata ==1
    filelist =[];
    for i =1:length(live_ch)
        ii = ind_live(i);
        data = [];
        index =[];
        if iscell(NS6.Data)
            for k =1:length(NS6.Data)
                index_k = [0:length(double(NS6.Data{k}(ii, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp(k)*1000/Fs;
                data_k =  double(NS6.Data{k}(ii, :));
                if k==1;
                    data=   [data_k]; % data is a necessary vector
                    index = [index_k ];
                else
                    data_k = data_k (index_k> index(end)+0.03);
                    index_k = index_k(index_k> index(end)+0.03);
                    data=   [data data_k]; % data is a necessary vector
                    index = [index index_k];
                end;
            end;
            
        else
            
            index = [0:length(double(NS6.Data(ii, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs;
            data =  double(NS6.Data(ii, :));
            
        end;
        
        savefile = ['chdat' num2str(live_ch(i)) '.mat']; % name of files
        save(savefile, 'data', 'index');
        filelist{i}=savefile;
    end;
    
    % analog input
    data = [];
    index =[];
    
    if iscell(NS6.Data)
        for k =1:length(NS6.Data)
            index_k = [0:length(double(NS6.Data{k}(end, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp(k)*1000/Fs;
            data_k =  double(NS6.Data{k}(end, :));
            if k==1;
                data=   [data_k]; % data is a necessary vector
                index = [index_k ];
            else
                data_k = data_k (index_k> index(end)+0.03);
                index_k = index_k(index_k> index(end)+0.03);
                data=   [data data_k]; % data is a necessary vector
                index = [index index_k];
            end;
        end;
        
    else
        
    index = [0:length(double(NS6.Data(end, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs;
    data =  double(NS6.Data(end, :));
    
end;

savefile = ['ForceSensor' , '.mat']; % name of files
save(savefile, 'data', 'index');

end;

functional_channels =live_ch;
% functional_channels = [1:16 36 ];

nospike_channels = [1 ];

pos_detection =[];  % for channel 13, use positive detection

plot_trange = [118 123]; % plot 10 sec of data
    
figure(20); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 35 25], 'paperpositionmode', 'auto' )

ha1 = subplot(1, 2, 1)
set(ha1, 'xlim', [plot_trange(1)*1000 plot_trange(2)*1000], 'ylim', [-500-16*300 500], 'nextplot', 'add');
title(['ch#' '1-16, band pass 2-200 Hz'])

line([plot_trange(1)*1000 plot_trange(1)*1000+2000], [0 0], 'color', 'k', 'linewidth', 3)
text(plot_trange(1)*1000+100, 200, '2sec', 'color', 'k', 'fontsize', 12)

axis off

ha2 = subplot(1, 2, 2)
set(ha2, 'xlim', [plot_trange(1)*1000 plot_trange(2)*1000], 'ylim', [-500-16*300 500], 'nextplot', 'add');
title(['ch#' '33-48, band pass 2-200 Hz'])

axis off

figure(21); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 35 25], 'paperpositionmode', 'auto' )

figure(22); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 35 25], 'paperpositionmode', 'auto' )

ha3 = subplot(1, 2, 1)
set(ha3, 'xlim', [plot_trange(1)*1000 plot_trange(2)*1000], 'ylim', [-100-16*300 200], 'nextplot', 'add');
title(['ch#' '1-16, high pass 2-200 Hz'])
line([plot_trange(1)*1000 plot_trange(1)*1000+2000], [0 0], 'color', 'k', 'linewidth', 3)
text(plot_trange(1)*1000+100, 200, '2sec', 'color', 'k', 'fontsize', 12)

axis off

ha4 = subplot(1, 2, 2)
set(ha4, 'xlim', [plot_trange(1)*1000 plot_trange(2)*1000], 'ylim', [-100-16*300 200], 'nextplot', 'add');
title(['ch#' '33-48, high pass 2-200 Hz'])
 
axis off
tosort_list=[];

for i = 1:length(functional_channels);
    
    indx = find(live_ch==functional_channels(i));
    
%     tosort_list{i, 1} = ['chdat' num2str(functional_channels(i)), '.mat'];
    tosort_list{1} = ['chdat' num2str(functional_channels(i)), '.mat'];
    
    param.stdmin = 4;
    param.sr = 30000;
    
    if ~isempty(find(pos_detection==functional_channels(i)))
        param.detection = 'pos';
    else
        param.detection = 'neg';
    end;
    
    param.detect_fmin = 250;               % high pass filter for detection
    param.detect_fmax = 5000;              % low pass filter for detection (default 1000)
    param.detect_order = 4;                % filter order for detection
    param.sort_fmin = 250;                 % high pass filter for sorting
    param.sort_fmax = 5000;                % low pass filter for sorting (default 3000)
    par.segments_length = 0.25;            % data will be precessing in segments of 15 seconds
    
    Get_spikes(tosort_list,'parallel',false,'par',param);
    
    chspikes = load(['chdat'  num2str(functional_channels(i)) '_spikes.mat']);
    % struct with fields:
    % par: [1×1 struct]
    % threshold: 147.9486
    % spikes: [584×64 double]
    % index: [1×584 double]
    % psegment: [1×100000 double]
    % sr_psegment: 1.6667e+03
    
    load(['chdat' num2str(functional_channels(i)) '.mat']); % index and data
    
    data_plot = data(index>=plot_trange(1)*1000 & index<=plot_trange(2)*1000);
    index_plot = index(index>=plot_trange(1)*1000 & index<=plot_trange(2)*1000);   
       
    % remove line noise
    d = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',48,'HalfPowerFrequency2',52, ...
        'DesignMethod','butter','SampleRate',param.sr);
    data_plot2 = filtfilt(d,data_plot);
    
    [b_detect,a_detect] = butter(2, [2 200]*2/param.sr, 'bandpass');  % field potential
    data_plot_band = filtfilt(b_detect, a_detect, data_plot2); % band pass 2-200 hz
    
    [b_detect,a_detect] = ellip(param.detect_order,0.1,40,[250 5000]*2/param.sr);  % high pass
    data_plot_hp = filtfilt(b_detect, a_detect, data_plot); % band pass 2-200 hz

    figure(21)   
    if i<=16
        axes(ha1)
        addon = -300*i;
    else
        axes(ha2)
        addon = -300*(i-16);
    end;
    
    plot(index_plot, data_plot_band/5+addon, 'k')
    hold on
    
    spikeindex_trange = find(chspikes.index>=plot_trange(1)*1000 & chspikes.index<=plot_trange(2)*1000);
    if ~isempty(spikeindex_trange)
        line([chspikes.index(spikeindex_trange); chspikes.index(spikeindex_trange)], [-50 50]/5+addon, 'color', 'r', 'linewidth', 1.5)
        %
    end;
    
    text(plot_trange(2)*1000-1, addon+50, ['#' num2str(functional_channels(i))], 'color', 'r', 'fontsize', 12);
    
    xlabel('Time (ms)')
    ylabel ('Artificial unit')
    
    figure(22)
    if i<=16
        axes(ha3)
        addon = -300*i;
    else
        axes(ha4)
        addon = -300*(i-16);
    end;
    
    plot(index_plot, data_plot_hp/2+addon, 'k')
    hold on
    
     if ~isempty(spikeindex_trange)
        line([chspikes.index(spikeindex_trange); chspikes.index(spikeindex_trange)], [-50 50]/2+addon, 'color', 'r', 'linewidth', 1.5)
        %
    end;
    
    text(plot_trange(2)*1000-1, addon+50, ['#' num2str(functional_channels(i))], 'color', 'r', 'fontsize', 12);
    
    xlabel('Time (ms)')
    ylabel ('Artificial unit')
    
    axis off
    
    figure(21)
    subplot(4, 8, indx)
    title(['ch#' num2str(functional_channels(i))])
    set(gca, 'xlim', [0 64]/30, 'nextplot', 'add', 'ylim', [-800 600]);
    if size(chspikes.spikes, 1)>100
        toplot = randperm(size(chspikes.spikes, 1), 100);
    else
        toplot = [1:100];
    end;
    
    waveindex = [1:64]/30;
    plot(waveindex, chspikes.spikes(toplot, :), 'r')
    
    xlabel('Time (ms)')
    ylabel ('Artificial unit')
    
    axis off
     
end;

print (20,'-dpng', ['LFP_spike_all' ])
print (21,'-dpng', ['spike_wave_all'])
print (22,'-dpng', ['HP_signal_all'])