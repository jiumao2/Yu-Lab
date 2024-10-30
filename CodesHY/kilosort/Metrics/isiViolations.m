function fpRate = isiViolations(spike_train, isi_threshold, min_isi)
% Calculate ISI violations for a spike train.
% 
% Based on metric described in Hill et al. (2011) J Neurosci 31: 8699-8705
% 
% modified by Dan Denman from cortex-lab/sortingQuality GitHub by Nick Steinmetz
% 
% Inputs:
% -------
% spike_train : array of spike times in ms
% min_time : minimum time for potential spikes
% max_time : maximum time for potential spikes
% isi_threshold : threshold for isi violation
% min_isi : threshold for duplicate spikes
% 
% Outputs:
% --------
% fpRate : rate of contaminating spikes as a fraction of overall rate
%     A perfect unit has a fpRate = 0
%     A unit with some contamination has a fpRate < 0.5
%     A unit with lots of contamination has a fpRate > 1.0

if nargin < 2
    isi_threshold = 1.5; % in ms
end

if nargin < 3
    min_isi = 0;
end

duplicate_spikes = find(diff(spike_train) <= min_isi);

spike_train(duplicate_spikes + 1) = [];
isis = diff(spike_train);

num_spikes = length(spike_train);
num_violations = sum(isis < isi_threshold);
violation_time = 2*num_spikes*(isi_threshold - min_isi);
total_rate = num_spikes ./ (max(spike_train) - min(spike_train));
violation_rate = num_violations ./ violation_time;
fpRate = violation_rate ./ total_rate;

end