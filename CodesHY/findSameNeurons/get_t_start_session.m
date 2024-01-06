function t = get_t_start_session(r, i_segments)
    t = zeros(size(i_segments));
    for k = 1:length(i_segments)
        dt = r.Meta(i_segments(k)).DateTimeRaw - r.Meta(1).DateTimeRaw;
        t(k) = dt(end)+dt(end-1)*1000+dt(end-2)*1000*60+dt(end-3)*1000*60*60; % ms
    end
end