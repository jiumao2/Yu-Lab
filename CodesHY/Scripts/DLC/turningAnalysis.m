%%
load RTarrayAll.mat
load timestamps.mat

direction_d_angle_above_zero = 'Right'; % Right turing when angle is increasing

subject = r.Meta(1).Subject;
session = datestr(r.Meta(1).DateTime, 'yyyymmdd');

n_segment = length(r.Meta);
frame_times_top = r.Video.t_frameon_top;
frame_num = arrayfun(@(x)length(x.ts), ts.top);
frame_start = [0, cumsum(frame_num(1:end-1))];

t_frames = [];
angle = [];
turning_angle = [];

% Read data from DLC output
for k = 1:n_segment
    data = readtable(['turning_angle_segment',num2str(k),'.csv']);
    t_frames = [t_frames, frame_times_top(data.frame_number+frame_start(k))]; 
    angle = [angle; data.angle];
    if k == 1
        tracking.frame_number = data.frame_number;
        tracking.x_left_ear = data.x_left_ear;
        tracking.y_left_ear = data.y_left_ear;
        tracking.x_right_ear = data.x_right_ear;
        tracking.y_right_ear = data.y_right_ear;
        tracking.p_left_ear = data.p_left_ear;
        tracking.p_right_ear = data.p_right_ear;
        tracking.p_head = data.p_head;
    else
        tracking.frame_number = [tracking.frame_number; data.frame_number+frame_start(k)];
        tracking.x_left_ear = [tracking.x_left_ear; data.x_left_ear];
        tracking.y_left_ear = [tracking.y_left_ear; data.y_left_ear];
        tracking.x_right_ear = [tracking.x_right_ear; data.x_right_ear];
        tracking.y_right_ear = [tracking.y_right_ear; data.y_right_ear];
        tracking.p_left_ear = [tracking.p_left_ear; data.p_left_ear];
        tracking.p_right_ear = [tracking.p_right_ear; data.p_right_ear];
        tracking.p_head = [tracking.p_head; data.p_head];
    end

    if k>1
        turning_angle = [turning_angle; data.turning_angle+turning_angle(end)];
    else
        turning_angle = [turning_angle; data.turning_angle];
    end
end

tracking.t_frames = t_frames';
tracking.angle = angle;
tracking.turning_angle = turning_angle;

%% press-reward & reward-press turning direction
% read press times and reward times from r
idx_lever_press = find(strcmpi(r.Behavior.Labels, 'LeverPress'));
idx_valve_onset = find(strcmpi(r.Behavior.Labels, 'ValveOnset'));
press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_lever_press);
reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_valve_onset);

% get the angle when the rat is pressing and poking
press_angle = median(angle(findNearestPoint(t_frames, press_times)));
reward_angle = median(angle(findNearestPoint(t_frames, reward_times)));

segment_start_times = zeros(1, length(r.Meta));
segment_end_times = zeros(1, length(r.Meta));
segment_duration = zeros(1,length(r.Meta));
for k = 1:length(r.Meta)
    segment_start_times(k) = get_t_start_session(r,k);
    segment_end_times(k) = get_t_end_session(r,k);
    segment_duration(k) = segment_end_times(k) - segment_start_times(k);
end

% combine press times and reward times
% sort the times to get press-to-poke and poke-to-press
idx = [zeros(1,length(press_times)), ones(1,length(reward_times))]; % 0:press, 1:reward
idx_press = [1:length(press_times), zeros(1,length(reward_times))];
t_press_reward = [press_times; reward_times];

[t_press_reward, sort_idx] = sort(t_press_reward);
idx_press_reward = idx(sort_idx);
idx_press = idx_press(sort_idx);

is_reward_to_press = [];    % note the turning is reward-to-press or press-to-reward
t_direction = [];           % the time of turning
direction = [];             % left or right turn
direction_angle = [];       % the change of angle in this turn
raw_press_idx = [];         % related to the press index
performance = [];           
duration = [];              % the duration of the turning
angle_press_all = [];       % the angle when pressing
angle_reward_all = [];      % the angle when poking

