function plotSpikesDCZ(r, unit_num, dose, varargin)

drugSegment = 2; % the recording segment after injection
recoverySegment = length(r.Meta); % set to [] if none

% parameters for plot PETHs
t_pre_press = -2500;
t_pre_release = -500;
t_pre_reward = -1000;
t_post_press = 2000;
t_post_release = 1000;
t_post_reward = 10000;

ax_width = 1/1000;
ax_height = 3/50;

rat_name = r.Meta(1).Subject;
session = datestr(r.Meta(1).DateTime, 'yyyymmdd');
ch = r.Units.SpikeNotes(unit_num, 1);
save_filename = fullfile('./Fig', [rat_name, '_', session, '_', 'Unit', num2str(unit_num)]);

if nargin > 3
    for k = 1:2:size(varargin, 2)
        if strcmpi(varargin{k}, 'drugSegment')
            drugSegment = varargin{k+1};
        elseif strcmpi(varargin{k}, 'recoverySegment')
            recoverySegment = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_pre_press')
            t_pre_press = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_post_press')
            t_post_press = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_pre_release')
            t_pre_release = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_post_release')
            t_post_release = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_pre_reward')
            t_pre_reward = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_post_reward')
            t_post_reward = varargin{k+1};
        elseif strcmpi(varargin{k}, 'ax_width')
            ax_width = varargin{k+1};
        elseif strcmpi(varargin{k}, 'ax_height')
            ax_height = varargin{k+1};
        elseif strcmpi(varargin{k}, 'save_filename')
            save_filename = varargin{k+1};
        else
            error('wrong argument!');
        end
    end
end


t_pre_post = [t_pre_press, t_pre_release, t_pre_reward;...
    t_post_press, t_post_release, t_post_reward];

fig = EasyPlot.figure();
ax_waveform = EasyPlot.axes(fig, ...
    'Width', 3,...
    'Height', 3,...
    'MarginLeft', 1,...
    'MarginRight', 1,...
    'MarginBottom', 1,...
    'XAxisVisible', 'off',...
    'YAxisVisible', 'off');

ax_autocorrelogram = EasyPlot.createAxesAgainstAxes(fig, ax_waveform, 'right',...
    'YAxisVisible', 'off');

ax_firing_rate = EasyPlot.createAxesAgainstAxes(fig, ax_autocorrelogram, 'right',...
    'MarginLeft', 1.5);

ax_raster_pre_press = EasyPlot.createAxesAgainstAxes(fig, ax_waveform, 'bottom',...
    'Width', (t_post_press-t_pre_press)*ax_width,...
    'XAxisVisible', 'off',...
    'YDir','reverse',...
    'MarginTop', 0.5);

ax_raster_pre_release = EasyPlot.createAxesAgainstAxes(fig, ax_raster_pre_press, "right",...
    "Width",(t_post_release-t_pre_release)*ax_width,...
    "XAxisVisible","off",...
    "YAxisVisible","off",...
    'YDir','reverse');

ax_raster_pre_reward = EasyPlot.createAxesAgainstAxes(fig, ax_raster_pre_release, "right",...
    "Width",(t_post_reward-t_pre_reward)*ax_width,...
    "XAxisVisible","off",...
    "YAxisVisible","off",...
    'YDir','reverse');

ax_raster_pre = {ax_raster_pre_press, ax_raster_pre_release, ax_raster_pre_reward};
ax_raster_post = EasyPlot.copyAxes(ax_raster_pre, 'bottom');
EasyPlot.set(ax_raster_post, 'XAxisVisible', 'off','YDir','reverse');
EasyPlot.set(ax_raster_post(2:3), 'YAxisVisible', 'off','YDir','reverse');

if ~isempty(recoverySegment)
    ax_raster_recovery = EasyPlot.copyAxes(ax_raster_post, 'bottom');
    EasyPlot.set(ax_raster_recovery, 'XAxisVisible', 'off','YDir','reverse');
    EasyPlot.set(ax_raster_recovery(2:3), 'YAxisVisible', 'off','YDir','reverse');
    
    ax_raster_all = {ax_raster_pre, ax_raster_post, ax_raster_recovery};
else
    ax_raster_all = {ax_raster_pre, ax_raster_post};
end

ax_PETH = EasyPlot.copyAxes(ax_raster_all{end}, 'bottom');
EasyPlot.set(ax_PETH, 'MarginBottom', 1,'YDir','normal');
EasyPlot.set(ax_PETH(2:3), 'YAxisVisible', 'off','YDir','normal');

EasyPlot.move({ax_waveform, ax_autocorrelogram, ax_firing_rate}, 'dx', 4);
ax_firing_rate.Position(3) = ax_raster_pre{3}.Position(1)+ax_raster_pre{3}.Position(3)-ax_firing_rate.Position(1);

% waveform
waveform_mean = mean(r.Units.SpikeTimes(unit_num).wave, 1)./4;
waveform_mean = waveform_mean-mean(waveform_mean(1:10));
plot(ax_waveform, waveform_mean, 'k-', 'LineWidth', 2);
xlim(ax_waveform, [0, length(waveform_mean)]);

