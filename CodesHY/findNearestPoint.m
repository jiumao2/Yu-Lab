function ind_out = findNearestPoint(seq, p)
l = 1;
r = length(seq);
m = round((l+r)/2);

while r-l>1
    if seq(m) > p
        r = m;
    elseif seq(m) < p
        l = m;
    else
        ind_out = m;
        return
    end
    m = round((l+r)/2);
end

if abs(seq(l)-p) < abs(seq(r)-p)
    ind_out = l;
else
    ind_out = r;
end
end