for k = 1:length(t_press_reward)
    if k==1
        % set initial state to be reward or press
        state = idx_press_reward(k);  
    elseif idx_press_reward(k) ~= state... % press-to-reward or reward-to-press
        && all((t_pre>segment_start_times) == (t_press_reward(k)>segment_start_times)) % Not across segments
        is_reward_to_press = [is_reward_to_press, state==1];
        t_direction = [t_direction, (t_pre+t_press_reward(k))/2];
        duration = [duration, t_press_reward(k)-t_pre];

        if state==1
            raw_press_idx = [raw_press_idx, idx_press(k)];
            performance = [performance, get_performance(r,idx_press(k))];
        else
            raw_press_idx = [raw_press_idx, idx_press(k-1)];
            performance = [performance, get_performance(r,idx_press(k-1))];
        end
        
        % Find the closest angles to get the closest angle when pressing
        % or poking from near anaylzed frames

        idx_angle = max(findNearestPoint(t_frames, t_press_reward(k))-1,1):min(findNearestPoint(t_frames, t_press_reward(k))+1,length(t_frames));
        if state==1
            [~, min_idx] = min(abs(sub_angle(angle(idx_angle), press_angle)));
        else
            [~, min_idx] = min(abs(sub_angle(angle(idx_angle), reward_angle)));
        end
        min_idx = idx_angle(min_idx);
        angle_this = angle(min_idx);
        
        % Let the press / reward angle to be the median angle
        if idx_press_reward(k)==0
            angle_press_all = [angle_press_all, angle_this];
            d_angle = sub_angle(press_angle, angle_this);
        else
            angle_reward_all = [angle_reward_all, angle_this];
            d_angle = sub_angle(reward_angle, angle_this);
        end
    
        turning_angle_post = turning_angle(min_idx)+d_angle;

        direction = [direction, turning_angle_post>turning_angle_pre];
        direction_angle = [direction_angle, turning_angle_post-turning_angle_pre];

        state = idx_press_reward(k);
    end
    
    idx_angle = max(findNearestPoint(t_frames, t_press_reward(k))-1,1):min(findNearestPoint(t_frames, t_press_reward(k))+1,length(t_frames));
    if state==0
        [~, min_idx] = min(abs(sub_angle(angle(idx_angle), press_angle)));
    else
        [~, min_idx] = min(abs(sub_angle(angle(idx_angle), reward_angle)));
    end
    min_idx = idx_angle(min_idx);
    angle_this = angle(min_idx);

    if state==0
        angle_press_all = [angle_press_all, angle_this];
        d_angle = sub_angle(press_angle, angle_this);
    else
        angle_reward_all = [angle_reward_all, angle_this];
        d_angle = sub_angle(reward_angle, angle_this);
    end

    turning_angle_pre = turning_angle(min_idx)+d_angle;
    t_pre = t_press_reward(k);
end

direction_segment = cell(1, n_segment);

for k = 1:n_segment
    t0 = segment_start_times(k);
    t1 = segment_end_times(k);

    idx_this = t_direction>t0 & t_direction<t1;
    direction_segment{k} = direction(idx_this);
end

%% Save data
Turning.Tracking = tracking;
Turning.Time = t_direction;
Turning.Direction = direction;
Turning.DirectionAngle = direction_angle;
Turning.Performance = performance;
Turning.PerformanceLabels = {'Correct', 'Premature', 'Late', 'Dark'};
Turning.Duration = duration;
Turning.isPokeToPress = is_reward_to_press;
Turning.RawPressIndex = raw_press_idx;
Turning.DirectionSegment = direction_segment;
if strcmpi(direction_d_angle_above_zero, 'Right')
    Turning.DirectionLabel = 'Right';
else
    Turning.DirectionLabel = 'Left';
end
r.Turning = Turning;
save RTarrayAll.mat r

%%
fig = EasyPlot.figure();
ax_ifi = EasyPlot.axes(fig, ...
    'MarginBottom', 1,...
    'MarginLeft', 1);
ax_angle_press_reward = EasyPlot.createAxesAgainstAxes(fig, ax_ifi, 'right',...
    'MarginLeft', 1,...
    'MarginRight', 2, ...
    'MarginBottom', 1);
ax_traj_pre = EasyPlot.createAxesAgainstAxes(fig, ax_ifi, 'bottom',...
    'MarginLeft', 2,...
    'MarginBottom', 1);
