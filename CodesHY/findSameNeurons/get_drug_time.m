function t = get_drug_time(r)
    t = mean([get_t_start_session(r,2), get_t_end_session(r,1)]);
end