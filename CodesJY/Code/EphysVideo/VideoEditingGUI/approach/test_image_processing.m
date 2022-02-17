function test_image_processing(path)
% get x_pos and y_pos
%[x_pos,y_pos] = find_pos(path)
x_pos = [932,1080];
y_pos = [4,122];

% get the path_med and path_bpod
path_date = [path(1:4),'-',path(5:6),'-',path(7:8)];
dir_med = 'F:\Thor\Thor Med Data';
dir_bpod = 'F:\Thor\Thor Session Data';

dir_output_med = dir(fullfile(dir_med,'*.txt'));
filenames_med = {dir_output_med.name};
for k = 1:length(filenames_med)
    if length(strfind(filenames_med{k},path_date))>=1
        path_med = fullfile(dir_med,filenames_med{k})
        break
    end
end

dir_output_bpod = dir(fullfile(dir_bpod,'*.mat'));
filenames_bpod = {dir_output_bpod.name};
for k = 1:length(filenames_bpod)
    if length(strfind(filenames_bpod{k},path(1:8)))>=1
        path_bpod = fullfile(dir_bpod,filenames_bpod{k})
        break
    end
end


% get filenames of all image
dir_output = dir(fullfile(path,'*.jpg'));

filenames = {dir_output.name};
filebytes = [dir_output.bytes];

% find background
bg = uint8(255*ones(x_pos(2)-x_pos(1)+1,y_pos(2)-y_pos(1)+1));
% bg_light = 0;
min_sum = sum(bg(:));
for k = 100:150
    img = imread([path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.jpg']);
%     area_light = img(x_pos_corr(1):x_pos_corr(2),y_pos_corr(1):y_pos_corr(2));
%     tmp_light = sum(area_light(:));
    img = img(x_pos(1):x_pos(2),y_pos(1):y_pos(2));
    tmp_sum = sum(img(:));
    if tmp_sum < min_sum
        bg = img;
        min_sum = tmp_sum;
%         bg_light = tmp_light;
    end
end


% find if light is on
ison = zeros(length(filenames),1);
diff_img = zeros(length(filenames),1);

parfor k = 201:(length(filenames)-2000)
        img = imread([path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.jpg']);
    %     area_light = img(x_pos_corr(1):x_pos_corr(2),y_pos_corr(1):y_pos_corr(2));
    %     img = img/(sum(area_light(:))/bg_light);
        img = img(x_pos(1):x_pos(2),y_pos(1):y_pos(2));
        tmp_diff = int32(img)-int32(bg);
        diff_img(k) = sum(tmp_diff(:));
    %     if sum(tmp_diff(:)) > threshold
    %         ison(k) = 1;
    %     end
end

% set threshold
threshold = max(diff_img) - 2e5;

figure;
plot(diff_img)
hold on
yline(threshold);
pause(0);

tmp_threshold = input('请输入阈值，输入0则继续，q则退出\n','s');
disp(tmp_threshold);
if ~strcmp(tmp_threshold,'0')
    if strcmp(tmp_threshold,'q')
        return
    else
        threshold = str2num(tmp_threshold);
        ison = (diff_img > threshold);
    end
end

ison = (diff_img > threshold);

new_path = [path,'_cut'];
mkdir(new_path);
video_range = -200:1:200;
parfor k = 201:length(filenames)-200
    % decide whether to make a video
    
    if ison(k) == 1 && ison(k-1) == 0 && ison(k+1) == 1 && ison(k+2) == 1 && ison(k-2) == 0
        % make a video      
        aviobj = VideoWriter([new_path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.avi']);
        aviobj.FrameRate = 50;
        open(aviobj)
        for j = 1:length(video_range)
            idx = k+video_range(j);
            writeVideo(aviobj,imread([path,'/',path(end-16:end),'.',num2str(idx,'%06d'),'.jpg']));
        end
        close(aviobj);
    end
    
end

% delete(gcp('nocreate'))

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
tmp_react_time1 = react_time(10:end-10);

min_error = 1e8;
min_k = 0;
for k = 1:length(event_time)-length(react_time)
    tmp_sum = 0;
    tmp_react_time = tmp_react_time1-tmp_react_time1(1)+event_time(k);
    for j = 1:length(tmp_react_time)
        tmp_sum = tmp_sum + min(abs(event_time-tmp_react_time(j)));
    end
    
    %disp([num2str(k),': ',num2str(tmp_sum)])
    
    if tmp_sum < min_error
        min_error = tmp_sum;
        min_k = k;
    end
    
    
end


figure;
plot(event_time,ones(1,length(event_time)),'x')
hold on
plot(react_time-(react_time(10)-event_time(max(min_k,1))),ones(1,length(react_time)),'.')

lag = react_time(10)-event_time(min_k);
react_time = react_time-lag;
% processing the avi files
mkdir([new_path,'/','long']);
mkdir([new_path,'/','short']);
mkdir([new_path,'/','long','/','stim']);
mkdir([new_path,'/','long','/','nostim']);
mkdir([new_path,'/','short','/','stim']);
mkdir([new_path,'/','short','/','nostim']);
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
end

    

end
