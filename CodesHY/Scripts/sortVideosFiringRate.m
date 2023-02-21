event = 'Press';
camview = 'side';
num_unit = 15;
t_pre = -500;
t_post = 500;

spike_count = zeros(length(r.VideoInfos_side),1);

for k = 1:length(spike_count)
    t_press = r.VideoInfos_side(k).Time;
    t_release = r.VideoInfos_side(k).Time+r.VideoInfos_side(k).Foreperiod+r.VideoInfos_side(k).ReactTime;
    if strcmpi(event,'press')
        spike_count(k) = sum(r.Units.SpikeTimes(num_unit).timings>t_press+t_pre & r.Units.SpikeTimes(num_unit).timings<t_press+t_post);
    elseif strcmpi(event,'release')
        spike_count(k) = sum(r.Units.SpikeTimes(num_unit).timings>t_release+t_pre & r.Units.SpikeTimes(num_unit).timings<t_release+t_post);
    end
end


[~,idx_sort] = sort(spike_count,'descend');

%%
video_dir = ['VideoFrames_',camview,'/SortedVideo/'];
if ~exist(video_dir,'dir')
    mkdir(video_dir);
end

% video_name = ['Unit',num2str(num_unit),'.avi'];
% 
% vid = VideoWriter(fullfile(video_dir,video_name));
% vid.open();
% 
% for k = 1:length(idx_sort)
%     vid2 = VideoReader(fullfile('VideoFrames_top/RawVideo/',...
%         ['Press',num2str(r.VideoInfos_top(idx_sort(k)).Index,'%03d'),'.avi']));
%     for j = 0:2:50
%         temp = r.VideoInfos_top(idx_sort(k));
%         n_start = round((-temp.t_pre+temp.Foreperiod+temp.ReactTime)/10);
%         if n_start+j>temp.total_frames || isnan(n_start)
%             disp('Wrong!')
%             break
%         end
%         vid.writeVideo(vid2.read(n_start+j));
%     end
%     k
% end
% vid.close();

%% Sorted videos
if strcmp(camview,'side')
    VideoInfos_this = r.VideoInfos_side;
elseif strcmp(camview,'top')
    VideoInfos_this = r.VideoInfos_top;
end

for k = 1:length(idx_sort)
    temp = VideoInfos_this(idx_sort(k));
    idx = temp.Index;
    if strcmpi(event, 'press')
        n_start = round(-temp.t_pre/10);
    elseif strcmpi(event,'release')
        n_start = round((-temp.t_pre+temp.Foreperiod+temp.ReactTime)/10);
    end
    n_range = (-100:4:50) + n_start;
    if n_range(end)>temp.total_frames || any(isnan(n_range))
        continue;
    end
    
    date_this = [num2str(r.Meta(1).DateTimeRaw(1),'%04d'),num2str(r.Meta(1).DateTimeRaw(2),'%02d'),num2str(r.Meta(1).DateTimeRaw(4),'%02d')];
    notes = {[r.Meta(1).Subject,' ',date_this,' Trial No.',num2str(idx)],...
        ['Performance: ',temp.Performance,...
        '; FP=',num2str(temp.Foreperiod),...
        'ms; RT=',num2str(temp.ReactTime),...
        'ms']};
    
    % Trajectory
    if isfield(temp,'Trajectory')
        if ~isempty(VideoInfos_this(idx_sort(k)).Trajectory) && (VideoInfos_this(idx_sort(k)).Trajectory==1 || VideoInfos_this(idx_sort(k)).Trajectory==2)
            traj = ['No.',num2str(VideoInfos_this(idx_sort(k)).Trajectory)];
        else
            traj = 'None';
        end    
        notes = [notes,'Traj: ',traj];
    end
    if strcmpi(event,'press')
        t_seq = temp.VideoFrameTime(n_range) - temp.Time;
        spiketime_seq{1} = VideoInfos_this(idx_sort(k)).Units.SpikeTimes(num_unit).timings - temp.Time;
    elseif strcmpi(event,'release')
        t_seq = temp.VideoFrameTime(n_range) - temp.Time - temp.Foreperiod - temp.ReactTime;
        spiketime_seq{1} = VideoInfos_this(idx_sort(k)).Units.SpikeTimes(num_unit).timings - temp.Time - temp.Foreperiod - temp.ReactTime;
    end

    spiketime_seq{1} = spiketime_seq{1}(spiketime_seq{1}>=t_seq(1));
    spiketime_seq{1} = spiketime_seq{1}(spiketime_seq{1}<=t_seq(end));
    
    vid_read = VideoReader(['.\VideoFrames_',camview,'\RawVideo\',temp.Event,num2str(idx,'%03d'),'.avi']);
    
    img_seq = cell(1,length(n_range));
    for j = 1:length(n_range)
        img_seq{j} = vid_read.read(n_range(j));
    end
    dir_name = ['.\VideoFrames_',camview,'\SortedVideo\Unit',num2str(num_unit)];
    if ~exist(dir_name,'dir')
        mkdir(dir_name);
    end
    moviename = ['.\VideoFrames_',camview,'\SortedVideo\Unit',num2str(num_unit),'/Sorted',num2str(k,'%03d'),'.avi'];
    MakeFrameRasterVideo(img_seq,spiketime_seq,t_seq,moviename,notes);
    
end

