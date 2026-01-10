addpath(genpath('F:\DaveeData\EphysCodeWHB'));

folder_data = 'F:\DaveeData';
rat_name = 'Davee';
spikeInfo = [];

% n_session = 6;
num_channels = 384;
depth_range = [-Inf, Inf];
chanMapCommon = [];

% peth params
t_pre = -500;
t_post = 500;
binwidth = 1;
gaussian_kernel = 50;

dir_out = dir(folder_data);
folder_names = {dir_out.name};

count_session = 0;
for k = 1:length(folder_names)
    folder_this = folder_names{k};
    if length(folder_this) ~= 8
        continue
    end

    fprintf('Processing %s ...\n', folder_this);

    dir_out = dir(fullfile(folder_data, folder_this, 'RClass_*.mat'));
    r_filename = dir_out.name;

    load(fullfile(folder_data, folder_this, r_filename));
    if isempty(chanMapCommon)
        chanMapCommon = rClass.Units.ChannelMap;
    end
    
    chanMap = rClass.Units.ChannelMap;
    if ~all(chanMapCommon.ycoords == chanMap.ycoords)
        fprintf('Different chanMap found in %s!\n', folder_this);
        continue
    end

    session = folder_this;
    count_session = count_session+1;

    % get event times
    idx_press = find(strcmpi(rClass.Behavior.Labels, 'LeverPress'));
    idx_release = find(strcmpi(rClass.Behavior.Labels, 'LeverRelease'));
    idx_reward = find(strcmpi(rClass.Behavior.Labels, 'ValveOnset'));

    press_times = rClass.Behavior.EventTimings(rClass.Behavior.EventMarkers == idx_press);
    release_times = rClass.Behavior.EventTimings(rClass.Behavior.EventMarkers == idx_release);
    reward_times = rClass.Behavior.EventTimings(rClass.Behavior.EventMarkers == idx_reward);

    assert(length(press_times) == length(release_times));

    idx_correct = rClass.Behavior.CorrectIndex;
    press_times = press_times(idx_correct);
    release_times = release_times(idx_correct);

    event_times = {press_times, release_times, reward_times};

    for j = 1:length(rClass.Units.SpikeTimes)
        % only consider good units
        if rClass.Units.SpikeNotes(j,3) ~= 1
            continue
        end

        wave_mean = rClass.Units.SpikeTimes(j).wave_mean;
        [~, channel] = max(max(wave_mean, [], 2) - min(wave_mean, [], 2));
        depth = chanMap.ycoords(channel);

        % compute the peth
        params.pre = -t_pre;
        params.post = t_post;
        params.binwidth = binwidth;

        spike_times = rClass.Units.SpikeTimes(j).timings;
        peth_all = [];
        for i = 1:length(event_times)
            peth_this = jpsth(spike_times, event_times{i}, params);
            peth_this = smoothdata(peth_this, 'gaussian', gaussian_kernel/binwidth*5);
            peth_all = [peth_all, peth_this];
        end
        
        % only include the units that were recorded in all the sessions
        if depth < depth_range(1) || depth > depth_range(2)
            continue
        end

        % find this unit in r_all
        idx_in_r_all = [];
        
        spikeInfo_this = struct();
        spikeInfo_this.RatName = rat_name;
        spikeInfo_this.Session = session;
        spikeInfo_this.SessionIndex = count_session;
        spikeInfo_this.Unit = j;
        spikeInfo_this.SpikeTimes = rClass.Units.SpikeTimes(j).timings;
        spikeInfo_this.PETH = peth_all;
    
        idx_included = find(chanMap.ycoords(chanMap.connected == 1) >= depth_range(1)...
            & chanMap.ycoords(chanMap.connected == 1) <= depth_range(2));
        assert(length(idx_included) == num_channels);

        spikeInfo_this.Waveform = wave_mean(idx_included, :);
        spikeInfo_this.Xcoords = chanMap.xcoords(idx_included);
        spikeInfo_this.Ycoords = chanMap.ycoords(idx_included);
        spikeInfo_this.Kcoords = chanMap.kcoords(idx_included);
        spikeInfo_this.Channel = find(idx_included == channel);
        
        if isempty(spikeInfo)
            spikeInfo = spikeInfo_this;
        else
            spikeInfo(end+1) = spikeInfo_this;
        end
    end

    disp([folder_this, ' done!']);
end

save ./spikeInfo.mat spikeInfo -nocompression;
