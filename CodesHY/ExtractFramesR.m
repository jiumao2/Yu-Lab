function r = ExtractFramesR(r, ts, varargin)
% requires "Video" field in r
    events = {};

    time_range = [-2000, 2000]; % in ms

    camview = 'side';
    frame_rate_seq = 100;
    frame_rate_out = 100;
    start_trial = 1;
    folder = pwd;

    if nargin > 2
        for i = 1:2:size(varargin,2)
            switch varargin{i}
                case 'events'
                    events = varargin{i+1};
                case 'time_range'
                    time_range = varargin{i+1};
                case 'camview'
                    camview = varargin{i+1}; 
                case 'frame_rate'
                    frame_rate_seq = varargin{i+1}; 
                case 'frame_rate_out'
                    frame_rate_out = varargin{i+1};
                case 'start_trial'
                    start_trial = varargin{i+1}; 
                case 'folder'
                    folder = varargin{i+1};
                otherwise
                    errordlg('unknown argument')
            end
        end
    end

    assert(frame_rate_seq == 100 || frame_rate_seq == 50);
    frame_interval = round(1000 / frame_rate_seq);
    frame_range = time_range./frame_interval;

    t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
    t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverRelease')));
    correct_index = r.Behavior.CorrectIndex;
    premature_index = r.Behavior.PrematureIndex;
    late_index = r.Behavior.LateIndex;
    FPs = r.Behavior.Foreperiods;
    RTs = t_release - t_press - FPs;
    RTs(RTs<0) = NaN;

    % determine which segment
    switch camview
        case 'side'
            if isfield(r.Video, 't_frameon_side')
                t_frameon = r.Video.t_frameon_side;
            else
                indframe = find(strcmp(r.Video.Labels, 'SideFrameOn'));
                t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
            end
        case 'top'
            if isfield(r.Video, 't_frameon_top')
                t_frameon = r.Video.t_frameon_top;
            else
                indframe = find(strcmp(r.Video.Labels, 'TopFrameOn'));
                t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
            end
        otherwise
            disp('Check camera view')
            return;
    end

    ind_break = zeros(1, length(ts.(camview)));
    n_frames = 0;
    for k = 1:length(ts.(camview))
        ind_break(k) = n_frames+1;
        n_frames = n_frames + length(ts.(camview)(k).ts);
    end

    t_seg = cell(1, length(ind_break));
    for i = 1:length(ind_break)
        if i < length(ind_break)
            t_seg{i} = t_frameon(ind_break(i):ind_break(i+1)-1);
        else
            t_seg{i} = t_frameon(ind_break(i):end);
        end
    end

    %% Events
    switch events
        case 'Press'
            event_sort = t_press;
        case 'Release'
            event_sort = t_release;
    end

    for i = start_trial:length(event_sort)
        idx_vid_file = 1;
        nstart = 0;
        for j = 1:length(t_seg)
            t_seg_this = t_seg{j};
            if t_press(i) > t_seg{j}(end)
                nstart = nstart + length(t_seg{j});
                idx_vid_file = idx_vid_file + 1;
            else
                break
            end
        end

        t_event_n = event_sort;

        ind_frame_event_all = findNearestPoint(t_frameon, t_event_n(i));
        ind_frame_event = ind_frame_event_all - nstart; % this is the frame position in that movie clip

        if isempty(ind_frame_event) ||... % no trial found
            (ind_frame_event <= -frame_range(1)) ||... % the trial starts before the video 
            (ind_frame_event + frame_range(2) >= length(t_seg_this)) ||... % the trial ends after the video
            any(isnan(t_frameon((frame_range(1):frame_range(end)) + ind_frame_event_all)))
            continue;
        end

        % compute dt between assumed start time and real start time
        t_start_assumed = time_range(1);
        d_frame = frame_range(1);
        t_start_real = t_frameon(round(ind_frame_event_all + d_frame)) - t_frameon(ind_frame_event_all);
        dt_start = t_start_real - t_start_assumed;

        t_end_assumed = time_range(2);
        d_frame = frame_range(2);
        t_end_real = t_frameon(round(ind_frame_event_all + d_frame)) - t_frameon(ind_frame_event_all);
        dt_end = t_end_real - t_end_assumed;
        
        if abs(dt_start) > frame_interval
            fprintf('The trial is skipped because the difference of start time > 10 ms\n dt = %f\n', dt_start);
            continue
        end

        if abs(dt_end) > frame_interval
            fprintf('The trial is skipped because the difference of end time > 10 ms\n dt = %f\n', dt_end);
            continue
        end
            RT_ni = RTs(i);
            FP_ni = FPs(i);
            if find(i==correct_index)
                performance = 'Correct';
            elseif find(i==premature_index)
                performance = 'Premature';
            elseif find(i==late_index)
                performance = 'Late';
            else
                performance = 'Others';
            end

            frames_to_extract_range = frame_range + ind_frame_event;

            % now let's make videos
            frames_to_extract = frames_to_extract_range(1):frames_to_extract_range(end); % now let's extract all frames
            tframes_to_extract = t_frameon((frame_range(1):frame_range(end)) + ind_frame_event_all); % this is the time of plotted frames, session time, not segment time

            thisFolder = fullfile(folder, ['VideoFrames_',camview], 'Video');
            thisFolder2 = fullfile(folder, ['VideoFrames_',camview], 'RawVideo');
            mat_dir = fullfile(folder, ['VideoFrames_',camview], 'MatFile');

            if ~exist(thisFolder, 'dir')
                mkdir(thisFolder)
            end

            if ~exist(thisFolder2, 'dir')
                mkdir(thisFolder2)
            end
            if ~exist(mat_dir,'dir')
                mkdir(mat_dir);
            end

            % make videos
            vidfile = ts.([lower(camview), 'views']){idx_vid_file};
            moviename = [thisFolder2,'/',events, num2str(i,'%03d'),'.avi'];

            writerObj = VideoWriter(moviename);
            writerObj.FrameRate = frame_rate_out; % this is 1 x slower
            % set the seconds per image
            % open the video writer
            open(writerObj);
            % write the frames to the video
            for frame_index = 1:length(frames_to_extract)
                frame = ReadJpegSEQ2(vidfile, frames_to_extract(frame_index)); % ica is image cell array
                writeVideo(writerObj, frame);
            end

            % close the writer object
            close(writerObj);

            VideoInfo.AnimalName = r.Meta(1).Subject;
            temp_time = datetime(r.Meta(1).DateTime, 'Locale', 'en_US');
            VideoInfo.SessionName = [num2str(temp_time.Year,'%04d'),num2str(temp_time.Month,'%02d'),num2str(temp_time.Day,'%02d')];
            VideoInfo.Event = events;
            VideoInfo.Index = i;
            if isfield(r.Behavior,'CueIndex') && ~isempty(r.Behavior.CueIndex)
                VideoInfo.Cue = r.Behavior.CueIndex(i,2);
            end
            VideoInfo.Time = t_event_n(i);
            VideoInfo.Foreperiod = FP_ni;
            VideoInfo.ReactTime = RT_ni;
            VideoInfo.t_pre = time_range(1);
            VideoInfo.t_post = time_range(2);
            VideoInfo.total_frames = length(frames_to_extract);

            VideoInfo.Performance = performance;
            VideoInfo.VideoFilename = vidfile;
            VideoInfo.VideoFrameIndex = frames_to_extract + nstart;
            VideoInfo.VideoFrameTime = tframes_to_extract;

            save([mat_dir,'/',events,num2str(i,'%03d'),'.mat'], 'VideoInfo');
            close all;

            fprintf('[%d / %d] %s done!\n', i, length(event_sort), moviename);
    end
end