ax_traj_post = EasyPlot.createAxesAgainstAxes(fig, ax_angle_press_reward, 'bottom');

ifi = diff(tracking.frame_number);
ifi(ifi>300) = [];
histogram(ax_ifi, ifi, 'BinWidth', 10);
xline(ax_ifi, 100, 'k-');
xlim(ax_ifi, [0,300]);
xlabel(ax_ifi, 'Inter-frame interval');
ylabel(ax_ifi, 'Counts');

plot(ax_angle_press_reward, angle_press_all, 'b.', 'MarkerSize', 5);
plot(ax_angle_press_reward, angle_reward_all, 'r.', 'MarkerSize', 5);
ylim(ax_angle_press_reward, [-pi, pi]);
lg = EasyPlot.legend(ax_angle_press_reward, {'Press', 'Poke'});
EasyPlot.move(lg, 'dx', 2)
xlabel(ax_angle_press_reward, 'Press / Poke #');
ylabel(ax_angle_press_reward, 'Angle (rad)');

traj = [r.VideoInfos_top.Trajectory];
idx_correct = find(strcmpi({r.VideoInfos_top.Performance},'Correct'));
idx_press_traj = [r.VideoInfos_top(idx_correct).Index];

dir_pre = NaN(1, length(idx_press_traj));
dir_post = NaN(1, length(idx_press_traj));
for k = 1:length(idx_press_traj)
    idx = find(raw_press_idx==idx_press_traj(k));
    if length(idx) ~= 2
        continue
    end
    dir_pre(k) = direction(idx(1));
    dir_post(k) = direction(idx(2));
end


plot(ax_traj_pre, traj+0.5*(rand(size(traj))-0.5), dir_pre+0.5*(rand(size(traj))-0.5), 'b.', 'MarkerSize', 5);
yticks(ax_traj_pre, [0,1]);
plot(ax_traj_post, traj+0.5*(rand(size(traj))-0.5), dir_post+0.5*(rand(size(traj))-0.5), 'b.', 'MarkerSize', 5);
yticks(ax_traj_post, []);
if strcmpi(direction_d_angle_above_zero, 'Right')
    yticklabels(ax_traj_pre, {'Left turn', 'Right turn'});
else
    yticklabels(ax_traj_pre, {'Right turn', 'Left turn'});
end

EasyPlot.setXLim({ax_traj_pre, ax_traj_post}, [0.6, max(traj)+0.4]);
EasyPlot.setYLim({ax_traj_pre, ax_traj_post}, [-0.2, 1.2]);
EasyPlot.setXLabelRow({ax_traj_pre, ax_traj_post}, 'Trajectory #');


% % detect unmatched presses
% idx1 = idx_press_traj(dir_pre == 0 & traj == 1);
% idx2 = idx_press_traj(dir_pre == 1 & traj == 2);
% disp(['Press indexes which are misclassified as traj #1: ', num2str(idx1)]);
% disp(['Press indexes which are misclassified as traj #2: ', num2str(idx2)]);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, ['TurningAnalysisResult_', subject, '_', session]);
%%
fig = EasyPlot.figure();
ax_direction_pre = EasyPlot.axes(fig,...
    'Width', 5,...
    'MarginBottom', 1,...
    'MarginLeft', 1.5);
ax_direction_post = EasyPlot.createAxesAgainstAxes(fig, ax_direction_pre, 'right');
ax_bar = EasyPlot.createAxesAgainstAxes(fig, ax_direction_post, 'right',...
    'Width', 3,...
    'MarginLeft', 1);


window = 60*1000*10; % in minutes
t = 0:1000*60:max(t_direction);
rate_pre = zeros(size(t));
rate_post = zeros(size(t));
CI_pre = zeros(2, length(t));
CI_post = zeros(2, length(t));

