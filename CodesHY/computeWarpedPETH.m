function [peth, t_peth, t_median, spike_counts_warped, ci] = computeWarpedPETH(...
    spike_times, event_times, t_pre, t_post, gaussian_kernel, binwidth, n_boot)
% spike_times: n_neuron x 1 cell, each element is an n x 1 double array
% event_times: n_trial x n_event double
if ~iscell(spike_times)
    spike_times = {spike_times};
end

if nargin < 5
    gaussian_kernel = 50;
end
if nargin < 6
    binwidth = 1;
end
if nargin < 7
    n_boot = 1000;
end

n_trial = size(event_times, 1);
n_event = size(event_times, 2);
n_neurons = length(spike_times);
t_median = median(event_times - event_times(:,1));

t_warped = t_pre:binwidth:t_median(end)+t_post;
t_post_border = ceil(t_median(end));
t_unwarped = t_pre:binwidth:t_median(end)+t_post+t_post_border;
t_edges_unwarped = [t_unwarped-binwidth./2, t_unwarped(end)+binwidth./2];

spike_counts = NaN(n_neurons, n_trial, length(t_unwarped));
for k = 1:n_trial
    for j = 1:n_neurons
        spike_counts(j,k,:) = bin_timings(spike_times{j}, binwidth,...
                't_edges', t_edges_unwarped + event_times(k,1));
    end
end
assert(all(~isnan(spike_counts(:))));

spike_counts_warped = NaN(n_neurons, n_trial, length(t_warped));
for k = 1:n_trial
    event_time_this = event_times(k, :);

    t_points_to_warp = event_time_this - event_time_this(1);
    t_dest = t_median;
    t_new = t_unwarped;
    for j = 2:length(t_points_to_warp)
        idx0 = findNearestPoint(t_unwarped, t_points_to_warp(j-1));
        idx1 = findNearestPoint(t_unwarped, t_points_to_warp(j));
        t_new(idx1) = t_dest(j);
        if idx0 == idx1
            idx1 = idx0+1;
        end
        t_new(idx0+1:idx1-1) = interp1([idx0, idx1], [t_dest(j-1), t_dest(j)], idx0+1:idx1-1);
        if j == length(t_points_to_warp)
            t_new(idx1+1:end) = t_new(idx1+1:end) - t_new(idx1+1) + t_new(idx1) + binwidth;
        end
    end
    if t_new(end) < t_post
        error('t_new is too short!');
    end
    
    for i_unit = 1:n_neurons
        spike_counts_warped_this = zeros(1, length(t_warped));
        for j = 1:length(spike_counts_warped_this)
            i = find(t_new >= t_warped(j), 1);
            if t_new(i) == t_warped(j)
                spike_counts_warped_this(j) = spike_counts(i_unit,k,i);
            elseif t_new(i) > t_warped(j)
                spike_counts_warped_this(j) = interp1(...
                    [t_new(i-1), t_new(i)],...
                    [spike_counts(i_unit,k,i-1), spike_counts(i_unit,k,i)],...
                    t_warped(j));
            end
        end
    
        spike_counts_warped(i_unit, k, :) = spike_counts_warped_this;
    end
end
assert(all(~isnan(spike_counts_warped(:))));

peth = zeros(n_neurons, length(t_warped));
for k = 1:n_neurons
    peth(k,:) = smoothdata(mean(squeeze(spike_counts_warped(k,:,:)))*1000./binwidth, 'gaussian', gaussian_kernel./binwidth*5);
end
t_peth = t_warped;

if nargout >= 4
    ci = cell(1, n_neurons);
    for k = 1:n_neurons
        ci{k} = bootci(n_boot,...
            @(x)smoothdata(mean(squeeze(x))*1000./binwidth, 'gaussian', gaussian_kernel./binwidth*5),...
            squeeze(spike_counts_warped(k,:,:)));
    end
end

end
