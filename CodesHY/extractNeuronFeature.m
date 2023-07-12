function out = extractNeuronFeature(r, unit_num, varargin)
    onlyFirstSession = 'off';
    if nargin>2
        for k = 1:2:size(varargin,2)
            switch varargin{k}
                case 'onlyFirstSession'
                    onlyFirstSession = varargin{k+1};
                otherwise
                    error('wrong argument!');
            end
        end
    end

    spike_times = r.Units.SpikeTimes(unit_num).timings; % ms
    
    if strcmpi(onlyFirstSession, 'on')
        t_end_control = get_t_end_session(r,1);
        spike_times = spike_times(spike_times<t_end_control);
    end

    % date
    out.Date = datestr(r.Meta(1).DateTime,'yyyymmdd');

    % channel
    out.Channel = r.Units.SpikeNotes(unit_num,1);

    % waveform
    out.Waveform = r.Units.SpikeTimes(unit_num).wave;
    if size(out.Waveform,1)>1 && size(out.Waveform,2)>1
        out.Waveform = mean(out.Waveform,1);
    end

    % autocorrelogram
    binwidth = 1; % ms
    window = 50;

    spike_counts = round(spike_times-spike_times(1))+1;
    s = zeros(max(spike_counts),1);
    s(spike_counts) = 1;
    
    [auto_cor, lag] = xcorr(s,s,round(window/binwidth));
    auto_cor(lag==0)=0; 

    out.Autocorrelogram = auto_cor';

    % ISI
    isi = diff(spike_times);
    isi_hist = histcounts(isi,'BinLimits',[0,100],'BinWidth',1);
    isi_freq = isi_hist./sum(isi_hist);
    out.ISI = isi_freq;

    % PETH
    idx_press = find(strcmp(r.Behavior.Labels,'LeverPress'));
    idx_release = find(strcmp(r.Behavior.Labels,'LeverRelease'));
    idx_reward = find(strcmp(r.Behavior.Labels,'ValveOnset'));
    idx_correct = r.Behavior.CorrectIndex;

    press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_press);
    release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_release);
    reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==idx_reward);

    press_times = press_times(idx_correct);
    release_times = release_times(idx_correct);


    if strcmpi(onlyFirstSession, 'on')
        press_times = press_times(press_times<t_end_control);
        release_times = release_times(release_times<t_end_control);
        reward_times = reward_times(reward_times<t_end_control);
    end

    params.pre = 1000;
    params.post = 1000;
    params.binwidth = 10;

    params_press = params;
    params_release = params;
    params_release.post = 500;
    params_reward = params;
    params_reward.pre = 500;

    gaussian_kernel = 5; % ms

    PETH_press = jpsth(spike_times, press_times, params_press);
    PETH_release = jpsth(spike_times, release_times, params_release);
    PETH_reward = jpsth(spike_times, reward_times, params_reward);
    PETH_press = smoothdata(PETH_press,'gaussian',gaussian_kernel*5);
    PETH_release = smoothdata(PETH_release,'gaussian',gaussian_kernel*5);
    PETH_reward = smoothdata(PETH_reward,'gaussian',gaussian_kernel*5);

    PETH_all = [PETH_press, PETH_release, PETH_reward];
    
    out.PETH = PETH_all;
end