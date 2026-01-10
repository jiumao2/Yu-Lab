function [t, response_type] = computeResponseTime(r, unit, trigger_times)
t_pre = -100;
t_post = 300;
binwidth = 20;
t_edges = t_pre:binwidth:t_post;
t_bins = 0.5*(t_edges(1:end-1)+t_edges(2:end));
n_trial = length(trigger_times);
alpha = 0.01;

spike_times = r.Units.SpikeTimes(unit).timings;
spike_counts = zeros(n_trial, length(t_bins));
for k = 1:n_trial
    for j = 1:length(t_bins)
        spike_counts(k,j) = sum(spike_times >= trigger_times(k)+t_edges(j) &...
            spike_times < trigger_times(k)+t_edges(j+1));
    end
end

peth = mean(spike_counts);

spike_counts_flattened = spike_counts(:);
n_permutation = 1000;  

max_modulation = max(peth);
max_values = zeros(1,n_permutation);
for k = 1:n_permutation
    max_values(k) = max(...
        mean(...
        reshape(...
        spike_counts_flattened(randperm(n_trial*length(t_bins))), n_trial, length(t_bins))));
end

% figure;
% histogram(max_values);
% hold on;
% xline(max_modulation);

if prctile(max_values, (1-alpha)*100) < max_modulation
    [~, idx_max] = max(peth);
    if t_bins(idx_max) < 0
        t = NaN;
        response_type = NaN;
    else
        t = t_bins(idx_max);
        response_type = 1;
    end
    return
end

% min_modulation = min(peth);
% min_values = zeros(1,n_permutation);
% for k = 1:n_permutation
%     min_values(k) = min(...
%         mean(...
%         reshape(spike_counts_flattened(randperm(n_trial*length(t_bins))), n_trial, length(t_bins))));
% end
% 
% if prctile(min_values, alpha*100) > min_modulation
%     [~, idx_min] = min(peth);
%     if t_bins(idx_min) < 0
%         t = NaN;
%         response_type = NaN;
%     else
%         t = t_bins(idx_min);
%         response_type = 0;
%     end
%     return
% end

t = NaN;
response_type = NaN;
end