h_scalebar = EasyPlot.scalebar(ax_waveform, 'XY',...
    'location', 'southwest',...
    'xBarLabel', '0.5 ms',...
    'xBarLength', 0.5*30,...
    'xBarRatio', 1,...
    'yBarLabel', '50 \muV',...
    'yBarLength', 50,...
    'yBarRatio', 1);

% autocorrelogram
spike_times = r.Units.SpikeTimes(unit_num).timings;
binwidth = 1; % ms
window = 50;

spike_counts = round(spike_times-spike_times(1))+1;
s = zeros(max(spike_counts),1);
s(spike_counts) = 1;

[auto_cor, lag] = xcorr(s,s,round(window/binwidth));
auto_cor(lag==0)=0; 

bar(ax_autocorrelogram, lag, auto_cor);
xlabel(ax_autocorrelogram, 'lag (ms)');

title(ax_waveform, 'Waveform');
title(ax_autocorrelogram, 'Autocorrelogram');

% firing rate vs time
gaussian_kernal = 60; % sec

t_end_control_session = get_t_end_session(r, drugSegment-1);  % in ms
t_start_drug_session = get_t_start_session(r, drugSegment);  % in ms
if isempty(recoverySegment)
    t_end_drug_session = get_t_end_session(r, length(r.Meta));
    t_start_segment_all = [0, t_start_drug_session];
    t_end_segment_all = [t_end_control_session, t_end_drug_session];
else
    t_end_drug_session = get_t_end_session(r, recoverySegment-1);
    t_start_segment_all = [0, t_start_drug_session, get_t_start_session(r, recoverySegment)];
    t_end_segment_all = [t_end_control_session, t_end_drug_session, get_t_end_session(r, length(r.Meta))];
end

drugTime = 0.5*(t_end_control_session+t_start_drug_session);
postTime = get_t_start_session(r, recoverySegment);

binwidth = 100;
spike_times = r.Units.SpikeTimes(unit_num).timings;

for k = 1:length(r.Meta)
    t_start = get_t_start_session(r,k);
    t_end = get_t_end_session(r,k);
    spike_times_this = spike_times(spike_times>t_start & spike_times<t_end);

    [spike_counts, t_spike_counts] = bin_timings(spike_times_this, binwidth,...
        'StartFromZero', 'off',...
        't_edges', t_start:binwidth:t_end);
    firing_rate = smoothdata(spike_counts, 'gaussian', gaussian_kernal*1000/binwidth*5)./binwidth*1000;

    t_plot = (t_spike_counts-drugTime)/1000/60;

    plot(ax_firing_rate, t_plot, firing_rate, 'k-', 'LineWidth',2);
end

xlim(ax_firing_rate, ([t_start_segment_all(1), t_end_segment_all(end)]-drugTime)/1000/60);

if ~isempty(recoverySegment)
    [ax_firing_rate1, ax_firing_rate2] = EasyPlot.truncAxis(ax_firing_rate, 'X', ([t_end_drug_session, postTime]-drugTime)./1000./60);
    xlim(ax_firing_rate1, ([t_start_segment_all(1), t_end_drug_session]-drugTime)/1000/60);
    xlim(ax_firing_rate2, ([postTime, t_end_segment_all(end)]-drugTime)/1000/60);
    ax_firing_rate_all = {ax_firing_rate1, ax_firing_rate2};
else
    ax_firing_rate_all = ax_firing_rate;
end

EasyPlot.setGeneralXLabel(ax_firing_rate_all, 'Time from injection (min)');

ylabel(ax_firing_rate, 'Firing rate (Hz)');

% raster and PETH
gaussian_kernal_peth = 25;

% min_trial_number = min([length(raster_all{unit_num}{1,1}), length(raster_all{unit_num}{2,1}), length(raster_all{unit_num}{3,1})]);
idx_press = find(strcmpi(r.Behavior.Labels, 'LeverPress'));
idx_release = find(strcmpi(r.Behavior.Labels, 'LeverRelease'));
idx_reward = find(strcmpi(r.Behavior.Labels, 'ValveOnset'));

press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_press);
release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_release);
reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_reward);
FPs = r.Behavior.Foreperiods;

if any([length(FPs), length(release_times)] ~= length(press_times))
    error('Press number does not match!');
end

idx_correct = r.Behavior.CorrectIndex;
idx_correct = idx_correct(idx_correct<length(press_times));

% only include FP = 1500 ms trials with reward
event_times = []; % press, release, reward pairs of size n_trial x 4
for j = 1:length(press_times)
    if ~any(idx_correct==j)
        continue
    end

    if FPs(j) ~= 1500
        continue
    end

    release_time_this = release_times(j);
    idx_reward_this = find(reward_times>release_time_this, 1);
    if isempty(idx_reward_this)
        continue
    end

    reward_time_this = reward_times(idx_reward_this);
    if j~=length(press_times) && reward_time_this >= press_times(j+1)
        % reward time is after the next press
        continue
    end

    event_times = [event_times; press_times(j), release_time_this, reward_time_this];
