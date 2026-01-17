function [t, response_type_out, unit_info] = getResponseToTriggerPlain(spike_times, trigger_times, varargin)
% GETRESPONSETOTRIGGER
%
% refer to Sul, Jung Hoon, Suhyun Jo, Daeyeol Lee, and Min Whan Jung. “Role of Rodent Secondary Motor Cortex in Value-Based Action Selection.” Nature Neuroscience 14, no. 9 (September 2011): 1202–8. https://doi.org/10.1038/nn.2881.
%
% For individual neurons, we examined whether neuronal activity that was
% associated with the trigger signal during a 50-ms sliding time window (with 20-ms time steps) 
% was significantly different in the short or long FP trials based on a ranksum test (α = 0.05). 
% The onset of response was determined as the first time point at which 
% the neuronal activity was significantly different between short-FP and long-FP trials 
% for a minimum of 100 ms (consecutive 5 bins)
%
% FP-750 trials: correct FP = 750 trials and RT is in RT_range
% FP-1500 trials: all correct FP = 1500 trials
%

t_pre = -200; % from trigger, in ms
t_post = 600; % from trigger, in ms
t_step = 10; % ms
bin_width = 50; % ms
alpha = 0.05; % the significance in a particular bin
n_consecutive = 5; % considered significant p < alpha in n_consecutive bins
min_n_trial = 10; % bad data if trial number of FP = 750 or FP = 1500 is less than n_trial
algorithm = 'ranksum'; % 'ranksum', 'permutation_test' or 'ttest'
response_type = 'both'; % 'increased', 'decreased' or 'both'

if nargin > 2
    for k = 1:2:size(varargin, 2)
        if strcmpi(varargin{k}, 't_pre')
            t_pre = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_post')
            t_post = varargin{k+1};
        elseif strcmpi(varargin{k}, 't_step')
            t_step = varargin{k+1};
        elseif strcmpi(varargin{k}, 'bin_width')
            bin_width = varargin{k+1};
        elseif strcmpi(varargin{k}, 'alpha')
            alpha = varargin{k+1};
        elseif strcmpi(varargin{k}, 'n_consecutive')
            n_consecutive = varargin{k+1};
        elseif strcmpi(varargin{k}, 'min_n_trial')
            min_n_trial = varargin{k+1};
        elseif strcmpi(varargin{k}, 'algorithm')
            algorithm = varargin{k+1};
        elseif strcmpi(varargin{k}, 'response_type')
            response_type = varargin{k+1};
        elseif strcmpi(varargin{k}, 'trigger_type')
            trigger_type = varargin{k+1};
        else
            error('Wrong argument!');
        end
    end
end

t_bins = t_pre:t_step:t_post;

unit_info = struct();
params = struct();

params.response_type = response_type;
params.algorithm = algorithm;
params.n_consecutive_bins = n_consecutive;
params.alpha = alpha;
params.t_pre = t_pre;
params.t_post = t_post;
params.t_step = t_step;
params.binwidth = bin_width;
params.min_n_trial = min_n_trial;

unit_info.params = params;
unit_info.t_bins = t_bins;

%% Data processing
% extract data
unit_info.spike_times = spike_times;     

% only include correct trials
unit_info.trigger_times = trigger_times;

if length(trigger_times) < min_n_trial
    warning(['Correct trials less than ', num2str(min_n_trial), '!']);
    t = NaN;
    response_type_out = '';
    unit_info = [];
    return
end

%% It should first be modulated by the trigger signal
% permutation test
p = checkModulationShuffling(unit_info.spike_times, trigger_times, -500, t_post, bin_width);
if p >= alpha
    t = NaN;
    unit_info = [];
    response_type_out = '';
    return
end

%% Compute the p_values in each bin
dt_compare = -(t_post+bin_width); % compare the spike counts in the target bin and in the bin dt before that bin

n_bins = length(t_bins);
p_values = zeros(1, n_bins);
tails = zeros(1, n_bins);

for k = 1:n_bins
    t0 = t_bins(k)-bin_width;
    t1 = t_bins(k);
    
    % get the spike counts in each bin
    timings = unit_info.spike_times;
    spike_counts_tone = zeros(length(trigger_times),1);
    spike_counts_control = zeros(length(trigger_times),1);
    for i = 1:length(trigger_times)
        spike_counts_tone(i) = sum(timings>trigger_times(i)+t0 & timings<trigger_times(i)+t1);
        spike_counts_control(i) = sum(timings>trigger_times(i)+t0+dt_compare & timings<trigger_times(i)+t1+dt_compare);
    end
    
    % 'increased' if only those units being activated after the trigger signal are considered
    if strcmpi(response_type, 'increased')
        tail = 'left';
    elseif strcmpi(response_type, 'decreased')
        tail = 'right';
    elseif strcmpi(response_type, 'both')
        tail = 'both';
    else
        error('Wrong response type!');
    end

    if strcmpi(algorithm, 'ranksum')
        p_values(k) = ranksum(spike_counts_control, spike_counts_tone, 'tail', tail);
    elseif strcmpi(algorithm, 'ttest')
        p_values(k) = ttest2(spike_counts_control, spike_counts_tone, 'Vartype', 'unequal', 'Tail', tail);
    elseif strcmpi(algorithm, 'permutation_test')
        p_values(k) = permutationTest(spike_counts_control, spike_counts_tone, 1000, tail);
    end

    if mean(spike_counts_control) <= mean(spike_counts_tone)
        tails(k) = 1;
    else
        tails(k) = 0;
    end
    
    % deal with NaN issues
    if isnan(p_values(k))
        p_values(k) = 1;
    end
end

unit_info.p = p_values;

% False discovery rate control may be not nessecary here because we added
% the constraints that p should be smaller than alpha for n_consecutive bins 
% [~, p_crit] = fdr_bh([p_all_ranksum{1}(:); p_all_ranksum{2}(:)], p_threshold);

%% siginificance: p<alpha for n_consecutive consecutive bins 
idx_significant = NaN;
response_type_out = '';
for k = 1:length(p_values)-n_consecutive
    % the response in 0~750 ms should be identical in FP=750 and FP=1500 trials 
    if t_bins(k)<0
        continue
    end

    if all(p_values(k:k+n_consecutive-1) < alpha) && length(unique(tails(k:k+n_consecutive-1))) == 1
        idx_significant = k;
        if tails(k) == 1
            response_type_out = 'increased';
        else
            response_type_out = 'decreased';
        end
        break
    end
end

if isnan(idx_significant)
    unit_info.tSignificant = NaN;
else
    unit_info.tSignificant = t_bins(idx_significant);
end

t = unit_info.tSignificant;

end