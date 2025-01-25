%% set meta info
t_pre = -2400;
t_post = 3000;
%% get the target folders
folder_root = 'E:\Videos';
rat_names = {'Jalan', 'Jaya', 'Klang', 'Putra', 'Sunway'};
folder_data = {};

for k = 1:length(rat_names)
    dir_out = dir(fullfile(folder_root, rat_names{k}));
    folder_out = {dir_out.name};
    for j = 1:length(folder_out)
        if length(folder_out{j}) ~= 8
            continue
        end
        folder_data{end+1} = fullfile(folder_root, rat_names{k}, folder_out{j});
    end
end

%% make video clips in each folder
for i_folder = 1:length(folder_data)
    folder_this = folder_data{i_folder};
    fprintf('Start processing %s ...\n', folder_this);

    load(fullfile(folder_this, 'timestamps.mat'));

    dir_out = dir(fullfile(folder_this, 'B_*.mat'));
    if isempty(dir_out) || length({dir_out.name}) > 1
        error(['B file error in ', folder_this]);
    end
    load(fullfile(folder_this, dir_out.name));
    
    press_times = b.PressTime*1000;
    release_times = b.ReleaseTime*1000;
    
    video_path = fullfile(folder_this, '/VideoFrames_top/');
    if ~exist(video_path, 'dir')
        mkdir(video_path);
    end
    
    for k = 1:length(press_times)
        % only include correct trials
        if ~any(b.Correct == k)
            continue
        end
        
        % get the frame index for the output videos
        idx_frame_press = findNearestPoint(ts.FrameTimesTop, press_times(k));
        idx_frames = idx_frame_press+(t_pre/10):idx_frame_press+(t_post/10); % FPS = 10
        
        % get the index of raw video file
        nframe_cumsum = cumsum(ts.NframeTop);
        idx_seg = find(nframe_cumsum > idx_frames(1), 1); 
        
        if isempty(idx_seg)
            continue
        end
        
        % get the frame index in the raw video file
        idx_frames_seg = idx_frames - sum(ts.NframeTop(1:idx_seg-1));
    
        if idx_frames_seg(1) < 1 || idx_frames_seg(end) > ts.NframeTop(idx_seg)
            continue
        end
        
        % only include videos that do not lose frames
        if abs(ts.FrameTimesTop(idx_frames(1)) - ts.FrameTimesTop(idx_frame_press) - t_pre) > 10
            fprintf('Skip trial %d for losing frames!\n', k);
            continue
        end
    
        if abs(ts.FrameTimesTop(idx_frames(end)) - ts.FrameTimesTop(idx_frame_press) - t_post) > 10
            fprintf('Skip trial %d for losing frames!\n', k);
            continue
        end
    
        % make the videos
        video_folder = fullfile(folder_this, 'VideoFrames_top/RawVideo/');
        video_name = fullfile(video_folder, ['Press', num2str(k, '%03d'), '.avi']);
        mat_folder = fullfile(folder_this, 'VideoFrames_top/MatFile/');
        mat_name = fullfile(mat_folder, ['Press', num2str(k, '%03d'), '.mat']);
    
        if ~exist(video_folder, 'dir')
            mkdir(video_folder);
        end
    
        if ~exist(mat_folder, 'dir')
            mkdir(mat_folder);
        end

        if exist(video_name, 'file') && exist(mat_name, 'file')
            try
                vid_obj = VideoReader(video_name);
                if vid_obj.NumFrames == 541
                    fprintf('%s already exist!\n', video_name);
                    continue
                end
            catch
                disp(['Reprocessing ', video_name]);
            end
        end
    
        vid_obj = VideoWriter(video_name);
        vid_obj.open();
        for j = 1:length(idx_frames_seg)
            img = ReadJpegSEQ(fullfile(folder_this, ts.topviews{idx_seg}), idx_frames_seg(j));
    
            vid_obj.writeVideo(img);
        end
        vid_obj.close();
        
        % save the meta info of the videos
        VideoInfo.AnimalName = b.Metadata.SubjectName;
        VideoInfo.SessionName = b.Metadata.Date;
        VideoInfo.Event = 'Press';
        VideoInfo.Index = k;
        VideoInfo.Time = press_times(k);
        VideoInfo.Foreperiod = b.FPs(k);
        VideoInfo.ReactTime = release_times(k) - VideoInfo.Foreperiod - VideoInfo.Time;
        VideoInfo.t_pre = t_pre;
        VideoInfo.t_post = t_post;
        VideoInfo.total_frames = length(idx_frames);
        if any(b.Correct == k)
            VideoInfo.Performance = 'Correct';
        elseif any(b.Premature == k)
            VideoInfo.Performance = 'Premature';
        elseif any(b.Late == k)
            VideoInfo.Performance = 'Late';
        else
            VideoInfo.Performance = 'Others';
        end
        VideoInfo.VideoFilename = ts.topviews{idx_seg};
        VideoInfo.VideoFrameIndex = idx_frames_seg;
        VideoInfo.VideoFrameTime = ts.FrameTimesTop(idx_frames);
    
        save(mat_name, 'VideoInfo');
        
        if mod(k, 10) == 1
            fprintf('%d / %d videos done!\n', k, length(press_times));
        end
    end

    fprintf('%s done!\n', folder_this);
end

