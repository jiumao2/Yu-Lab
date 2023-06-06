function t_out = align_times(t, map)
% t: 1xn double. Sorted times.
% map: 2xn double. First row is the timeline aligning to. Second row is the
% corresponding old time
map(1,:) = sort(map(1,:));
map(2,:) = sort(map(2,:));

t_out = zeros(size(t));
idx_map = 1;
scale_factor = 1;
for k = 1:length(t)
    if idx_map<size(map,2) && t(k) >= map(2,idx_map+1)
        idx_map = idx_map+1;
    end

    if (idx_map==1 && t(k)<map(2,idx_map)) || idx_map==size(map,2)
        scale_factor = 1;
    else
        scale_factor = (map(1,idx_map+1)-map(1,idx_map))/(map(2,idx_map+1)-map(2,idx_map));
    end

    if t(k)<map(2,idx_map) && idx_map==1
        t_out(k) = t(k)-(map(2,1)-map(1,1));
    else
        t_out(k) = map(2,idx_map) + scale_factor*(t(k)-map(2,idx_map))-(map(2,idx_map)-map(1,idx_map));
    end
end
end
