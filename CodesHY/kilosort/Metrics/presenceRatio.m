function presence_ratio = presenceRatio(spike_train, min_time, max_time, num_bins)
% Calculate fraction of time the unit is present within an epoch.
% 
% Inputs:
% -------
% spike_train : array of spike times
% min_time : minimum time for potential spikes
% max_time : maximum time for potential spikes
% 
% Outputs:
% --------
% presence_ratio : fraction of time bins in which this unit is spiking

if nargin < 4
    num_bins = 100;
end

h = histcounts(spike_train, linspace(min_time, max_time, num_bins));
presence_ratio = sum(h > 0) / num_bins;

end