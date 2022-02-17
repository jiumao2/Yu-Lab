function move_video(path,path_med,path_bpod)
% path = path_avi

% % get the path_med and path_bpod
% path_date = [path(end-20:end-17),'-',path(end-16:end-15),'-',path(end-14:end-13)];
% dir_med = 'C:\Users\A\Desktop\Pineapple\Pineapple Med Data';
% dir_bpod = 'C:\Users\A\Desktop\Pineapple\Pineapple Session Data';
% 
% dir_output_med = dir(fullfile(dir_med,'*.txt'));
% filenames_med = {dir_output_med.name};
% for k = 1:length(filenames_med)
%     if length(strfind(filenames_med{k},path_date))>=1
%         path_med = fullfile(dir_med,filenames_med{k})
%         break
%     end
%     if k == length(filenames_med)
%         warning('no med data, return')
%         return
%     end
% end
% 
% dir_output_bpod = dir(fullfile(dir_bpod,'*.mat'));
% filenames_bpod = {dir_output_bpod.name};
% for k = 1:length(filenames_bpod)
%     if length(strfind(filenames_bpod{k},path(end-20:end-13)))>=1
%         path_bpod = fullfile(dir_bpod,filenames_bpod{k})
%         break
%     end
%     if k == length(filenames_bpod)
%         warning('no bpod data, return')
%         return
%     end
% end

if exist(fullfile(path,'long')) || exist(fullfile(path,'short'))
    disp('已有分类视频')
    return;
end

new_path = path;
path = new_path(1:end-4);
% new_path = [path,'_cut'];

% get the light-on time in the videos
react_time = [];
dir_output = dir(fullfile(new_path,'*.avi'));
filenames = {dir_output.name};
for k = 1:length(filenames)
    react_time = [react_time,str2num(filenames{k}(end-9:end-4))/100];
end
react_time = sort(react_time,'ascend');

% get the react time from the med data
Time_events = med_to_tec_new(path_med,100);
[len_event, ~] = size(Time_events);
event_time = [];
event_length = [];
for k = 1:len_event
    if Time_events(k,2) == 1 && Time_events(k+2,2) == 11
        if Time_events(k+1,2) == 55 
            event_time = [event_time, Time_events(k+1,1)];
            event_length = [event_length,1];
        elseif Time_events(k+1,2) == 54 
            event_time = [event_time, Time_events(k+1,1)];
            event_length = [event_length,0];    
        end
    end
end

% get the stimulus data from bpod
stim = get_stim_data(path_med,path_bpod);
stim(1:length(stim)-length(event_time)) = [];

% align the two data
start = 10;
tmp_react_time1 = react_time(start:start + 20);

min_error = 1e8;
min_k = 0;
for k = 1:length(event_time)-length(react_time)
    tmp_sum = 0;
    tmp_react_time = tmp_react_time1-tmp_react_time1(1)+event_time(k);
    for j = 1:length(tmp_react_time)
        tmp_sum = tmp_sum + min(abs(event_time-tmp_react_time(j)));
    end
    
    % disp([num2str(k),': ',num2str(tmp_sum)])
    
    if tmp_sum < min_error
        min_error = tmp_sum;
        min_k = k;
    end
    
    
end
% mapping med data to tone data
lag = react_time(start)-event_time(min_k);
for k = 5:length(react_time)
    event_time(min_k+k-start:end) = event_time(min_k+k-start:end) + (react_time(k)-lag-event_time(min_k+k-start));
    %react_time(k:end) = react_time(k:end) - (react_time(k)-event_time(min_k+k-start));
end

figure;
plot(event_time,ones(1,length(event_time)),'x')
hold on
plot(react_time-(react_time(start)-event_time(min_k)),ones(1,length(react_time)),'.')
% plot(react_time,ones(1,length(react_time)),'.')
pause(0)

% lag = react_time(start)-event_time(min_k);
react_time = react_time-lag;

% processing the avi files
mkdir(fullfile(new_path,'long'));
mkdir(fullfile(new_path,'short'));
mkdir(fullfile(new_path,'long','stim'));
mkdir(fullfile(new_path,'long','nostim'));
mkdir(fullfile(new_path,'short','stim'));
mkdir(fullfile(new_path,'short','nostim'));

for k = max(min_k-9,1):min_k-9 + length(react_time)-1
    tmp_event = event_time(k);
    if k == 1
        d_min = event_time(k+1)-event_time(k);
    else
        d_min = min(event_time(k)-event_time(k-1),event_time(k+1)-event_time(k));
    end
    
    for j = 1:length(react_time)
        if react_time(1)>= tmp_event
            filename = [path,'.',num2str(round((react_time(1)+lag)*100),'%06d'),'.avi'];
            d_min_react = react_time(1) - tmp_event;
            break
        elseif react_time(end) <= tmp_event
            filename = [path,'.',num2str(round((react_time(end)+lag)*100),'%06d'),'.avi'];
            d_min_react = tmp_event - react_time(end);
            break
        end
        
        if react_time(j) <= tmp_event && react_time(j+1) >= tmp_event
            d1 = tmp_event - react_time(j);
            d2 = react_time(j+1) - tmp_event;
            if d1<d2
                filename = [path,'.',num2str(round((react_time(j)+lag)*100),'%06d'),'.avi'];
            else
                filename = [path,'.',num2str(round((react_time(j+1)+lag)*100),'%06d'),'.avi'];
            end
            d_min_react = min(d1,d2);
            
            break
        end

    end
    filename = filename(end-27:end);
    if exist(fullfile(new_path,filename))
    
    if d_min_react < d_min
        if event_length(k) == 1
            if stim(k) == 1
                movefile(fullfile(new_path,filename), fullfile(new_path,'long','stim',filename));
            elseif stim(k) == 0
                movefile(fullfile(new_path,filename), fullfile(new_path,'long','nostim',filename));
            else
                movefile(fullfile(new_path,filename), fullfile(new_path,'long',filename));
            end
        elseif event_length(k) == 0
            if stim(k) == 1
                movefile(fullfile(new_path,filename), fullfile(new_path,'short','stim',filename));
            elseif stim(k) == 0
                movefile(fullfile(new_path,filename), fullfile(new_path,'short','nostim',filename));
            else
                movefile(fullfile(new_path,filename), fullfile(new_path,'short',filename));
            end
        end
    end
    else
        warning(['no match for',fullfile(new_path,filename)])
    end
    
end

end