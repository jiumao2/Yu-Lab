function [data_warped, t_warped, t_median] = computeWarpedData(...
    data, data_times, event_times, t_pre, t_post, binwidth, t_median)
% data: n_trial x n_timepoints array
% data_times: 1 x n_timepoints array
% event_times: n_trail x n_event array

if nargin < 6
    binwidth = 1;
end
if nargin < 7
    t_median = [];
end

n_trial = size(event_times, 1);
if isempty(t_median)
    t_median = median(event_times - event_times(:,1));
end

t_warped = t_pre:binwidth:t_median(end)+t_post;
t_unwarped = data_times;


data_warped = NaN(n_trial, length(t_warped));
for k = 1:n_trial
    event_time_this = event_times(k, :);

    t_points_to_warp = event_time_this - event_time_this(1);
    t_unwarped_this = t_unwarped - event_time_this(1);

    t_dest = t_median;
    t_new = t_unwarped_this;
    for j = 2:length(t_points_to_warp)
        idx0 = findNearestPoint(t_unwarped_this, t_points_to_warp(j-1));
        idx1 = findNearestPoint(t_unwarped_this, t_points_to_warp(j));
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
    
    for j = 1:length(t_warped)
        i = find(t_new >= t_warped(j), 1);
        if t_new(i) == t_warped(j)
            data_warped(k,j) = data(k,i);
        elseif t_new(i) > t_warped(j)
            data_warped(k,j) = interp1(...
                [t_new(i-1), t_new(i)],...
                [data(k,i-1), data(k,i)],...
                t_warped(j));
        end
    end
end
assert(all(~isnan(data_warped(:))));

end





