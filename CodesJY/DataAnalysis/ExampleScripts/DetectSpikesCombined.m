% generate NS6 file.
filenames = { 'datafile002.ns6', 'datafile003.ns6',  'datafile004.ns6'};

for i =1:length(filenames)
    if i ==1
        openNSx(filenames{i}, 'read', 'report')
        NS6all= NS6;
    else
        openNSx(filenames{i}, 'read', 'report')
        NS6all(i)= NS6;
    end;
end;
 
allchs = [1:39];
live_ch = [1:32]; % all live channels for 2 16-wire arrays

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
        for k = 1:length(NS6all)
            NS6 = NS6all(k);
            if k>1
                dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw;
                dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
            else
                dBlockOnset=0;
            end;
            if iscell(NS6.Data)
                for k =1:length(NS6.Data)
                    index_k = [0:length(double(NS6.Data{k}(ii, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp(k)*1000/Fs+dBlockOnset;
                    data_k =  double(NS6.Data{k}(ii, :));
                    if k==1;
                        data=   [data data_k]; % data is a necessary vector
                        index = [index index_k ];
                    else
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
        
        savefile = ['chdat' num2str(live_ch(i)) '.mat']; % name of files
        save(savefile, 'data', 'index');
        filelist{i}=savefile;
    end;
    
%     analog input
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
allchs = [1:39];

live_ch = [1:32 ]; % all live channels for 2 16-wire arrays

% this is after data were extracted from NS6 file.
MakingAvgData;

load('chdatavg.mat')
[b_detect,a_detect] = ellip(4,0.1,40,[250 8000]*2/30000);  % high pass
avgdata = filtfilt(b_detect, a_detect, avgdata); % band pass 2-200 hz

for i =1:length(live_ch)
    load(['chdat' num2str(live_ch(i)) '.mat']);
    data = filtfilt(b_detect, a_detect, data); % band pass 2-200 hz
    data = data -avgdata;
    
    savefile = ['chdat_meansub' num2str(live_ch(i)) '.mat']; % name of files
    save(savefile, 'data', 'index');
end;


functional_channels = live_ch
 
nospike_channels = [1 ];

pos_detection =[  ];  % for channel 13, use positive detection

plot_trange = [118 123]; % plot 10 sec of data
    
tosort_list=[];
 

for i = 1:length(functional_channels);
    
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
        
    param.stdmin = 3.5; 
    param.stdmax = 200;
    
    Get_spikes(tosort_list,'parallel',false,'par',param); 
    Do_clustering(['chdat_meansub' num2str(functional_channels(i)), '_spikes.mat'])
    
end;

% 