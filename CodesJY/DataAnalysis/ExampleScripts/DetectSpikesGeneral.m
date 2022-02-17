%% Read NS6 file.
ns6_files = dir('*.ns6');
if length(ns6_files)>0
    for i =1:length(ns6_files)
        if i ==1
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all= NS6;
        else
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all(i)= NS6;
        end;
    end;
else
    return
end;

%% Define channels
Nch = 32;
AllChs = [1:Nch 33:39];
EphysChs =[1:Nch];
LiveChs = [1 3 4 5 6 7 8 15 18 19 20  26]; % all live channels for 32-ch arrays (one can choose only a subset of these channels if not all channels have good data)
AllChs = [LiveChs 33:39];

[~, ind_live]=intersect(AllChs, LiveChs);
Fs = 30000; % this is the sampling rate

RMS_Chs = zeros(1, 32);  % we use this to select "good" chs which will be used later to construct a common avg. 
ind_exp = [1:30000*30];  % 30 seconds of data
DataExp = [];

%% Extract ephys data
pardata = 1;
if pardata ==1
    filelist =[];
    for i =1:length(EphysChs)
        ii = EphysChs(i);
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
                    % this is data of channel LiveChs(i)
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
        
        RMS_Chs(i) = rms(data);
        DataExp(:, i) = data(ind_exp);
        
        savefile = ['chdat' num2str(ii) '.mat']; % name of raw data files
        save(savefile, 'data', 'index');
        filelist{i}=savefile;
    end
    
   
    %% Extract analog input
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
    savefile = ['ForceSensor' , '.mat']; % this is the force sensor data
    save(savefile, 'data', 'index');
end;

%% This step is optional and can be improved. The idea is the subtract a common average signal from individual channels
% select "Good channels" to construct a Common Avg
clc
disp('Select threshold to define good channels, end selection by a right click');

figure(26); clf(26)
set(gcf, 'name', 'noise levels', 'units', 'centimeters', 'position', [20 10 15 20])
ha1 = subplot(2, 1, 1)
set(ha1, 'nextplot', 'add')
histogram(RMS_Chs, 10);
xlabel('RMS')
ylabel('Count')

ha2 = subplot(2, 1, 2)
set(ha2, 'nextplot', 'add')

for i=1:length(RMS_Chs)
    hp(i) = plot(DataExp(:, i)-(i-1)*2000, 'color', 'k');
end;

axes(ha1)
[x_th] = getpts(gcf);
x_th = min(x_th);
line([x_th x_th], get(ha1, 'ylim'), 'linestyle', ':')

ind_good = find(RMS_Chs < x_th);
ind_bad = find(RMS_Chs > x_th);
ChsGood = EphysChs(ind_good);  % these are the index of good Chs

for i =1:length(ind_bad)
    set(hp(ind_bad(i)), 'color', [0.8 0.8 0.8])
end;

axis tight
 
CommonAvg(ChsGood);  % this will save a 'CommonAvgData.mat' file

%% Remove common average
load('CommonAvgData.mat')
[b_detect,a_detect]     =       ellip(4,0.1,40,[250 8000]*2/Fs);  % high pass
for i =1:length(LiveChs)
    tic
    load(['chdat' num2str(LiveChs(i)) '.mat']);
    data = round(filtfilt(b_detect, a_detect, (data-CommonAvgData))); % band pass 2-200 hz 
    savefile = ['chdat_meansub' num2str(LiveChs(i)) '.mat']; % name of files
    save(savefile, 'data', 'index');
    toc
end;

%% Spike detection and sorting
functional_channels = LiveChs;
pos_detection =[ ];  % for channel 13, use positive detection
tosort_list=[];

for i = 1:length(functional_channels)
    indx = find(LiveChs==functional_channels(i));
    tosort_list{1} = ['chdat_meansub' num2str(functional_channels(i)), '.mat'];
    param               =           set_parameters();
    param.sr           =           Fs;
    if ~isempty(find(pos_detection==functional_channels(i)))
        param.detection = 'pos';
    else
        param.detection = 'neg';
    end;
    param.detect_fmin               =       250;               % high pass filter for detection
    param.detect_fmax               =       8000;              % low pass filter for detection (default 1000)
    param.detect_order              =       4;                % filter order for detection
    param.sort_fmin                    =        250;                 % high pass filter for sorting
    param.sort_fmax                    =        8000;                % low pass filter for sorting (default 3000)
    param.segments_length        =          1;            % data will be precessing in segments of 15 seconds
    
    param.stdmin                         =          4;
    param.stdmax                        =       50;
    
    Get_spikes(tosort_list,'parallel',false,'par',param);
    Do_clustering(['chdat_meansub' num2str(functional_channels(i)), '_spikes.mat'])
end;