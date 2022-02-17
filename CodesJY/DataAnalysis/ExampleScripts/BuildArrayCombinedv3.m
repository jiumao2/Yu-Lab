% generate NS6 file.
filenames = { 'datafile001.ns6',  'datafile002.ns6'};

for i =1:length(filenames)
    if i ==1
        openNSx(filenames{i}, 'read', 'report')
        NS6all= NS6;
    else
        openNSx(filenames{i}, 'read', 'report')
        NS6all(i)= NS6;
    end;
end;
 
% define channels
allchs = [1:39];
live_ch = [1:32]; % all live channels for 32-ch arrays (one can choose only a subset of these channels if not all channels have good data)
[~, ind_live]=intersect(allchs, live_ch);

Fs = 30000; % this is the sampling rate

%% extract data
pardata = 1;
if pardata ==1
    filelist =[];
    for i =1:length(live_ch)
        ii = ind_live(i);
        data = [];
        index =[];
        for k = 1:length(NS6all)
            NS6 = NS6all(k);
            if k>1
                dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
                dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % convert time to ms
            else
                dBlockOnset=0; % define the starting time of the first session as 0
            end;
            if iscell(NS6.Data)
                for k =1:length(NS6.Data)
                    % this is time in ms
                    index_k = [0:length(double(NS6.Data{k}(ii, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp(k)*1000/Fs+dBlockOnset;
                    % this is data of channel live_ch(i)
                    data_k =  double(NS6.Data{k}(ii, :));
                    if k==1;
                        data=   [data data_k]; % data is a necessary vector
                        index = [index index_k ];
                    else
                        % this is to take care of an old issue
                        data_k = data_k (index_k> index(end)+0.03);
                        index_k = index_k(index_k> index(end)+0.03);
                        data=   [data data_k]; % data is a necessary vector
                        index = [index index_k];
                    end;
                end;
            else
                index = [index [0:length(double(NS6.Data(ii, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset];
                data =  [data double(NS6.Data(ii, :))];
            end;
        end;
        
        savefile = ['chdat' num2str(live_ch(i)) '.mat']; % name of raw data files
        save(savefile, 'data', 'index');
        filelist{i}=savefile;
    end
    
% Extract analog input
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

%% This step is optional and can be improved. The idea is the subtract a common average signal from individual channels
allchs = [1:39];
live_ch = [1:32 ]; % all live channels for 2 16-wire arrays

% this is after data were extracted from NS6 file.
MakingAvgData;

load('chdatavg.mat')
[b_detect,a_detect] = ellip(4,0.1,40,[250 8000]*2/30000);  % high pass
avgdata = filtfilt(b_detect, a_detect, avgdata); % band pass 2-200 hz

figure(20); clf

ha=axes('nextplot', 'add', 'xlim', [50 60]);

for i =1:length(live_ch)
    load(['chdat' num2str(live_ch(i)) '.mat']);
    dataorg =data;
    ind_toplt = find(index>50*1000 & index <60*1000); % plot 10 seconds of data

    data = filtfilt(b_detect, a_detect, data); % band pass 2-200 hz
    data = data -avgdata;
    
    
    plot(index(ind_toplt), dataorg(ind_toplot)-i*100, 'color', 'k');
    plot(index(ind_toplt), data(ind_toplot)-i*100, 'color', [0 .5 0]);
    
    savefile = ['chdat_meansub' num2str(live_ch(i)) '.mat']; % name of files
    save(savefile, 'data', 'index');
    
    axis 'auto y'
end;


live_ch = [1:32 ]; % all live channels for 2 16-wire arrays

functional_channels = live_ch
 
nospike_channels = [1 ];

pos_detection =[  3 ];  % for channel 13, use positive detection

plot_trange = [118 123]; % plot 10 sec of data
    
tosort_list=[];
 

for i = 22
    live_ch = [1:32 ]; % all live channels for 2 16-wire arrays
    functional_channels = live_ch;
    indx = find(live_ch==functional_channels(i));
    
    
    tosort_list{1} = ['chdat_meansub' num2str(functional_channels(i)), '.mat'];
    
    param.sr = 30000;
    
    if ~isempty(find(pos_detection==functional_channels(i)))
        param.detection = 'pos';
    else
        param.detection = 'neg';
    end;
    
    param.detect_fmin = 250;               % high pass filter for detection
    param.detect_fmax = 8000;              % low pass filter for detection (default 1000)
    param.detect_order = 4;                % filter order for detection
    param.sort_fmin = 250;                 % high pass filter for sorting
    param.sort_fmax = 8000;                % low pass filter for sorting (default 3000)
    par.segments_length = 0.25;            % data will be precessing in segments of 15 seconds
    
    param.stdmin = 4.5;
    param.stdmax = 20;
    
    Get_spikes(tosort_list,'parallel',false,'par',param);
    Do_clustering(['chdat_meansub' num2str(functional_channels(i)), '_spikes.mat'])
    
end;

% 