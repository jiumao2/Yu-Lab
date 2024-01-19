function [width, waveform_out] = get_waveform_half_width(waveform, n_waveforms)
if nargin<2
    n_waveforms = round(length(waveform)/61);
end

waveform_all = reshape(waveform, [], n_waveforms);

[~, idx_best] = max(max(waveform_all) - min(waveform_all));
waveform_out = waveform_all(:, idx_best);

% width of half-maximum
waveform_out = waveform_out - mean(waveform_out(1:10));
[min_waveform, min_idx] = min(waveform_out); % only consider the downward waveform
[max_waveform, max_idx] = max(waveform_out);

if abs(min_waveform) >= abs(max_waveform)
    half_minimum = 0.5*min_waveform;
    peak_idx = min_idx;
else
    half_minimum = 0.5*max_waveform;
    peak_idx = max_idx;
end

cross_x = [];
for k = 1:length(waveform_out)-1
    if (waveform_out(k) - half_minimum) * (waveform_out(k+1) - half_minimum) < 0
        cross_x = [cross_x, k+0.5];
    end
end

if length(cross_x) ~= 2
    warning('More than 2 cross points found! Using nearest 2 points around the peak!');
    for k = 1:length(cross_x)-1
        if (cross_x(k)-peak_idx)*(cross_x(k+1)-peak_idx) < 0
            cross_x = cross_x(k:k+1);
            break
        end
    end
end

width = (cross_x(end) - cross_x(1))./30;
end