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
Nch = 16;
EphysChs =[1:Nch];
LiveChs =EphysChs; % all live channels for 32-ch arrays (one can choose only a subset of these channels if not all channels have good data)
AllChs = [LiveChs 33:39];

[~, ind_live]=intersect(AllChs, LiveChs);
Fs = 30000; % this is the sampling rate

data_avg = [];
ndata = 0;

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

        savefile = ['chdat' num2str(ii) '.mat']; % name of raw data files
        save(savefile, 'data', 'index');

        if isempty(data_avg)
            ndata =1;
            data_avg = data;
        else
            data_avg = (data_avg*ndata + data)/(ndata+1);
            ndata = ndata +1;
        end;

    end

    save('AvgData', 'data_avg');

    for i =1:length(EphysChs)
        ii = EphysChs(i);
        savefile = ['chdat' num2str(ii) '.mat']; % name of raw data files
        load(savefile);
        data = round(data - data_avg);
        save(savefile, 'data', 'index');
    end;

end;

%     %% Extract analog input
%     data = [];
%     index =[];
% 
%     SignalName = 'ForceSensor';
%     ind_ai_1 = 22;
%     for k = 1:length(NS6all)
%         NS6 = NS6all(k);
%         if k>1
%             dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
%             dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % convert time to ms
%         else
%             dBlockOnset=0; % define the starting time of the first session as 0
%         end;
%         index = [index [0:length(double(NS6.Data(ind_ai_1, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset];
%         data =  [data double(NS6.Data(ind_ai_1, :))];
%     end;
% 
%     savefile = [SignalName , '.mat']; % this is the force sensor data
%     save(savefile, 'data', 'index');
% 
% 
%     SignalName = 'LaserSignal';
%     data = [];
%     index =[];
%     ind_ai_2 = 23;
%     for k = 1:length(NS6all)
%         NS6 = NS6all(k);
%         if k>1
%             dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
%             dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % convert time to ms
%         else
%             dBlockOnset=0; % define the starting time of the first session as 0
%         end;
%         index = [index [0:length(double(NS6.Data(ind_ai_2, :)))-1]*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset];
%         data =  [data double(NS6.Data(ind_ai_2, :))];
%     end;
% 
%     savefile = [SignalName , '.mat']; % this is the force sensor data
%     save(savefile, 'data', 'index');

%% Spike detection and sorting
functional_channels = LiveChs;
pos_detection =[ ];  % for channel 13, use positive detection
tosort_list=[];

for i = 1:length(functional_channels)
    indx = find(LiveChs==functional_channels(i));
    tosort_list{1} = ['chdat' num2str(functional_channels(i)), '.mat'];
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
    param.sort_fmax                    =        5000;                % low pass filter for sorting (default 3000)
    param.segments_length        =          1;            % data will be precessing in segments of 15 seconds
    param.stdmin                         =          4;
    param.stdmax                        =       50;

    Get_spikes(tosort_list,'parallel',false,'par',param);
    Do_clustering(['chdat' num2str(functional_channels(i)), '_spikes.mat'])
end;