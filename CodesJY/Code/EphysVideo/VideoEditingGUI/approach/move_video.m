function move_video(path,path_med,path_bpod)
% path = path_avi

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
event_time_all = [];
event_length_all = [];
event_time = [];
event_length = [];
for k = 1:len_event
    if Time_events(k,2) == 1
        if Time_events(k,2) == 1 && Time_events(k+2,2) == 11
            if Time_events(k+1,2) == 55 
                event_time = [event_time, Time_events(k+2,1)];
                event_time_all = [event_time_all, Time_events(k+2,1)];
                event_length = [event_length,1];
                event_length_all = [event_length_all,1];
            elseif Time_events(k+1,2) == 54 
                event_time = [event_time, Time_events(k+2,1)];
                event_time_all = [event_time_all, Time_events(k+2,1)];
                event_length = [event_length,0];    
                event_length_all = [event_length_all, 0];
            end
            
        else
            event_time_all = [event_time_all, 0];
            event_length_all = [event_length_all,-1];  
        end
    end
end

[bnew,bpod_to_MED] =  getBehaviorApproach(path_med, path_bpod);

% get the stimulus data from bpod
[approach_time_bpod, approach_stim, approach_presstime] = get_stim_data(path_med,path_bpod);

% align the two data & get the frame rate of the video
start = 10;
%tmp_react_time1 = react_time(start:end);

min_frame_rate = 0;
min_error = 1e8;
min_k = 0;
for frame_rate = 95:0.01:105
    for k = 1:length(event_time)-length(react_time)
        tmp_react_time1 = react_time(start:end)/(frame_rate/100);
        tmp_sum = 0;
        tmp_react_time = tmp_react_time1-tmp_react_time1(1)+event_time(k);
        for j = 1:length(tmp_react_time)
            tmp_sum = tmp_sum + min(abs(event_time-tmp_react_time(j)));
        end

        % disp([num2str(k),': ',num2str(tmp_sum)])

        if tmp_sum < min_error
            min_error = tmp_sum;
            min_k = k;
            min_frame_rate = frame_rate;
        end
    end
end

react_time = react_time/(min_frame_rate/100);

% mapping med data to tone data
event_time_origin = event_time;
lag = react_time(start)-event_time(min_k);
for k = start:length(react_time)
    [~, idx] = min(abs(react_time-lag-event_time(min_k+k-start)));
    event_time(min_k+k-start:end) = event_time(min_k+k-start:end) + (react_time(idx)-lag-event_time(min_k+k-start));
end

for k = start:-1:1
    %[~, idx] = min(abs(react_time-lag-event_time(min_k+k-start)));
    idx = k;
    if min_k+k-start > 0
        event_time(1:min_k+k-start) = event_time(1:min_k+k-start) + (react_time(idx)-lag-event_time(min_k+k-start));
    end
end

% update the approach_presstime and approach_time_bpod
event_time_all_origin =  event_time_all;
event_time_all_origin(event_time_all_origin~=0) = event_time_origin;
event_time_all(event_time_all~=0) = event_time;
event_time_all = event_time_all(bpod_to_MED);
event_time_all_origin = event_time_all_origin(bpod_to_MED);
approach_presstime(approach_presstime~=0);
approach_presstime(approach_presstime~=0) = approach_presstime(approach_presstime~=0) + event_time_all - event_time_all_origin;
j = 0;
for k = 1:length(approach_time_bpod)
    if  approach_presstime(k) ~= 0 
        j = j+1;
        approach_time_bpod(k) = approach_time_bpod(k) + event_time_all(j) -  event_time_all_origin(j);
    elseif j ~= 0
        approach_time_bpod(k) = approach_time_bpod(k) + event_time_all(j) -  event_time_all_origin(j);
    end
end
    
event_length_all = event_length_all(bpod_to_MED);


figure;
plot(event_time,ones(1,length(event_time)),'x')
hold on
plot(react_time-(react_time(start)-event_time(min_k)),ones(1,length(react_time)),'.')
pause(0)

approach_time_bpod = approach_time_bpod+lag;
approach_presstime(approach_presstime~=0) = approach_presstime(approach_presstime~=0) + lag;
event_time = event_time + lag;
event_time_all(event_time_all~=0) = event_time_all(event_time_all~=0) + lag;


