function ind_out = getFrameInd(t_frameon, ts)
t_frameon = t_frameon-t_frameon(1);
ts = ts-ts(1);
ind_out = 1:length(ts);

ind_max = 0;
% ind_out = dsearchn(t_frameon,ts);
for k = 1:length(ts)
    ind_out(k) = findNearestPoint(t_frameon,ts(k));
    if ind_out(k)<=ind_max
        ind_out(k) = ind_max+1;
    end
    
    if ind_out(k) > length(t_frameon)
        for j = k:-1:2
            if ind_out(j)-ind_out(j-1) > 1
                ind_out(j:k) = ind_out(j:k)-1;
                ind_out(k) = length(t_frameon);
            end
        end
    end
    
    ind_max = ind_out(k);
end
