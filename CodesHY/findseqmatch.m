function indout = findseqmatch(seq_mom,seq_son)
% FINDSEQMATCH Find matched index in seq_mom.
% indout = findseqmatch(seq_mom,seq_son)
% seq_son: the sequence to match
% seq_mom: the reference sequence
% indout: the matched index in seq_mom
%
% Logic:
% 1) Start from the original coarse alignment, and compare it with a simple
%    monotonic nearest-neighbor initialization.
% 2) Remove suspicious repeated or backward matches from the fitting set.
% 3) Fit a linear transform
%       seq_mom ~= b * seq_son + a
%    to capture global time offset and small clock drift.
% 4) Rematch with the fitted transform using monotonic one-to-one nearest
%    neighbors, and iterate a few times until stable.
% 5) Return the candidate matching with the smaller fitting error.

seq_mom = seq_mom(:)';
seq_son = seq_son(:)';
indout = zeros(1,length(seq_son));

if isempty(seq_mom) || isempty(seq_son)
    return
end

if any(diff(seq_mom)<=0) || any(diff(seq_son)<=0)
    error('findseqmatch requires strictly increasing input sequences.');
end

% first-round coarse matching from the original implementation
min_error = Inf;
min_k = 1;
if length(seq_mom) >= length(seq_son)
    for k = 1:length(seq_mom)-length(seq_son)+1
        tmp_t1 = seq_son;
        tmp_sum = 0;
        tmp_t1 = tmp_t1-tmp_t1(1)+seq_mom(k);

        for i = 1:length(tmp_t1)
            idx = findNearestIndex(seq_mom, tmp_t1(i));
            tmp_sum = tmp_sum + abs(seq_mom(idx)-tmp_t1(i));
        end

        if tmp_sum < min_error
            min_error = tmp_sum;
            min_k = k;
        end
    end

    tmp_t1 = seq_son-seq_son(1)+seq_mom(min_k);
else
    tmp_t1 = seq_son-seq_son(1)+seq_mom(1);
end

for i = 1:length(tmp_t1)
    indout(i) = findNearestIndex(seq_mom, tmp_t1(i));
end

max_iter = 5;
indout_best = indout;
fit_error_best = Inf;
raw_error_best = Inf;
slope_best = 1;
intercept_best = 0;

for i_case = 1:2
    if i_case == 1
        indout_this = indout;
    else
        indout_this = zeros(1,length(seq_son));
        idx_start = 1;
        for i = 1:length(seq_son)
            if idx_start > length(seq_mom)
                indout_this(i:end) = length(seq_mom);
                break
            end
            idx_this = findNearestIndex(seq_mom(idx_start:end), seq_son(i));
            idx_this = idx_this + idx_start - 1;
            indout_this(i) = idx_this;
            idx_start = idx_this + 1;
        end
    end

    indout_prev = indout_this;
    for i_iter = 1:max_iter
        is_valid = true(size(indout_this));
        idx_dup = find(diff(indout_this)==0);
        is_valid(idx_dup) = false;
        is_valid(idx_dup+1) = false;
        idx_back = find(diff(indout_this)<0);
        is_valid(idx_back) = false;
        is_valid(idx_back+1) = false;
        idx_valid = find(is_valid);

        if numel(idx_valid) < 2
            break
        end

        p = polyfit(seq_son(idx_valid), seq_mom(indout_this(idx_valid)), 1);
        slope = p(1);
        intercept = p(2);

        indout_this = zeros(1,length(seq_son));
        idx_start = 1;

        for i = 1:length(seq_son)
            if idx_start > length(seq_mom)
                indout_this(i:end) = length(seq_mom);
                break
            end

            t_pred = slope*seq_son(i)+intercept;
            seq_search = seq_mom(idx_start:end);
            idx_this = findNearestIndex(seq_search, t_pred);
            idx_this = idx_this + idx_start - 1;
            indout_this(i) = idx_this;
            idx_start = idx_this + 1;
        end

        if isequal(indout_this, indout_prev)
            break
        end
        indout_prev = indout_this;
    end

    is_valid = true(size(indout_this));
    idx_dup = find(diff(indout_this)==0);
    is_valid(idx_dup) = false;
    is_valid(idx_dup+1) = false;
    idx_back = find(diff(indout_this)<0);
    is_valid(idx_back) = false;
    is_valid(idx_back+1) = false;
    idx_valid = find(is_valid);

    if numel(idx_valid) >= 2
        p = polyfit(seq_son(idx_valid), seq_mom(indout_this(idx_valid)), 1);
        t_fit = p(1)*seq_son(idx_valid)+p(2);
        slope_this = p(1);
        intercept_this = p(2);
        fit_error_this = median(abs(seq_mom(indout_this(idx_valid))-t_fit));
    else
        slope_this = 1;
        intercept_this = 0;
        fit_error_this = Inf;
    end
    raw_error_this = median(abs(seq_mom(indout_this)-seq_son));

    if fit_error_this < fit_error_best || ...
            (fit_error_this == fit_error_best && raw_error_this < raw_error_best)
        indout_best = indout_this;
        fit_error_best = fit_error_this;
        raw_error_best = raw_error_this;
        slope_best = slope_this;
        intercept_best = intercept_this;
    end
end

indout = indout_best;
fprintf('findseqmatch final fit: seq_mom = %.12g * seq_son + %.12g\n', slope_best, intercept_best);
fprintf('findseqmatch meaning: time offset = %.12g, freq difference = %.6f%%\n', intercept_best, (slope_best-1)*100);

end

function idx = findNearestIndex(seq, value)

l = 1;
r = length(seq);

if seq(l) >= value
    idx = l;
    return
end

if seq(r) <= value
    idx = r;
    return
end

while r-l > 1
    tmp_idx = round((l+r)/2);
    if seq(tmp_idx) - value > 0
        r = tmp_idx;
    else
        l = tmp_idx;
    end
end

if abs(seq(r)-value) > abs(value-seq(l))
    idx = l;
else
    idx = r;
end

end
