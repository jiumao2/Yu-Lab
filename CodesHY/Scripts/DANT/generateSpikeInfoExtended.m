folder_root = 'D:\Dropbox\13_EphysProcessed\Dara'; % the folder that contains session data, e.g. folder_data/20250510/
rat_name = 'Dara';
folder_task = {'1_AutoShaping', '2_LeverPress', '3_LeverRelease', '4_Wait', '5_SRT_2FPProbeWin1000', '6_SRT_2FPProbe'};
regions = {'Cortex', 'Striatum'};

% define the number of channels and the range of interests. It should be
% determined with reliable approaches
num_channels = 439;

% peth params
% use same pre/post time range (ms) to cover all events: press, release, poke.
t_pre = -500;
t_post = 500;
binwidth = 1;
gaussian_kernel = 50;

chanMap = load('./mergedChanMap.mat');
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

            % save to spikeInfo
            spikeInfo_this = struct();
            spikeInfo_this.RatName = rat_name;
            spikeInfo_this.Session = session;
            spikeInfo_this.SessionIndex = count_session;
            spikeInfo_this.Unit = j;
            spikeInfo_this.ChannelR = r.Units.SpikeNotes(j, 1);
            spikeInfo_this.NumInChannel = r.Units.SpikeNotes(j, 2);
            spikeInfo_this.SpikeTimes = r.Units.SpikeTimes(j).timings;
            spikeInfo_this.PETH = peth_all;

            % find the existing channels
            n_channels = length(chanMap.ycoords);
            ids_all = chanMap.ycoords*1e6+chanMap.xcoords;
            ids_this = r.Units.ChanMap.ycoords*1e6 + r.Units.ChanMap.xcoords;
            idx_intersect = arrayfun(@(x)find(ids_all == x), ids_this);
            idx_others = setdiff(1:n_channels, idx_intersect);

            waveforms = zeros(n_channels, size(r.Units.SpikeTimes(1).wave_mean, 2));
            waveforms(idx_intersect,:) = r.Units.SpikeTimes(j).wave_mean;

            % Kriging interpolation
            channel_locations_this = [r.Units.ChanMap.xcoords, r.Units.ChanMap.ycoords];
            channel_locations_others = [chanMap.xcoords(idx_others), chanMap.ycoords(idx_others)];

            % Map waveforms to other channel sites
            Kxx = computeKernel2D(channel_locations_this, channel_locations_this);
            Kyx = computeKernel2D(channel_locations_others, channel_locations_this);

            % kernel prediction matrix
            M = Kyx /(Kxx + .01 * eye(size(Kxx,1)));

            waveforms(idx_others,:) = M * r.Units.SpikeTimes(j).wave_mean;

            spikeInfo_this.Waveform = waveforms;
            spikeInfo_this.Xcoords = chanMap.xcoords;
            spikeInfo_this.Ycoords = chanMap.ycoords;
            spikeInfo_this.Kcoords = chanMap.kcoords;

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
    filename_output = fullfile('./Merged/', ['spikeInfo_', regions{k}, '.mat']);
    spikeInfo = spikeInfoAll{k};
    save(filename_output, 'spikeInfo', '-nocompression');
end
