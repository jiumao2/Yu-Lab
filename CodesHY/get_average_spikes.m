function [average_spikes_long, average_spikes_short] = get_average_spikes(r, unit_of_interest,t_pre,t_post,varargin)

    gaussian_kernel = 50;
    normalized = '';
    event = 'press';
    is_channel_number = false;
    is_only_first_session = false;
    t_start = NaN;
    t_end = NaN;
    for i =1:2:nargin-4
        switch varargin{i}
            case 'gaussian_kernel'
                gaussian_kernel = varargin{i+1};
            case 'normalized'
                normalized = varargin{i+1};
            case 'event'
                event = varargin{i+1};
            case 'Channel_Number'
                is_channel_number = varargin{i+1};
            case 'onlyFirstSession'
                is_only_first_session = varargin{i+1};
            case 'tStart'
                t_start = varargin{i+1};
            case 'tEnd'
                t_end = varargin{i+1};
            otherwise
                error('unknown argument');
        end
    end

    t_len = t_post-t_pre+1;

    if is_channel_number
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
        spike_times{k} = round(r.Units.SpikeTimes(k).timings);
        if r.Units.SpikeTimes(k).timings(end)>max_spike_time
            max_spike_time = round(r.Units.SpikeTimes(k).timings(end));
        end
    end

    % binned
    spikes = zeros(length(unit_of_interest),max_spike_time);
    for k = 1:length(unit_of_interest)
        spikes(k,spike_times{unit_of_interest(k)}) = 1;
    end

    % gaussian kernel
    spikes = smoothdata(spikes','gaussian',gaussian_kernel*5)' * 1000; % sigma = 250/5 = 50ms

    % pick correct trials and separate long-FP/short-FP trials
    ind_press = find(strcmp(r.Behavior.Labels, 'LeverPress'));
    t_presses = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_press));
    ind_release = find(strcmp(r.Behavior.Labels, 'LeverRelease'));
    t_releases = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_release));
    ind_rewards = find(strcmp(r.Behavior.Labels, 'ValveOnset'));
    t_rewards= round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_rewards));

    correct_index = r.Behavior.CorrectIndex;
    FP_long_index = find(r.Behavior.Foreperiods(correct_index)==1500);
    FP_short_index = find(r.Behavior.Foreperiods(correct_index)==750);

%     movetime = zeros(1, length(t_rewards));
%     for i =1:length(t_rewards)
%         dt = t_rewards(i)-t_releases(correct_index);
%         dt = dt(dt>0);
%         if ~isempty(dt)
%             movetime(i) = dt(end);
%         end
%     end
%     t_rewards = t_rewards(movetime>0);

    t_rewards_new = [];
    FP_long_index_reward = [];
    FP_short_index_reward = [];
    for i = 1:length(correct_index)
        dt = t_rewards - t_releases(correct_index(i));
        idx_dt = find(dt>0, 1);
        if isempty(idx_dt)
            continue
        end
        if correct_index(i)==length(t_releases) || dt(idx_dt)<t_releases(correct_index(i)+1)-t_releases(correct_index(i))
            t_rewards_new = [t_rewards_new, t_rewards(idx_dt)];
            if r.Behavior.Foreperiods(correct_index(i)) == 1500
                FP_long_index_reward = [FP_long_index_reward, i];
            else
                FP_short_index_reward = [FP_short_index_reward, i];
            end
        end
    end
    t_rewards = t_rewards_new;


    if strcmp(event,'press')
        t_event = t_presses(correct_index);
    elseif strcmp(event,'release')
        t_event = t_releases(correct_index);
    elseif strcmp(event,'reward')
        t_event = t_rewards;
    end
    t_event = t_event(t_event+t_post<length(spikes));

    if is_only_first_session
        t_start = get_t_start_session(r,1);
        t_end = get_t_end_session(r,1);
    end
    if isnan(t_start)
        t_start = get_t_start_session(r, 1);
    end
    if isnan(t_end)
        t_end = get_t_end_session(r, length(r.Meta));
    end

    FP_long_index(FP_long_index>length(t_event)) = [];
    FP_short_index(FP_short_index>length(t_event)) = [];
    FP_long_index_reward(FP_long_index_reward>length(t_event)) = [];
    FP_short_index_reward(FP_short_index_reward>length(t_event)) = [];

    spikes_trial = zeros(t_len, length(t_event), length(unit_of_interest));

    for k = 1:length(t_event)
        for j = 1:length(unit_of_interest)
            spikes_trial(:,k,j) = spikes(j,t_event(k)+t_pre:t_event(k)+t_post);
        end
    end

    idx_included = find(t_event>t_start & t_event<t_end);

    % Average
    if ~strcmp(event,'reward')
        average_spikes_long = reshape(mean(spikes_trial(:,intersect(FP_long_index,idx_included),:),2),t_len,[]);
        average_spikes_short = reshape(mean(spikes_trial(:,intersect(FP_short_index,idx_included),:),2),t_len,[]);  
    else
        average_spikes_long = reshape(mean(spikes_trial(:,intersect(FP_long_index_reward,idx_included),:),2),t_len,[]);
        average_spikes_short = reshape(mean(spikes_trial(:,intersect(FP_short_index_reward,idx_included),:),2),t_len,[]);
    end

    if strcmp(normalized,'zscore')
        average_spikes_long = zscore(average_spikes_long,0,1);
        average_spikes_short = zscore(average_spikes_short,0,1);
    end

end