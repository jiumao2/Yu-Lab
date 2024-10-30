function fraction_missing = amplitudeCutoffs(amplitudes, num_histogram_bins, histogram_smoothing_value)
% Calculate approximate fraction of spikes missing from a distribution of amplitudes
% 
% Assumes the amplitude histogram is symmetric (not valid in the presence of drift)
% 
% Inspired by metric described in Hill et al. (2011) J Neurosci 31: 8699-8705
% 
% Input:
% ------
% amplitudes : 1 x n_spike_times array
%     Array of amplitudes (don't need to be in physical units)
% 
% Output:
% -------
% fraction_missing : 1 x 1 double
%     Fraction of missing spikes (0-0.5)
%     If more than 50% of spikes are missing, an accurate estimate isn't possible

if nargin < 2
    num_histogram_bins = 500;
end

if nargin < 3
    histogram_smoothing_value = 3;
end

h = histcounts(amplitudes, num_histogram_bins);

pdf = smoothdata(h, 'gaussian', histogram_smoothing_value*5);
pdf = pdf./sum(pdf);

[~, peak_index] = max(pdf);
[~, G] = min(abs(pdf(peak_index+1:end) - pdf(1)));
G = G + peak_index;

fraction_missing = sum(pdf(G+1:end));

fraction_missing = min(fraction_missing, 0.5);

end













