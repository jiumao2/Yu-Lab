function [x_plot, y_plot] = rasterize(spikeTimes, height)
% spikeTimes: 1xn double array or 1xn_trial cell array
% height: the height of each bar

if nargin<2
    height = 1;
end

if iscell(spikeTimes)
    x_plot = [];
    y_plot = [];
    for k = 1:length(spikeTimes)
        [x_this, y_this] = rasterize(spikeTimes{k}, height);
        x_plot = [x_plot, x_this];
        y_plot = [y_plot, y_this+k-1];
    end
    return
end

x_plot = NaN(1,3*length(spikeTimes));
y_plot = NaN(1,3*length(spikeTimes));

x_plot(1:3:end) = spikeTimes;
x_plot(2:3:end) = spikeTimes;

y_plot(1:3:end) = ones(1, length(spikeTimes)) - height/2;
y_plot(2:3:end) = ones(1, length(spikeTimes)) + height/2;

end