end


colors = colororder;
release_col = 'g';

% rng(1);
n_trials = zeros(1, length(t_start_segment_all));
for k = 1:length(t_start_segment_all)
    for j = 1:size(event_times, 2)
        x_plot = [];
        y_plot = [];

        idx_included = find(min(event_times, [], 2) > t_start_segment_all(k)...
            & max(event_times, [], 2) < t_end_segment_all(k));
        n_trials(k) = length(idx_included);

        event_times_this = event_times(idx_included, :);
        for i = 1:size(event_times_this, 1)
            t_event = event_times_this(i,j);
            st = spike_times(spike_times>t_event+t_pre_post(1,j)...
                & spike_times<t_event+t_pre_post(2,j)) - t_event;
            for ii = 1:length(st)
                x_plot = [x_plot, st(ii), st(ii), NaN];
                y_plot = [y_plot, i-0.5, i+0.5, NaN];
            end
        end

        % raster
        plot(ax_raster_all{k}{j}, x_plot./1000, y_plot, '-', 'LineWidth', 1, 'Color', colors(k,:));
        xlim(ax_raster_all{k}{j}, t_pre_post(:,j)./1000);
        ylim(ax_raster_all{k}{j}, [0.5, length(idx_included)+0.5]);

        % PETH
        params.pre = -t_pre_post(1,j);
        params.post = t_pre_post(2,j);
        params.binwidth = 1;
        [peth, t_peth] = jpsth(spike_times, event_times_this(:,j), params);
        peth = smoothdata(peth, 'gaussian', gaussian_kernal_peth/params.binwidth*5);

        plot(ax_PETH{j}, t_peth./1000, peth, '-', 'Color', colors(k,:), 'LineWidth', 2);
        xlim(ax_PETH{j}, t_pre_post(:,j)./1000);

    end

    xline(ax_raster_all{k}{1}, 0, 'k:', 'LineWidth', 2);
    xline(ax_raster_all{k}{1}, 1.5, 'm:', 'LineWidth', 2);
    xline(ax_raster_all{k}{2}, 0, 'k:', 'LineWidth', 2);
    xline(ax_raster_all{k}{3}, 0, 'k:', 'LineWidth', 2);
end

xline(ax_PETH{1}, 0, 'k:', 'LineWidth', 2);
xline(ax_PETH{1}, 1.5, 'm:', 'LineWidth', 2);
xline(ax_PETH{2}, 0, 'k:', 'LineWidth', 2);
xline(ax_PETH{3}, 0, 'k:', 'LineWidth', 2);

xlabel(ax_PETH{1}, 'Time from press (s)');
xlabel(ax_PETH{2}, 'Time from release (s)');
xlabel(ax_PETH{3}, 'Time from reward (s)');
ylabel(ax_PETH{1}, 'Firing rate (Hz)');
ylabel(ax_raster_all{end}{1}, 'Trials');

EasyPlot.setYLim(ax_PETH);

% adjust the height of rasters
dy = 0;
for k = 1:length(t_start_segment_all)
    height_raw = ax_raster_all{k}{1}.Position(4);
    height_new = ax_height*n_trials(k);
    EasyPlot.set(ax_raster_all{k}, 'Height', height_new);
    EasyPlot.move(ax_raster_all{k}, 'dy', dy + height_raw-height_new);

    dy = dy + height_raw-height_new;
end
EasyPlot.move(ax_PETH, 'dy', dy);

% set title
EasyPlot.setGeneralTitle(ax_raster_pre, 'Pre-injection', 'yShift', -0.2);
EasyPlot.setGeneralTitle(ax_raster_post, 'Post-injection', 'yShift', -0.2);

if ~isempty(recoverySegment)
    EasyPlot.setGeneralTitle(ax_raster_recovery, [num2str((postTime-drugTime)/1000/60/60, '%.1f'), ' hour after injection'], 'yShift', -0.2);
end


EasyPlot.markAxes(fig, ax_waveform, rat_name, 'fontSize', 12,...
    'xShift', 0, 'yShift', -0.5,...
    'Width', 4);
EasyPlot.markAxes(fig, ax_waveform, session, 'fontSize', 12,...
    'xShift', 0, 'yShift', -1.3,...
    'Width', 4);
EasyPlot.markAxes(fig, ax_waveform, ['Unit ' num2str(unit_num), ' (Ch ', num2str(ch), ')'] , 'fontSize', 12,...
    'xShift', 0, 'yShift', -2.1,...
    'Width', 4);
EasyPlot.markAxes(fig, ax_waveform, ['DCZ ' getFractionString(dose), 'x'] , 'fontSize', 12,...
    'xShift', 0, 'yShift', -2.9,...
    'Width', 4);

EasyPlot.cropFigure(fig);

EasyPlot.exportFigure(fig, save_filename);
end
