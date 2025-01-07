function indout = findseqmatch(seq_mom,seq_son)
% FINDSEQMATCH Find matched index in seq_mom.
% indout = findseqmatch(seq_mom,seq_son)
% seq_son: the substring
% seq_mom: the full string
% indout: the matched index in seq_mom
indout = zeros(1,length(seq_son));

% for each point in t1, find the corresponding point in t2
min_error = Inf;
min_k = 0;
for k = 1:length(seq_mom)-length(seq_son)+1
    tmp_t1 = seq_son;
    tmp_sum = 0;
    tmp_t1 = tmp_t1-tmp_t1(1)+seq_mom(k);
    
    % find nearest point in seqmom for each point in seqson
    for i = 1:length(tmp_t1)
        l = 1;
        r = length(seq_mom);
        if seq_mom(l) >= tmp_t1(i)
            r = l;
        elseif seq_mom(r) <= tmp_t1(i)
            l = r;
        else
            while r-l > 1
                tmp_idx = round((l+r)/2);
                if seq_mom(tmp_idx) - tmp_t1(i) > 0
                    r = tmp_idx;
                else
                    l = tmp_idx;
                end
            end
        end
        % compute the distance between this point and the nearest point in seqmom
        tmp_sum = tmp_sum + min(abs(seq_mom(r)-tmp_t1(i)),abs(tmp_t1(i)-seq_mom(l)));
    end

    if tmp_sum < min_error 
        min_error = tmp_sum;
        min_k = k;
    end
end
indout(1) = min_k;

% retrieve the index of full sequence
tmp_t1 = tmp_t1-tmp_t1(1)+seq_mom(min_k);
for i = 1:length(tmp_t1)
    l = 1;
    r = length(seq_mom);
    if seq_mom(l) >= tmp_t1(i)
        r = l;
    elseif seq_mom(r) <= tmp_t1(i)
        l = r;
    else
        while r-l > 1
            tmp_idx = round((l+r)/2);
            if seq_mom(tmp_idx) - tmp_t1(i) > 0
                r = tmp_idx;
            else
                l = tmp_idx;
            end
        end
    end

    if abs(seq_mom(r)-tmp_t1(i)) > abs(tmp_t1(i)-seq_mom(l))
        indout(i) = l;
    else
        indout(i) = r;
    end
    
end
    
end