function indout = matching_time(t2,t1)
% t1: the substring
% t2: the full string
% intout: the matched index in t2
indout = zeros(1,length(t1));

% for each point in t1, find the corresponding point in t2
j = 1;
min_error = 1e8;
min_k = 0;
for k = 1:length(t2)-length(t1)+1
    tmp_t1 = t1;
    tmp_sum = 0;
    tmp_t1 = tmp_t1-tmp_t1(j)+t2(k);

    for i = 1:length(tmp_t1)
        l = 1;
        r = length(t2);
        if t2(l) >= tmp_t1(i)
            r = l;
        elseif t2(r) <= tmp_t1(i)
            l = r;
        else
            while r-l > 1
                tmp_idx = round((l+r)/2);
                if t2(tmp_idx) - tmp_t1(i) > 0
                    r = tmp_idx;
                else
                    l = tmp_idx;
                end
            end
        end
        tmp_sum = tmp_sum + min(abs(t2(r)-tmp_t1(i)),abs(tmp_t1(i)-t2(l)));
    end

    if tmp_sum < min_error 
        min_error = tmp_sum;
        min_k = k;
    end
end
indout(j) = min_k;

tmp_t1 = tmp_t1-tmp_t1(1)+t2(min_k);
for i = 1:length(tmp_t1)
    l = 1;
    r = length(t2);
    if t2(l) >= tmp_t1(i)
        r = l;
    elseif t2(r) <= tmp_t1(i)
        l = r;
    else
        while r-l > 1
            tmp_idx = round((l+r)/2);
            if t2(tmp_idx) - tmp_t1(i) > 0
                r = tmp_idx;
            else
                l = tmp_idx;
            end
        end
    end

    if abs(t2(r)-tmp_t1(i)) > abs(tmp_t1(i)-t2(l))
        indout(i) = l;
    else
        indout(i) = r;
    end
    
end
    
end