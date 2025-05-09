% meta info
lesion_index = -2;

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

% start to label hands
outcome_all = [];
press_index_all = [];
press_time_all = [];
FPs_all = [];
RTs_all = [];
press_paw_all = [];
%% if mislabeled, change `count` to previous one
count = 0;

if count>length(press_index_all)
    error('Please set count smaller than the length of press_paw_all!');
end
if isempty(press_index_all)
    press_idx_start = 1;
else
    press_idx_start = press_index_all(count)+1;
end

for k = press_idx_start:length(b.PressTime)
    press_idx = k;
    press_time_this = b.PressTime(k)*1000;
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
    if ts.FrameTimesSide(1) > press_time_this
        continue
    end

    frame_press = findNearestPoint(ts.FrameTimesSide, press_time_this);
    frames_all = [frame_press+20, frame_press+10, frame_press, frame_press-10, frame_press-20];
    if any(frames_all > sum(ts.NframeSide))
        break
    end

    vid_idx = find(frame_press <= cumsum(ts.NframeSide), 1);
    if vid_idx > 1
        frame_press = frame_press - sum(ts.NframeSide(1:vid_idx-1));
        frames_all = frames_all - sum(ts.NframeSide(1:vid_idx-1));
    end

    video_path = ts.sideviews{vid_idx};
    
    fig = EasyPlot.figure();
    ax_all = EasyPlot.createGridAxes(fig,1,5,...
        'XAxisVisible','off',...
        'YAxisVisible','off',...
        'Width', 7,...
        'Height', 7,...
        'YDir','reverse');
    
    for j = 1:length(frames_all)
        if frames_all(j) > ts.NframeSide(vid_idx) || frames_all(j) <= 0
            continue
        end
        img = ReadJpegSEQ2(video_path, frames_all(j));
        image(ax_all{end-j+1}, img);
        EasyPlot.colormap(ax_all, 'gray');
        title(ax_all{end-j+1}, ['Frame = ', num2str(frames_all(j)-frame_press)]);
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
            idx_start = max(1, frame_press-40);
            idx_end = min(ts.NframeSide(vid_idx), frame_press+40);
            fig_video = EasyPlot.figure();
            ax_video = EasyPlot.axes(fig_video,...
                'XAxisVisible', 'off',...
                'YAxisVisible', 'off',...
                'YDir', 'reverse',...
                'Width', 10, ...
                'Height', 10);
            img = ReadJpegSEQ2(video_path, idx_start);
            ax_video.Position(3) = size(img, 2)/size(img, 1)*10;
            xlim(ax_video, [0, size(img, 2)]);
            ylim(ax_video, [0, size(img, 1)]);
            im = image(ax_video, img);
            EasyPlot.colormap(ax_video, 'gray');
            EasyPlot.cropFigure(fig_video);
            for i = idx_start:2:idx_end
                im.CData = ReadJpegSEQ2(video_path, i);
                title(ax_video, num2str(i-frame_press));
                pause(0.1);
            end
            close(fig_video);
        end
    end

    disp(['Press ',num2str(press_idx), ' (out of ', num2str(length(b.PressTime)), ' trials): ', num2str(hand)]);
    close all;

    if isnan(hand)
        continue
    end
    
    % save data
    count = count+1;
    outcome_all(count) = outcome;
    press_paw_all(count) = hand;
    press_index_all(count) = press_idx;
    press_time_all(count) = press_time_this;
    FPs_all(count) = b.FPs(press_idx);

    if outcome == -1
        RTs_all(count) = NaN;
    else
        RTs_all(count) = b.ReleaseTime(press_idx)*1000 - b.PressTime(press_idx)*1000 - b.FPs(press_idx);
    end

    if any(RTs_all<0)
        error('RT is less than 0!');
    end

end

press_out.PressIndex = press_index_all';
press_out.PressTime = press_time_all';
press_out.Outcome = outcome_all;
press_out.FPs = FPs_all';
press_out.RTs = RTs_all;
press_out.PressPaw = press_paw_all;

press_out.FlexOnset = NaN(1, length(press_time_all));
press_out.TouchOnset = NaN(1, length(press_time_all));
press_out.ReleaseOnset = NaN(1, length(press_time_all));
press_out.HoldPaw = NaN(1, length(press_time_all));
press_out.ReleasePaw = NaN(1, length(press_time_all));

% save PressOut
PressOut = press_out;

if lesion_index > 0
    save_filename = ['PressOut_', press_out.RatName, '_postIndex_', num2str(abs(lesion_index))];
else
    save_filename = ['PressOut_', press_out.RatName, '_preIndex_', num2str(abs(lesion_index))];
end

save(save_filename, 'PressOut');