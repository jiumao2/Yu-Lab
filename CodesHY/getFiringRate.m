function firing_rate = getFiringRate(spike_times, times, binwidth)
%GETFIRINGRATE get firing rates from spike_times
    if nargin <= 2
        binwidth = 50;
    end
    firing_rate = zeros(size(times));
    for k = 1:length(times)
        spike_num = sum(spike_times>=times(k)-binwidth/2 & spike_times<=times(k)+binwidth/2);
        firing_rate(k) = spike_num./binwidth;
    end
end

