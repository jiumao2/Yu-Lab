function plotOmittedReward(r, unit)
t_pre = -1000;
t_post = 1000;
height_per_trial = 0.05;
gaussian_kernel = 50;

idx_press = find(strcmpi(r.Behavior.Labels, 'LeverPress'));
idx_release = find(strcmpi(r.Behavior.Labels, 'LeverRelease'));
idx_reward = find(strcmpi(r.Behavior.Labels, 'ValveOnset'));
idx_sham_reward = find(strcmpi(r.Behavior.Labels, 'ShamValveOnset'));

press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_press);
release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_release);
reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_reward);
if isempty(idx_sham_reward)
    sham_reward_times = [];
else
    sham_reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_sham_reward);
end

n_reward = length(reward_times);
n_sham = length(sham_reward_times);

reward_times_all = [reward_times; sham_reward_times];
reward_times_all = sort(reward_times_all);

spike_times = r.Units.SpikeTimes(unit).timings;

event_times = {reward_times_all, reward_times, sham_reward_times};
x_rasters = cell(1,3);
y_rasters = cell(1,3);
peth_all = cell(1,3);

for i_event = 1:length(event_times)
    event_times_this = event_times{i_event};

    x_plot = [];
    y_plot = [];
    for k = 1:length(event_times_this)
        t_event = event_times_this(k);
        st = spike_times(spike_times > t_event + t_pre & spike_times < t_event + t_post) - t_event;
        for j = 1:length(st)
            x_plot = [x_plot, st(j), st(j), NaN];
            y_plot = [y_plot, k-0.5, k+0.5, NaN];
        end
    end
    
    params.pre = -t_pre;
    params.post = t_post;
    params.binwidth = 1;
    [peth, t_peth] = jpsth(spike_times, event_times_this, params);
    peth = smoothdata(peth, 'gaussian', 5*gaussian_kernel/params.binwidth);

    x_rasters{i_event} = x_plot;
    y_rasters{i_event} = y_plot;
    peth_all{i_event} = peth;
end

fig = EasyPlot.figure();
ax_raster_combined = EasyPlot.axes(fig,...
    'Width', 3,...
    'Height', height_per_trial*(n_reward+n_sham),...
    'MarginBottom', 0.1,...
    'MarginLeft', 1,...
    'XAxisVisible', 'off');

ax_peth = EasyPlot.createAxesAgainstAxes(fig, ax_raster_combined, 'bottom',...
    'Height', 3,...
    'MarginLeft', 1,...
    'MarginBottom', 1,...
    'YGrid', 'on');

ax_peth2 = EasyPlot.createAxesAgainstAxes(fig, ax_peth, 'right',...
    'YAxisVisible', 'off',...
    'YGrid', 'on');
ax_raster_sham = EasyPlot.createAxesAgainstAxes(fig, ax_peth2, 'top',...
    'Height', height_per_trial*n_sham,...
    'XAxisVisible', 'off');
ax_raster_reward = EasyPlot.createAxesAgainstAxes(fig, ax_raster_sham, 'top',...
    'Height', height_per_trial*n_reward,...
    'XAxisVisible', 'off');

ax_rasters = {ax_raster_combined, ax_raster_reward, ax_raster_sham};
colors = lines(3);
for i_event = 1:length(event_times)
    plot(ax_rasters{i_event}, x_rasters{i_event}./1000, y_rasters{i_event}, '-', ...
        'LineWidth', 0.5, ...
        'Color', colors(i_event, :));
    xlim(ax_rasters{i_event}, [t_pre, t_post]./1000);
    ylim(ax_rasters{i_event}, [0.5, length(event_times{i_event})+0.5]);
end
ylabel(ax_rasters{1}, 'Trials');

plot(ax_peth, t_peth./1000, peth_all{1}, '-', 'LineWidth', 1, 'Color', colors(1, :));
plot(ax_peth2, t_peth./1000, peth_all{2}, '-', 'LineWidth', 1, 'Color', colors(2, :));
plot(ax_peth2, t_peth./1000, peth_all{3}, '-', 'LineWidth', 1, 'Color', colors(3, :));

EasyPlot.setXLim({ax_peth, ax_peth2}, [t_pre, t_post]./1000);
EasyPlot.setYLim({ax_peth, ax_peth2});
ylabel(ax_peth, 'Firing rate (Hz)');
xlabel(ax_peth, 'Time from reward (s)');

title(ax_raster_combined, 'Combined');
title(ax_raster_reward, 'Rewarded');
title(ax_raster_sham, 'Sham');

session = datestr(r.Meta(1).DateTime, 'yyyymmdd');
rat_name = r.Meta(1).Subject;

h = EasyPlot.setGeneralTitle({ax_raster_combined, ax_raster_reward},...
    [rat_name, ' ', session, ' Unit', num2str(unit)]);
EasyPlot.move(h, 'dy', 0.5);

EasyPlot.cropFigure(fig);
output_folder = fullfile('./Fig/Reward');
if ~isfolder(output_folder)
    mkdir(output_folder);
end



EasyPlot.exportFigure(fig, fullfile(output_folder,...
    [rat_name, '_', session, '_Unit', num2str(unit)]), 'dpi', 300);

end