for k = 1:length(rate_pre)
    idx_segment = find(segment_start_times>t(k), 1);
    if isempty(idx_segment)
        idx_segment = length(segment_start_times);
    else
        idx_segment = idx_segment-1;
    end

    t0 = max([0, t(k)-window/2, segment_start_times(idx_segment)]);
    t1 = min([t(end), t(k)+window/2, segment_end_times(idx_segment)]);

    idx = find(t_direction>=t0 & t_direction<=t1);

    direction_this = direction(idx);
    is_reward_to_press_this = is_reward_to_press(idx);
    direction_pre = direction_this(is_reward_to_press_this==1);
    direction_post = direction_this(is_reward_to_press_this==0);
    
    if length(direction_pre)<=1
        rate_pre(k) = NaN;
        CI_pre(:, k) = NaN;
    else
        rate_pre(k) = sum(direction_pre==1)/length(direction_pre);
        CI_pre(:, k) = bootci(1000, {@mean, direction_pre==1}, 'Alpha', 0.05);
    end

    if length(direction_post)<=1
        rate_post(k) = NaN;
        CI_post(:, k) = NaN;
    else
        rate_post(k) = sum(direction_post==1)/length(direction_post);
        CI_post(:, k) = bootci(1000, {@mean, direction_post==1}, 'Alpha', 0.05);
    end
end

plot(ax_direction_pre, t_direction(is_reward_to_press==1)/1000/60, direction(is_reward_to_press==1), 'b.', 'MarkerSize', 3);
plot(ax_direction_pre, t/1000/60, rate_pre, 'b-', 'LineWidth', 2);

plot(ax_direction_post, t_direction(is_reward_to_press==0)/1000/60, direction(is_reward_to_press==0), 'b.', 'MarkerSize', 3);
plot(ax_direction_post, t/1000/60, rate_post, 'b-', 'LineWidth', 2);

EasyPlot.setYLim({ax_direction_pre, ax_direction_post}, [-0.2, 1.2]);
EasyPlot.setXLim({ax_direction_pre, ax_direction_post}, [0, max(t_direction)/1000/60]);

yticks(ax_direction_pre, [0,1]);
yticks(ax_direction_post, []);

CI_pre_nan_removed = {};
CI_post_nan_removed = {};
t_pre_nan_removed = {};
t_post_nan_removed = {};

k = 1;
t_pre = t;
while k <= length(t_pre)
    j = find(isnan(CI_pre(1,k:end)), 1);

    if isempty(j)
        j = length(CI_pre(1,k:end)) + 1;
    elseif j <= 2
        k = k+1;
        continue
    end

    CI_pre_nan_removed{end+1} = CI_pre(:, k:k+j-2);
    t_pre_nan_removed{end+1} = t_pre(k:k+j-2);

    k = k+j-1;
end

k = 1;
t_post = t;
while k <= length(t_post)
    j = find(isnan(CI_post(1,k:end)), 1);

    if isempty(j)
        j = length(CI_post(1,k:end)) + 1;
    elseif j <= 2
        k = k+1;
        continue
    end

    CI_post_nan_removed{end+1} = CI_post(:, k:k+j-2);
    t_post_nan_removed{end+1} = t_post(k:k+j-2);

    k = k+j-1;
end

for k = 1:length(CI_pre_nan_removed)
    EasyPlot.plotShaded(ax_direction_pre, t_pre_nan_removed{k}/60/1000, CI_pre_nan_removed{k});
end
for k = 1:length(CI_post_nan_removed)
    EasyPlot.plotShaded(ax_direction_post, t_post_nan_removed{k}/60/1000, CI_post_nan_removed{k});
end

ax_all{1} = ax_direction_pre;
for k = 1:length(r.Meta)-1
    [ax_all{k}, ax_all{k+1}] = EasyPlot.truncAxis(ax_all{k},...
        "X", [segment_end_times(k)/1000/60, segment_start_times(k+1)/1000/60],...
        'Xratio', segment_duration(k)./sum(segment_duration(k+1:end)),...
        'truncRatio', 0.2/ax_all{k}.Position(3));
end
EasyPlot.setGeneralTitle(ax_all, 'Poke to press');

ax_all{1} = ax_direction_post;
for k = 1:length(r.Meta)-1
    [ax_all{k}, ax_all{k+1}] = EasyPlot.truncAxis(ax_all{k},...
        "X", [segment_end_times(k)/1000/60, segment_start_times(k+1)/1000/60],...
        'Xratio', segment_duration(k)./sum(segment_duration(k+1:end)),...
        'truncRatio', 0.2/ax_all{k}.Position(3));
