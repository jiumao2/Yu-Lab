function t = get_t_start_session(r, k)
    dt = r.Meta(k).DateTimeRaw - r.Meta(1).DateTimeRaw;
    t = dt(end)+dt(end-1)*1000+dt(end-2)*1000*60+dt(end-3)*1000*60*60; % ms
end