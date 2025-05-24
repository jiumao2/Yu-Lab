function plotWaveform(waveforms, channel_locations, n_channels)
% waveforms: n_channel x n_sample matrix
% channel_locations: n_channel x 2 matrix
% n_channels: number of channels nearest the peak channel

if nargin < 3
    n_channels = 20;
end

sample_scale = 1;
x_scale = 3;
y_scale = 1;
waveform_scale = 0.2;
figure_width = 1;
figure_height = 5;

ptt = max(waveforms, [], 2) - min(waveforms, [], 2);
[~, idx_max] = max(ptt);
distance_to_peak_channel = sqrt(sum((channel_locations - channel_locations(idx_max,:)).^2, 2));
[~, idx_sort] = sort(distance_to_peak_channel);
idx_included = idx_sort(1:n_channels);

waveforms_plot = waveforms(idx_included, :);

% Pack data for plotting
x_plot = [];
y_plot = [];
x_plot_ch = [];
y_plot_ch = [];

samples_plot = (1:size(waveforms, 2)) - (size(waveforms, 2)+1)/2;
max_sample = max(samples_plot);

for k = 1:n_channels
    x = channel_locations(idx_included(k), 1);
    y = channel_locations(idx_included(k), 2);

    x_plot = [x_plot, x*x_scale+samples_plot*sample_scale, NaN];
    y_plot = [y_plot, y*y_scale+waveforms_plot(k,:)*waveform_scale, NaN];
end

fig = EasyPlot.figure('Visible', 'on');

ax = EasyPlot.axes(fig,...
    'Width', figure_width,...
    'Height', figure_height,...
    'fontSize', 7,...
    'Box', 'on',...
    'MarginBottom', 1,...
    'MarginLeft', 1);

x_range = [min(x_plot) - 15, max(x_plot) + 15];
y_range = [min(y_plot) - 20, max(y_plot) + 20];
x_this = max_sample;

% Make patches representing channel sites.  
for k = 1:n_channels
    x = channel_locations(idx_included(k), 1);
    y = channel_locations(idx_included(k), 2);
    y_this = x_this/diff(x_range)*ax.Position(3)*diff(y_range)/ax.Position(4);
    x_plot_ch = [x_plot_ch, [x*x_scale - sample_scale*x_this; x*x_scale - sample_scale*x_this;...
        x*x_scale + sample_scale*x_this; x*x_scale + sample_scale*x_this]];
    y_plot_ch = [y_plot_ch, [y*y_scale - sample_scale*y_this; y*y_scale + sample_scale*y_this;...
        y*y_scale + sample_scale*y_this; y*y_scale - sample_scale*y_this]];
end

% plot the channels
patch(ax, x_plot_ch, y_plot_ch, [.8 .8 .8], 'FaceAlpha', 0.8, 'EdgeColor', 'none');

% plot the waveforms
plot(ax, x_plot, y_plot, 'k-');

EasyPlot.setXLim(ax, x_range);
EasyPlot.setYLim(ax, y_range);

h_scalebar = EasyPlot.scalebar(ax, 'XY',...
    'location', 'southeast',...
    'xBarLabel', '2 ms',...
    'xBarLength', 2*30*sample_scale,...
    'xBarRatio', 1,...
    'yBarLabel', '0.1 mV',...
    'yBarLength', 100*waveform_scale,...
    'yBarRatio', 1,...
    'fontSize', 7,...
    'lineWidth', 1);
EasyPlot.move(h_scalebar, 'dx', 0.8, 'dy', 0);

EasyPlot.cropFigure(fig);

end