function [average_spikes_long, average_spikes_short] = get_average_spikes(r, unit_of_interest,t_pre,t_post,varargin)

gaussian_kernel = 50;
normalized = '';
for i =1:2:nargin-4
    switch varargin{i}
        case 'gaussian_kernel'
            gaussian_kernel = varargin{i+1};
        case 'normalized'
            normalized = varargin{i+1};
        otherwise
            errordlg('unknown argument')
    end
end

t_len = t_post-t_pre+1;

if size(unit_of_interest,1)>1 && size(unit_of_interest,2)>1 
    unit_of_interest_new = [];
    for k = 1:size(unit_of_interest,1)
        unit_of_interest_new = [unit_of_interest_new,find(r.Units.SpikeNotes(:,1)==unit_of_interest(k,1) ...
            & r.Units.SpikeNotes(:,2)==unit_of_interest(k,2))];
    end
    unit_of_interest = unit_of_interest_new;
end
if isempty(unit_of_interest)
    average_spikes_long = [];
    average_spikes_short = [];
    return
end

spike_times = cell(length(r.Units.SpikeTimes),1);

max_spike_time = 0;
for k = 1:length(spike_times)
    spike_times{k} = r.Units.SpikeTimes(k).timings;
    if r.Units.SpikeTimes(k).timings(end)>max_spike_time
        max_spike_time = r.Units.SpikeTimes(k).timings(end);
    end
end

% binned
spikes = zeros(length(unit_of_interest),max_spike_time);
for k = 1:length(unit_of_interest)
    spikes(k,spike_times{unit_of_interest(k)}) = 1;
end

% gaussian kernel
spikes = smoothdata(spikes','gaussian',gaussian_kernel*5)'; % sigma = 250/5 = 50ms

% pick correct trials and separate long-FP/short-FP trials
press_times = round(r.Behavior.EventTimings(r.Behavior.EventMarkers==3));

correct_index = r.Behavior.CorrectIndex;
FP_long_index = find(r.Behavior.Foreperiods(correct_index)==1500);
FP_short_index = find(r.Behavior.Foreperiods(correct_index)==750);

spikes_trial_flattened = zeros(length(unit_of_interest),t_len*length(correct_index));

for k = 1:length(correct_index)
    spikes_trial_flattened(:,t_len*(k-1)+1:t_len*k) = spikes(:,press_times(correct_index(k))+t_pre:press_times(correct_index(k))+t_post);
end

% normalize
if strcmp(normalized,'zscore')
    spikes_trial_flattened = zscore(spikes_trial_flattened,0,2);
elseif strcmp(normalized,'minmax')
    spikes_trial_flattened = (spikes_trial_flattened-min(spikes_trial_flattened))/(max(spikes_trial_flattened)-min(spikes_trial_flattened));
end
spikes_trial = reshape(spikes_trial_flattened',t_len,length(correct_index),length(unit_of_interest));

% Average
average_spikes_long = reshape(mean(spikes_trial(:,FP_long_index,:),2),t_len,[]);
average_spikes_short = reshape(mean(spikes_trial(:,FP_short_index,:),2),t_len,[]);    
end