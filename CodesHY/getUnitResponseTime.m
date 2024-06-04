function [response_time, p_out, t_plot] = getUnitResponseTime(r, unit, varargin)

t_pre = -200;
t_post = 600;
t_step = 20;
bin_width = 50;
rt_window = [200, 600];
min_n_trial = 10;
p_threshold = 0.05;
n_consequtive_bins = 5;

if nargin > 2
    for k = 1:2:size(varargin,2)
        if strcmpi(varargin{k},'t_pre')
            t_pre = varargin{k+1};
        elseif strcmpi(varargin{k},'t_post')
            t_post = varargin{k+1};
        elseif strcmpi(varargin{k},'t_step')
            t_step = varargin{k+1};
        elseif strcmpi(varargin{k},'bin_width')
            bin_width = varargin{k+1};
        elseif strcmpi(varargin{k},'rt_window')
            rt_window = varargin{k+1};
        elseif strcmpi(varargin{k},'min_n_trial')
            min_n_trial = varargin{k+1};
        elseif strcmpi(varargin{k},'p_threshold')
            p_threshold = varargin{k+1};
        elseif strcmpi(varargin{k},'n_consequtive_bins')
            n_consequtive_bins = varargin{k+1};
        else
            error('Wrong arguments!');
        end
    end
end


t_plot = t_pre:t_step:t_post;
n_bins = length(t_plot);

save_filename = 'ResponsePrediction_p_value';
save_resolution = 1200;

%% Data processing
% extract data

subject = r.Meta(1).Subject;
session = datestr(r.Meta(1).DateTime, 'yyyymmdd');
timings = r.Units.SpikeTimes(unit).timings;

correct_idx = r.Behavior.CorrectIndex;
press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverPress')));
release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels,'LeverRelease')));
release_times = release_times(correct_idx);
press_times = press_times(correct_idx);
FPs = r.Behavior.Foreperiods(correct_idx);
trigger_times = press_times + FPs;

if length(press_times) ~= length(FPs) || length(FPs)~=length(release_times)
    error('Bad behavior data');
end

RTs = release_times - press_times - FPs;

idx_good_rt = RTs>rt_window(1) & RTs<rt_window(2);
idx_good_fp = FPs==750 | FPs==1500;
idx_good_trial = find(idx_good_rt & idx_good_fp);

release_times = release_times(idx_good_trial);
press_times = press_times(idx_good_trial);
FPs = FPs(idx_good_trial);
trigger_times = trigger_times(idx_good_trial);
RTs = RTs(idx_good_trial);
idx_short = find(FPs == 750);
idx_long = find(FPs == 1500);

if length(idx_short) < min_n_trial || length(idx_long) < min_n_trial
    error('Too few trials!');
end


%%
p_values_ranksum = zeros(1, n_bins);
% p_values_t_test = zeros(1, n_bins);
for j = 1:n_bins
    t0 = t_plot(j)-bin_width/2;
    t1 = t_plot(j)+bin_width/2;

    trigger_times = press_times+750;
    outcome = zeros(length(trigger_times),1);
    outcome(idx_short) = 1;

    spike_counts = zeros(length(trigger_times),1);
    for i = 1:length(trigger_times)
        spike_counts(i) = sum(timings>trigger_times(i)+t0 & timings<trigger_times(i)+t1);
    end
    p_values_ranksum(j) = ranksum(spike_counts(outcome == 0), spike_counts(outcome == 1));
%     p_values_t_test(j) = ttest2(spike_counts(outcome == 0), spike_counts(outcome == 1), 'Vartype', 'unequal');
    
    if isnan(p_values_ranksum(j))
        p_values_ranksum(j) = 1;
    end
end

p_out = p_values_ranksum;
response_time = NaN;
for k = 1:n_bins-n_consequtive_bins+1
    if all(p_out(k:k+n_consequtive_bins-1) < p_threshold)
        response_time = t_plot(k);
        break
    end
end


end