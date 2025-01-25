rat_name = 'Pierce';
folder_r = fullfile('../Sessions/');
folder_video = './';
dir_output = dir(folder_video);

filenames = {dir_output.name};

folder_data = {};
for k = 1:length(filenames)
    folder_this = filenames{k};
    if length(folder_this) ~= 15
        continue
    end

    if ~exist(fullfile(folder_video, folder_this), 'dir')
        continue
    end

    folder_data{end+1} = folder_this;
end

disp(folder_data)

bad_folders = {'20241106_videos'};

%%
for i_folder = 1:length(bad_folders)
%     folder_this = folder_data{i_folder};
    folder_this = bad_folders{i_folder};
    session = folder_this(1:8);
    load(fullfile(folder_video, folder_this, 'timestamps.mat'));    
    r_file = fullfile(folder_r, session, ['RTarray_', rat_name, '_', session, '.mat']);

    if ~exist(r_file, 'file')
        continue
    end
    load(r_file);


    %% get trigger times from videos
    trigger_times_start_idx = [];
    trigger_times_end_idx = [];
    flag = false;
    for k = 1:length(ts.intensity)-23
        if all(ts.intensity(k:k+23)>ts.threshold)
            if ~flag
                trigger_times_start_idx = [trigger_times_start_idx, k];
            end
            flag = true;
        else
            if flag
                trigger_times_end_idx = [trigger_times_end_idx, k];
            end
            flag = false;
        end
    end
    
    t_side_all = [];
    t_top_all = [];
    for k = 1:length(ts.sideviews)
        t_side_all = [t_side_all, ts.side(k).ts+ReadTimestampSEQ(ts.sideviews{k},1)];
    end

    for k = 1:length(ts.topviews)
        t_top_all = [t_top_all, ts.top(k).ts+ReadTimestampSEQ(ts.topviews{k},1)];
    end
    
    trigger_times_start_vid = t_side_all(trigger_times_start_idx);
%     trigger_times_end_vid = t_side_all(trigger_times_end_idx);
    
    % %% Some points might be removed manually
    % idx_remove = findNearestPoint(trigger_times_start_vid, trigger_times_start_vid(1)+2304610);
    % idx_remove = [1,2];
    % trigger_times_start_vid(idx_remove) = [];
    % trigger_times_start_idx(idx_remove) = [];
%     %% get trigger times from r
%     press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
%     FPs = r.Behavior.Foreperiods;
%     
%     % deal with problems of shape
%     if size(press_times,1)~=1
%         press_times = press_times';
%     end
%     if size(FPs,1)~=1
%         FPs = FPs';
%     end
%     
%     trigger_times = press_times + FPs;
%     trigger_times = trigger_times(sort([r.Behavior.CorrectIndex,r.Behavior.LateIndex]));
    load(fullfile(folder_r, session, 'EventOut.mat'));
    idx_trigger = find(strcmpi(EventOut.EventsLabels, 'Trigger'));
    trigger_times = EventOut.Onset{idx_trigger}';

    if length(trigger_times_start_vid) > length(trigger_times)
        idx = findseqmatch(trigger_times_start_vid, trigger_times);

        trigger_times_start_vid = trigger_times_start_vid(idx);
        trigger_times_start_idx = trigger_times_start_idx(idx);
    end

    %% Align
    idx_out = findseqmatch(trigger_times,trigger_times_start_vid);
    
    figure;
    plot(trigger_times-trigger_times(idx_out(1)),2, 'ro')
    hold on
    plot(trigger_times_start_vid-trigger_times_start_vid(1),1,'bx');
    for k = 1:length(idx_out)
        plot([trigger_times_start_vid(k)-trigger_times_start_vid(1),...
            trigger_times(idx_out(k))-trigger_times(idx_out(1))],...
            [1,2], 'k-');
    end
    
    time_maps = [trigger_times(idx_out);trigger_times_start_vid];
    
    time_diff = trigger_times(idx_out)-trigger_times_start_vid;
    time_diff = time_diff-time_diff(1);
    
    frames_times_side = align_times(t_side_all, time_maps);
    frames_times_top = align_times(t_top_all, time_maps);
    
    time_diff_corrected = trigger_times(idx_out)-frames_times_side(trigger_times_start_idx);
    time_diff_corrected = time_diff_corrected-time_diff_corrected(1);
    
    h = figure;
    plot(time_diff ,'bx-')
    hold on
    plot(time_diff_corrected ,'ro-')
    
    print(h, fullfile(folder_video, folder_this, 'Alignment.png'), '-dpng', '-r600');
    
    %% save to r
    r.Video.t_frameon_side = frames_times_side;
    r.Video.t_frameon_top = frames_times_top;
    save(fullfile(folder_video, folder_this, 'RTarrayAll.mat'), 'r');
    
    %% Check minimum of frame intervals
    n_frames_side = zeros(1, length(ts.side));
    n_frames_top = zeros(1, length(ts.top));

    min_frame_interval = 1e8;
    for k = 1:length(ts.side) - 1
        n_frames_side(k) = length(ts.side(k).ts);
        n_cumsum = sum(n_frames_side(1:k));
        min_frame_interval = min(min_frame_interval,...
            frames_times_side(n_cumsum+1)-frames_times_side(n_cumsum));
    end

    for k = 1:length(ts.top) - 1
        n_frames_top(k) = length(ts.top(k).ts);
        n_cumsum = sum(n_frames_top(1:k));
        min_frame_interval = min(min_frame_interval,...
            frames_times_top(n_cumsum+1)-frames_times_top(n_cumsum));
    end

    
    frame_intervals_top = diff(frames_times_top);
    frame_intervals_top = sort(frame_intervals_top, 'descend');
    disp('Top frame intervals in top-view videos:')
    disp(frame_intervals_top(frame_intervals_top>min_frame_interval));
    disp('');
    
    if sum(frame_intervals_top>min_frame_interval) > length(ts.topviews)-1
        disp([num2str(sum(frame_intervals_top>min_frame_interval)) ' Intervals found!']);
        error('Too many intervals. Please set larger "min_frame_interval"');
    end
    
    frame_intervals_side = diff(frames_times_side);
    frame_intervals_side = sort(frame_intervals_side, 'descend');
    disp('Frame intervals that is higher than 1000 in top-view videos:')
    disp(frame_intervals_side(frame_intervals_side>min_frame_interval));
    disp('');
    
    if sum(frame_intervals_side>min_frame_interval) > length(ts.sideviews)-1
        disp([num2str(sum(frame_intervals_side>min_frame_interval)) ' Intervals found!']);
        error('Too many intervals. Please set larger "min_frame_interval"');
    end

    ts.min_frame_interval = min_frame_interval;
    fprintf('min_frame_interval = %d\n', min_frame_interval);
    save(fullfile(folder_video, folder_this, 'timestamps.mat'), 'ts');

    close all;
end