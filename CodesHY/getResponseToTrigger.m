function [t, unit_info] = getResponseToTrigger(r, unit, varargin)
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
t_step = 20; % ms
bin_width = 50; % ms
alpha = 0.05; % the significance in a particular bin
n_consecutive = 5; % considered significant p < alpha in n_consecutive bins
min_n_trial = 10; % bad data if trial number of FP = 750 or FP = 1500 is less than n_trial
RT_range = [200, 600]; % only consider trials where RT is in this range to avoid anticipatory response and the interference of release-related response
is_late_trials_included = false; % Include the late trials. Note that the RT_range should be changed as well
algorithm = 'ranksum'; % 'ranksum', 'permutation_test' or 'ttest'
response_type = 'both'; % 'increased', 'decreased' or 'both'
trigger_type = [];

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
        elseif strcmpi(varargin{k}, 'RT_range')
            RT_range = varargin{k+1};
        elseif strcmpi(varargin{k}, 'is_late_trials_included')
            is_late_trials_included = varargin{k+1};
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

t_bins = (t_pre:t_step:t_post-t_step) + t_step/2;
n_bins = length(t_bins);

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
params.RT_range = RT_range;
params.min_n_trial = min_n_trial;
params.is_late_trials_included = is_late_trials_included;

unit_info.params = params;
unit_info.t_bins = t_bins;

%% Data processing
% extract data
unit_info.subject = r.Meta(1).Subject;
unit_info.session = datestr(r.Meta(1).DateTime, 'yyyymmdd');
unit_info.unitID = unit;
unit_info.spike_times = r.Units.SpikeTimes(unit).timings;     

correct_idx = reshape(r.Behavior.CorrectIndex, 1, []);
if is_late_trials_included
    late_idx = reshape(r.Behavior.LateIndex, 1, []);
    correct_idx = sort([late_idx, correct_idx]);
end

press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverPress')));
release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverRelease')));
if size(r.Behavior.Foreperiods,1) ~= size(press_times, 1)
    r.Behavior.Foreperiods = r.Behavior.Foreperiods';
end

% only include correct trials
unit_info.release_times = release_times(correct_idx);
unit_info.press_times = press_times(correct_idx);
unit_info.FPs = r.Behavior.Foreperiods(correct_idx);
unit_info.trigger_times = unit_info.press_times + unit_info.FPs;

if isfield(r.Behavior, 'TriggerTypes')
    unit_info.trigger_types = r.Behavior.TriggerTypes(correct_idx);
    unit_info.trigger_type_labels = r.Behavior.TriggerTypeLabels;
end

% check the intergrity of behavior data
if length(unit_info.press_times) ~= length(unit_info.FPs) || length(unit_info.FPs)~=length(unit_info.release_times)
    warning('Bad behavior data!');
    t = NaN;
    unit_info = [];
    return
end

unit_info.RTs = unit_info.release_times - unit_info.press_times - unit_info.FPs;

idx_good_rt = unit_info.RTs>RT_range(1) & unit_info.RTs<RT_range(2);

% trigger type could be tone or flash
idx_trigger_type = ones(length(correct_idx), 1);
if ~isempty(trigger_type) && isfield(r.Behavior, 'TriggerTypes')
    idx_trigger_type = unit_info.trigger_types == trigger_type;
end

idx_cued = ones(length(correct_idx), 1);
if isfield(r.Behavior, 'CueIndex')
    idx_cued = r.Behavior.CueIndex(correct_idx,2) == 1;
end

% idx_good_fp = unit_info.FPs==750 | unit_info.FPs==1500;

idx_good_trial = find((idx_good_rt & unit_info.FPs==750 & idx_cued & idx_trigger_type) | unit_info.FPs==1500);

unit_info.release_times = unit_info.release_times(idx_good_trial);
unit_info.press_times = unit_info.press_times(idx_good_trial);
unit_info.FPs = unit_info.FPs(idx_good_trial);
unit_info.trigger_times = unit_info.trigger_times(idx_good_trial);
unit_info.RTs = unit_info.RTs(idx_good_trial);

% separate the short / long trials
unit_info.idx_shortFP = find(unit_info.FPs == 750);
unit_info.idx_longFP = find(unit_info.FPs == 1500);

if length(unit_info.idx_shortFP) < min_n_trial || length(unit_info.idx_longFP) < min_n_trial
    warning(['Correct trials less than ', num2str(min_n_trial), '!']);
    t = NaN;
    unit_info = [];
    return
end

%% Compute the p_values in each bin
p_values = zeros(1, n_bins);

for k = 1:n_bins
    t0 = t_pre+k*t_step-bin_width/2;
    t1 = t_pre+k*t_step+bin_width/2;

    trigger_times = unit_info.press_times+750;
    
    % trial type could be FP=750 or FP=1500
    trial_type = zeros(length(trigger_times),1);
    trial_type(unit_info.idx_shortFP) = 1; % trial_type = 1 if FP = 750 in this trial
    
    % get the spike counts in each bin
    timings = unit_info.spike_times;
    spike_counts = zeros(length(trigger_times),1);
    for i = 1:length(trigger_times)
        spike_counts(i) = sum(timings>trigger_times(i)+t0 & timings<trigger_times(i)+t1);
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
        p_values(k) = ranksum(spike_counts(trial_type == 0), spike_counts(trial_type == 1), 'tail', tail);
    elseif strcmpi(algorithm, 'ttest')
        p_values(k) = ttest2(spike_counts(trial_type == 0), spike_counts(trial_type == 1), 'Vartype', 'unequal', 'Tail', tail);
    elseif strcmpi(algorithm, 'permutation_test')
        p_values(k) = permutationTest(spike_counts(trial_type == 0), spike_counts(trial_type == 1), 1000, tail);
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
for k = 1:length(p_values)-n_consecutive
    % the response in 0~750 ms should be identical in FP=750 and FP=1500 trials 
    if t_bins(k)<0
        continue
    end

    if all(p_values(k:k+n_consecutive-1) < alpha)
        idx_significant = k;
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