% function pca_neuron_trial(data_path,t_pre,t_post)
data_path = 'c:/Users/jiumao/Desktop/Russo20210910';
if ~exist('r','var')
    load([data_path, '/RTarrayAll.mat'])
end
spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

% unit_of_interest = [2     4     7     8    12    14    16  19];
% unit_of_interest = [1,5,7,8,9,11,12,14,19];
unit_of_interest = 1:length(r.Units.SpikeTimes);

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',500*2)';
spikes = zscore(spikes,0,2);

[coeff, score, latent, tsquared, explained] = pca(spikes');

