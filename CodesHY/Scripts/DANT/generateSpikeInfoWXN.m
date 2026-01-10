folder_root = 'D:\Dropbox\13_EphysProcessed\Juno'; % the folder that contains session data, e.g. folder_data/20250510/
rat_name = 'Juno';
folder_task = {'1_AutoShaping', '2_LeverPress', '3_LeverRelease', '4_Wait', '5_SRT_2FPProbeWin1000'};
regions = {'Cortex', 'Striatum'};

% define the number of channels and the range of interests. It should be
% determined with reliable approaches
depth_range = [-Inf, Inf];
num_channels = 383;

% peth params
% use same pre/post time range (ms) to cover all events: press, release, poke.
t_pre = -500;
t_post = 500;
binwidth = 1;
gaussian_kernel = 50;

%% Extract spikeInfo
% initialization
spikeInfoAll = cell(1, length(regions));
count_session = 0;
length_session_name = 8; % e.g., 20250607

for i_task = 1:length(folder_task)
    folder_data = fullfile(folder_root, folder_task{i_task});

    % get all folders
    dir_out = dir(folder_data);
    folder_names = {dir_out.name};
    
    for k = 1:length(folder_names)
        folder_this = folder_names{k}; % e.g., 20250607
        session = folder_this;

        % the length of the folder name should be 8
        if length(folder_this) ~= length_session_name
            continue
        end

        % load necessary data
        r_filename = fullfile(folder_data, folder_this, ['RTarray_', rat_name, '_', session, '.mat']);
        if ~exist(r_filename, 'file')
            error('R not found!');
        end

        disp(['Processing ', folder_this, '...']);
        count_session = count_session+1;
        load(r_filename);
        chanMap = r.Units.ChanMap;

        % compute peth for each unit
        % get event times
        press_times  = r.Behavior.EventTimings(r.Behavior.EventMarkers == 3);
        release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == 5);
        reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == 6);

        % select the good trials
        if ~isempty(press_times)
            idx_correct = r.Behavior.CorrectIndex;
            idx_correct = idx_correct(idx_correct <= min(length(press_times), length(release_times)));
            press_times = press_times(idx_correct);
            release_times = release_times(idx_correct);
    
            assert(all(release_times >= press_times));
        end

        % combine all event times
        event_times = {press_times, release_times, reward_times};

        for j = 1:length(r.Units.SpikeTimes)
            % only consider good units
            if r.Units.SpikeNotes(j,3) ~= 1
                continue
            end

            region_this = r.Units.SpikeNotesColumn5{r.Units.SpikeNotes(j,5)};
            idx_region = find(strcmpi(regions, region_this));
            if isempty(idx_region)
                continue
            end

            wave_mean = r.Units.SpikeTimes(j).wave_mean;

            % get the channel with max amplitude
            [~, channel] = max(max(wave_mean, [], 2) - min(wave_mean, [], 2));
            depth = chanMap.ycoords(channel);

            % compute the peth
            params.pre = -t_pre;
            params.post = t_post;
            params.binwidth = binwidth;

            spike_times = r.Units.SpikeTimes(j).timings;
            peth_all = [];
            for i = 1:length(event_times)
                if isempty(event_times{i})
                    peth_this = NaN(1, t_post-t_pre);
                else
                    peth_this = jpsth(spike_times, event_times{i}, params);
                    peth_this = smoothdata(peth_this, 'gaussian', gaussian_kernel/binwidth*5);
                end
                peth_all = [peth_all, peth_this];
            end

            % only include the units that were recorded in all the sessions
            if depth < depth_range(1) || depth > depth_range(2)
                error('This unit is outside the depth range!');
            end

            % save to spikeInfo
            spikeInfo_this = struct();
            spikeInfo_this.RatName = rat_name;
            spikeInfo_this.Session = session;
            spikeInfo_this.SessionIndex = count_session;
            spikeInfo_this.Unit = j;
            spikeInfo_this.Channel = r.Units.SpikeNotes(k, 1);
            spikeInfo_this.NumInChannel = r.Units.SpikeNotes(k, 2);
            spikeInfo_this.SpikeTimes = r.Units.SpikeTimes(j).timings;
            spikeInfo_this.PETH = peth_all;

            % select the channels within the given ranges
            idx_included = find(chanMap.ycoords(chanMap.connected == 1) >= depth_range(1)...
                & chanMap.ycoords(chanMap.connected == 1) <= depth_range(2));
            assert(length(idx_included) == num_channels);

            spikeInfo_this.Waveform = wave_mean(idx_included, :);
            spikeInfo_this.Xcoords = chanMap.xcoords(idx_included);
            spikeInfo_this.Ycoords = chanMap.ycoords(idx_included);
            spikeInfo_this.Kcoords = chanMap.kcoords(idx_included);
            spikeInfo_this.Channel = find(idx_included == channel);

            if isempty(spikeInfoAll{idx_region})
                spikeInfoAll{idx_region} = spikeInfo_this;
            else
                spikeInfoAll{idx_region}(end+1) = spikeInfo_this;
            end
        end

        disp([folder_this, ' done!']);
    end
end

for k = 1:length(regions)
    filename_output = fullfile('./', ['spikeInfo_', regions{k}, '.mat']);
    spikeInfo = spikeInfoAll{k};
    save(filename_output, 'spikeInfo', '-nocompression');
end