% cut video based on mask-start time
approach_path = [path,'_approach'];
mkdir(approach_path);
mkdir([approach_path,'\stim']);
mkdir([approach_path,'\stim\long']);
mkdir([approach_path,'\stim\short']);
mkdir([approach_path,'\stim\others']);
mkdir([approach_path,'\nostim']);
mkdir([approach_path,'\nostim\long']);
mkdir([approach_path,'\nostim\short']);
mkdir([approach_path,'\nostim\others']);
mkdir([approach_path,'\approach_frames'])
video_range = -2*100:6*100;

expanded_event_length = approach_presstime;
expanded_event_length(expanded_event_length~=0) = event_length_all;
disp('开始剪切')
dir_output = dir(fullfile(path,'*.jpg'));
filenames_length = length({dir_output.name});

load([path,'.mat'])
my_time = time;

parfor k = 1:length(approach_time_bpod)
    time_tmp = approach_time_bpod(k)*100*(min_frame_rate/100);
    [~,index_time] = min(abs(my_time - time_tmp));
    time_tmp = index_time;
    is_stim = -1;
    if time_tmp>300 && time_tmp<filenames_length-700
        if approach_stim(k) == 1
            is_stim = 1;
            if approach_presstime(k) ~= 0 && expanded_event_length(k) ~= -1 
                if expanded_event_length(k) == 1
                     path_tmp = [approach_path,'\stim\long\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                elseif expanded_event_length(k) == 0
                     path_tmp = [approach_path,'\stim\short\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                else
                    mkdir([approach_path,'\stim\other_length'])
                    path_tmp = [approach_path,'\stim\other_length\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                end
            else
                path_tmp = [approach_path,'\stim\others\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
            end
        else
            is_stim = 0;
            if approach_presstime(k) ~= 0 && expanded_event_length(k) ~= -1 
                if expanded_event_length(k) == 1
                     path_tmp = [approach_path,'\nostim\long\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                elseif expanded_event_length(k) == 0
                     path_tmp = [approach_path,'\nostim\short\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                else
                    mkdir([approach_path,'\nostim\other_length'])
                    path_tmp = [approach_path,'\nostim\other_length\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
                end
            else
                 path_tmp = [approach_path,'\nostim\others\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.avi'];
            end
        end
        
        copyfile([path,'\',path(end-16:end),'.',num2str(round(time_tmp),'%06d'),'.jpg'],[approach_path,'\approach_frames']);
        
        disp(path_tmp)
        aviobj = VideoWriter(path_tmp);
        aviobj.FrameRate = 100;
        open(aviobj)
%         x_stim = 200 + [zeros(1,100*2),-100*ones(1,100*4+1),zeros(1,100*2+1)];
%         x_nostim = 200*ones(8*100+1);
%         y_stim = [linspace(101,300,100*2),linspace(300,700,100*4+1),linspace(700,900,100*2+1)];
%         y_nostim = linspace(101,900,length(x));
        for j = 1:length(video_range)
            idx = round(time_tmp+video_range(j));
            frame_tmp = imread([path,'/',path(end-16:end),'.',num2str(idx,'%06d'),'.jpg']);
%             if is_stim == 1
%                 y_tmp = y_stim(y_stim<=(video_range(j)+301));
%                 x_tmp = x_stim(1:length(y_tmp));
%             else
%                 y_tmp = y_nostim(y_nostim<=(video_range(j)+301));
%                 x_tmp = x_nostim(1:length(y_tmp));
%             end
%             figure(1);clf(1);
%             imshow(frame_tmp);
%             hold on
%             plot(y_tmp,x_tmp,'w-')
%             F = getframe(gca);
%             close(1)
%             frame = rgb2gray(F.cdata(2:801,:,:));
            if is_stim == 1
                if video_range(j)<0
                    frame_tmp(200-1:200+1,101:video_range(j)+301) = uint8(255);
                else
                    frame_tmp(200-1:200+1,101:300) = uint8(255);
                    frame_tmp(200:-1:100,300-1:300+1) = uint8(255);
                    if video_range(j) < 400
                        frame_tmp(100-1:100+1,300:video_range(j)+301) = uint8(255);
                    else
                        frame_tmp(100-1:100+1,300:700) = uint8(255);
                        frame_tmp(100:200,700-1:700+1) = uint8(255);
                        frame_tmp(200-1:200+1,700:video_range(j)+301) = uint8(255);
                    end
                end
            else
                frame_tmp(200-1:200+1,101:video_range(j)+301) = uint8(255);
            end
            writeVideo(aviobj,frame_tmp);
        end
        
        close(aviobj);
    end
    
end
    

end