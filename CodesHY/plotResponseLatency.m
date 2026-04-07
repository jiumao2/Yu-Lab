function fig = plotResponseLatency(spike_times, event_times, latency, ...
    response_type, t_pre, t_post, binwidth)
% plotResponseLatency Visualize event-aligned neural responses and latency estimate.
%
%   plotResponseLatency(spike_times, event_times, latency)
%   plotResponseLatency(spike_times, event_times, latency, t_pre, t_post, binwidth)
%
%   Inputs:
%   spike_times : vector of spike timestamps in ms.
%   event_times : vector of event / stimulus timestamps in ms.
%   latency     : estimated response latency in ms, relative to event onset.
%   t_pre       : start time of plotting window in ms. Default: -200.
%   t_post      : end time of plotting window in ms. Default: 500.
%   binwidth    : PETH bin width in ms. Default: 10.
%
%   Description:
%   This function plots a trial-by-trial raster and an unsmoothed PETH
%   aligned to the provided event times. The estimated latency is marked on
%   both panels so the user can visually assess whether the latency matches
%   the apparent neural response onset.
%
%   Notes:
%   - All time variables are assumed to be in ms.
%   - The PETH is not smoothed.
%   - Inputs are assumed to be valid.

if nargin < 4
    response_type = '';
end
if nargin < 5 || isempty(t_pre)
    t_pre = -200;
end
if nargin < 6 || isempty(t_post)
    t_post = 500;
end
if nargin < 7 || isempty(binwidth)
    binwidth = 10;
end

window = [t_pre, t_post];
n_trials = numel(event_times);

edges = window(1):binwidth:window(2);
if edges(end) < window(2)
    edges(end+1) = window(2);
end
bin_widths = diff(edges);
bin_centers = edges(1:end-1) + bin_widths / 2;

x_raster = [];
y_raster = [];
spikes_rel_all = [];

for i = 1:n_trials
    t0 = event_times(i);
    spikes_rel = spike_times( ...
        spike_times >= (t0 + window(1)) & ...
        spike_times <= (t0 + window(2))) - t0;

    spikes_rel_all = [spikes_rel_all; spikes_rel(:)];

    for j = 1:numel(spikes_rel)
        x_raster = [x_raster, spikes_rel(j), spikes_rel(j), NaN];
        y_raster = [y_raster, i - 0.45, i + 0.45, NaN];
    end
end

counts = histcounts(spikes_rel_all, edges);
peth_hz = counts ./ (n_trials .* (bin_widths / 1000));

fig = EasyPlot.figure();
ax = EasyPlot.createGridAxes(fig, 2, 1, ...
    'Width', 5, ...
    'Height', 2.5, ...
    'MarginLeft', 0.9, ...
    'MarginRight', 0.25, ...
    'MarginTop', 0.2, ...
    'MarginBottom', 0.2);

EasyPlot.set(ax(1), 'Height', 2.5);
EasyPlot.set(ax(2), 'Height', 2.5, 'MarginBottom', 0.9);

ax_raster = ax{1};
ax_peth = ax{2};

% raster
plot(ax_raster, x_raster, y_raster, 'k-', 'LineWidth', 0.75);
xline(ax_raster, 0, ':', 'Color', [0.2 0.4 0.8], 'LineWidth', 1.2);
if ~isnan(latency)
    xline(ax_raster, latency, '--', 'Color', [0.85 0.2 0.2], 'LineWidth', 1.5);
end

% peth
bar(ax_peth, bin_centers, peth_hz, 1, ...
    'FaceColor', [0.15 0.15 0.15], ...
    'EdgeColor', 'none');
xline(ax_peth, 0, ':', ...
    'Color', [0.2 0.4 0.8], ...
    'LineWidth', 1.2, ...
    'LabelOrientation', 'horizontal');

if ~isnan(latency)
    xline(ax_peth, latency, '--', ...
        'Color', [0.85 0.2 0.2], ...
        'LineWidth', 1.5, ...
        'LabelOrientation', 'horizontal');
end

EasyPlot.setXLim(ax, window);
ylim(ax_raster, [0.5, n_trials + 0.5]);

set(ax_raster, 'XTickLabel', []);

ylabel(ax_raster, 'Trial');
ylabel(ax_peth, 'Firing rate (Hz)');
xlabel(ax_peth, 'Time from event (ms)');

if isempty(response_type)
    title(ax_raster, sprintf('Latency = %.0f ms', latency));
else
    title(ax_raster, sprintf('Latency = %.0f ms | %s', latency, response_type));
end

EasyPlot.cropFigure(fig);

end
