% meta info
lesion_index = 4;

% load b
dir_out = dir('./B_*.mat');
filename = dir_out.name;
load(filename);

% load timestamps
load timestamps.mat

press_out = struct();
press_out.LesionIndex = lesion_index;
press_out.PawUsage = {'Left: 1', 'Right: 2', 'Both: 3'};
press_out.OutcomeLabels = {'Correct: 1', 'Premature: -1', 'Late: 0'};
press_out.RatName = b.Metadata.SubjectName;
press_out.SessionName = b.Metadata.Date;

%% start to label hands
outcome_all = [];
release_index_all = [];
press_time_all = [];
release_time_all = [];
FPs_all = [];
RTs_all = [];
release_paw_all = [];
%% if mislabeled, change `count` to previous one
count = 0;

if count>length(release_index_all)
    error('Please set count smaller than the length of press_paw_all!');
end
if isempty(release_index_all)
    release_idx_start = 1;
else
    release_idx_start = release_index_all(count)+1;
end

video_path_running = ts.VidFilenames{1};
vid = VideoReader(video_path_running);
for k = release_idx_start:length(b.ReleaseTime)
    release_idx = k;
    press_time_this = b.PressTime(k)*1000;
    release_time_this = b.ReleaseTime(k)*1000;
    % get performance
    if any(b.Correct == k)
        outcome = 1;
    elseif any(b.Premature == k)
        outcome = -1;
    elseif any(b.Late == k)
        outcome = 0;
    else
        continue
    end

    % label the hand
    if ts.FrameTimes(1) > release_time_this
        continue
    end

    frame_release = findNearestPoint(ts.FrameTimes, release_time_this);
    frames_all = [frame_release+10, frame_release+5, frame_release, frame_release-5, frame_release-10];
    if frame_release > sum(ts.Nframe)
        break
    end

    vid_idx = find(frame_release <= cumsum(ts.Nframe), 1);
    if vid_idx > 1
        frame_release = frame_release - sum(ts.Nframe(1:vid_idx-1));
        frames_all = frames_all - sum(ts.Nframe(1:vid_idx-1));
    end

    video_path = ts.VidFilenames{vid_idx};
    if ~strcmp(video_path, video_path_running) 
        video_path_running = video_path;
        vid = VideoReader(video_path);
    end
    
    fig = EasyPlot.figure();
    ax_all = EasyPlot.createGridAxes(fig,1,5,...
        'XAxisVisible','off',...
        'YAxisVisible','off',...
        'Width', 7,...
        'Height', 7,...
        'YDir','reverse');
    
    for j = 1:length(frames_all)
        if frames_all(j) > vid.NumFrames || frames_all(j) <= 0
            continue
        end
        img = vid.read(frames_all(j));
        image(ax_all{end-j+1}, img);
        title(ax_all{end-j+1}, ['Frame = ', num2str(frames_all(j)-frame_release)]);
    end
    EasyPlot.cropFigure(fig);
    
    while true
        out = input('Enter 1 for left press. Enter 2 for right press. Enter 3 for both press. Enter 0 to skip. Enter ? to check the video\n', 's');
        if out == '1'
            hand = 1;
            break
        elseif out == '2'
            hand = 2;
            break
        elseif out == '3'
            hand = 3;
            break
        elseif out == '0'
            hand = NaN;
            break
        elseif out == '?'
            % check the video
            idx_start = max(1, frame_release-20);
            idx_end = min(vid.NumFrames, frame_release+20);
            fig_video = EasyPlot.figure();
            ax_video = EasyPlot.axes(fig_video,...
                'XAxisVisible', 'off',...
                'YAxisVisible', 'off',...
                'YDir', 'reverse',...
                'Width', 10, ...
                'Height', 10);
            img = vid.read(idx_start);
            ax_video.Position(3) = size(img, 2)/size(img, 1)*10;
            xlim(ax_video, [0, size(img, 2)]);
            ylim(ax_video, [0, size(img, 1)]);
            im = image(ax_video, img);
            EasyPlot.cropFigure(fig_video);
            for i = idx_start:idx_end
                im.CData = vid.read(i);
                title(ax_video, num2str(i-frame_release));
                pause(0.1);
            end
            close(fig_video);
        end
    end

    disp(['Press ',num2str(release_idx), ' (out of ', num2str(length(b.ReleaseTime)), ' trials): ', num2str(hand)]);
    close all;

    if isnan(hand)
        continue
    end
    
    % save data
    count = count+1;
    outcome_all(count) = outcome;
    release_paw_all(count) = hand;
    release_index_all(count) = release_idx;
    press_time_all(count) = press_time_this;
    release_time_all(count) = release_time_this;
    FPs_all(count) = b.FPs(release_idx);

    if outcome == -1
        RTs_all(count) = NaN;
    else
        RTs_all(count) = b.ReleaseTime(release_idx)*1000 - b.PressTime(release_idx)*1000 - b.FPs(release_idx);
    end

    if any(RTs_all<0)
        error('RT is less than 0!');
    end

end



%% save PressOut
if lesion_index > 0
    save_filename = ['PressOut_', press_out.RatName, '_postIndex_', num2str(abs(lesion_index)), '.mat'];
else
    save_filename = ['PressOut_', press_out.RatName, '_preIndex_', num2str(abs(lesion_index)), '.mat'];
end

if exist(fullfile('./', save_filename), 'file')
    disp('PressOut.mat found!');
    load(fullfile('./', save_filename));

    % search for same index
    idx_same = intersect(PressOut.PressIndex, release_index_all');

    idx_in_PressOut = findSeq(PressOut.PressIndex, idx_same);
    idx_new = findSeq(release_index_all', idx_same);
    if length(PressOut.PressIndex) ~= length(release_index_all) || any(PressOut.PressIndex ~= release_index_all')
        warning('Labelled paws in press / release are different');
    end

    PressOut.ReleasePaw(idx_in_PressOut) = release_paw_all(idx_new);
else
    disp('PressOut.mat not found! Create a new file!');
    PressOut = press_out;

    PressOut.PressIndex = release_index_all';
    PressOut.PressTime = press_time_all';
    PressOut.Outcome = outcome_all;
    PressOut.FPs = FPs_all';
    PressOut.RTs = RTs_all;
    PressOut.PressPaw = NaN(1, length(release_time_all));
    
    PressOut.FlexOnset = NaN(1, length(release_time_all));
    PressOut.TouchOnset = NaN(1, length(release_time_all));
    PressOut.ReleaseOnset = NaN(1, length(release_time_all));
    PressOut.HoldPaw = NaN(1, length(release_time_all));
    PressOut.ReleasePaw = release_paw_all;
end

save(save_filename, 'PressOut');