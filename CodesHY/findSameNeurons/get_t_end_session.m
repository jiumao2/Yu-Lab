function t = get_t_end_session(r, k)
    t = get_t_start_session(r,k)+r.Meta(k).DataDuration/30;

%     spike_time_all = sort([r.Units.SpikeTimes.timings]);
%     if k == length(r.Meta)
%         t = spike_time_all(end);
%         return
%     end
% 
%     t_start_next_session = get_t_start_session(r, k+1);
%     idx_seg = diff(spike_time_all)>10000; % two sessions must have an interval longer than 10 sec
%     t_seg = spike_time_all(idx_seg);
%     t_seg(t_seg>t_start_next_session) = [];
%     t = t_seg(end);  % in ms
end