end
EasyPlot.setGeneralTitle(ax_all, 'Press to poke');

if strcmpi(direction_d_angle_above_zero, 'Right')
    yticklabels(ax_direction_pre, {'Left turn', 'Right turn'});
else
    yticklabels(ax_direction_pre, {'Right turn', 'Left turn'});
end

x = 1:n_segment;
y = zeros(1,n_segment);
CI = zeros(2, n_segment);
for k = 1:n_segment
    if strcmpi(direction_d_angle_above_zero, 'Right')
        y(k) = sum(direction_segment{k}==0)./length(direction_segment{k});
        CI(:, k) = bootci(1000, @mean, direction_segment{k}==0);
    else
        y(k) = sum(direction_segment{k}==1)./length(direction_segment{k});
        CI(:, k) = bootci(1000, @mean, direction_segment{k}==1);
    end
end
bar(ax_bar, y);
xticks(ax_bar, 1:length(y));
xlabel(ax_bar, 'Segment #');
ylabel(ax_bar, 'Left turn rate');
title(ax_bar, [subject, ' ', session]);
errorbar(ax_bar, 1:length(y), y,...
        CI(1,:)-y,... % yneg
        CI(2,:)-y,... % ypos
        'k.',...
        'MarkerSize', 1e-8,...
        'LineWidth', 1);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, ['TurningStatistics_', subject, '_', session]);

%%
% t0 = reward_times(84);
% t_pre = 6000;
% t_post = 10000;
% idx_frame = findNearestPoint(r.Video.t_frameon_top, t0);
% idx_seqfile = find(frame_start>idx_frame, 1);
% video_dir = 'F:\Fountain\Videos\20230920';
% if isempty(idx_seqfile)
%     idx_seqfile = length(frame_start);
% else
%     idx_seqfile = idx_seqfile-1;
% end
% seqfile = ts.topviews{idx_seqfile};
% frame_range = find(r.Video.t_frameon_top>t0-t_pre & r.Video.t_frameon_top<t0+t_post)-frame_start(idx_seqfile);
% 
% vid_out = VideoWriter('VideoOut.avi');
% vid_out.open();
% for k = 1:5:length(frame_range)
%     img = ReadJpegSEQ2(fullfile(video_dir, seqfile), frame_range(k));
%     img = insertText(img, [20,20], ['Angle: ',num2str(angle(findNearestPoint(t_frames, frame_times_top(frame_start(idx_seqfile)+frame_range(k)))))]);
%     
%     [x_left, y_left, x_right, y_right, p_head] = get_ear_location(tracking, frame_range(k)+frame_start(idx_seqfile));
%     if ~isnan(x_left)
%         img = insertMarker(img, [x_left, y_left], 'circle', 'Size', 5, 'Color', 'blue');
%         img = insertMarker(img, [x_right, y_right], 'circle', 'Size', 5, 'Color', 'red');
%         img = insertText(img, [20,50], ['p: ',num2str(p_head)]);
%     end
%     
%     vid_out.writeVideo(img);
% end
% vid_out.close();

function out = sub_angle(x,y)
    out = x-y;
    out(out<=-pi) = out(out<=-pi)+2*pi;
    out(out>pi) = out(out>pi)-2*pi;
end

function out = get_performance(r, idx_press)
% 1:correct; 2:premature; 3:late; 4:dark
    if any(r.Behavior.CorrectIndex==idx_press)
        out = 1;
    elseif any(r.Behavior.PrematureIndex==idx_press)
        out = 2;
    elseif any(r.Behavior.LateIndex==idx_press)
        out = 3;
    elseif any(r.Behavior.DarkIndex==idx_press)
        out = 4;
    else
        error('Performance not found!');
    end
end

function [x_left, y_left, x_right, y_right, p_head] = get_ear_location(tracking, idx_frame)
    x_left = NaN; y_left = NaN; x_right = NaN; y_right = NaN;
    idx = findNearestPoint(tracking.frame_number, idx_frame);
    if isempty(idx)
        return
    end
    x_left = tracking.x_left_ear(idx);
    y_left = tracking.y_left_ear(idx);
    x_right = tracking.x_right_ear(idx);
    y_right = tracking.y_right_ear(idx);
    p_head = tracking.p_head(idx);
end
