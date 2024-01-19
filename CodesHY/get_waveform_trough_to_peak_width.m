function [width, waveform_out] = get_waveform_trough_to_peak_width(waveform, n)
if nargin<2
    n = round(length(waveform)/61);
end

waveform_all = reshape(waveform, [], n);

[~, idx_best] = max(max(waveform_all) - min(waveform_all));
waveform_out = waveform_all(:, idx_best);

waveform_out = waveform_out - mean(waveform_out(1:10));

[~, min_idx] = min(waveform_out);

% get subsequent maximum
[~, max_idx] = max(waveform_out(min_idx+1:end));


width = max_idx./30;
end