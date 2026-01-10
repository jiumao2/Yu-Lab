folder_root = 'D:\Dropbox\13_EphysProcessed\Juno'; % the folder that contains session data, e.g. folder_data/20250510/
rat_name = 'Juno';
folder_task = {'1_AutoShaping', '2_LeverPress', '3_LeverRelease', '4_Wait', '5_SRT_2FPProbeWin1000'};

%% Extract spikeInfo
% initialization
count_session = 0;
length_session_name = 8; % e.g., 20250607

SessionID = [];
SessionName = {};
TrialID = [];
PressTime = [];
TriggerTime = [];
ReleaseTime = [];
RewardTime = [];
Performance = {};
Cue = [];
FP = [];

for i_task = 1:length(folder_task)
    folder_data = fullfile(folder_root, folder_task{i_task});

    % get all folders
    dir_out = dir(folder_data);
    folder_names = {dir_out.name};

    for i_session = 1:length(folder_names)
        folder_this = folder_names{i_session}; % e.g., 20250607
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

        idx_press = find(strcmpi(r.Behavior.Labels, 'LeverPress'));
        idx_trigger = find(strcmpi(r.Behavior.Labels, 'Trigger'));
        idx_release = find(strcmpi(r.Behavior.Labels, 'LeverRelease'));
        idx_reward = find(strcmpi(r.Behavior.Labels, 'ValveOnset'));

        press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_press);
        trigger_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_trigger);
        release_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_release);
        reward_times = r.Behavior.EventTimings(r.Behavior.EventMarkers == idx_reward);

        if length(press_times) > length(release_times)
            n_trial = length(release_times);
            press_times = press_times(1:n_trial);
        end

        if ~isempty(press_times)
            assert(length(press_times) == length(release_times));
            assert(all(release_times > press_times));
        end

        count_trial = 0;

        if isempty(press_times) % AutoShaping
            for j = 1:length(trigger_times)
                % find the corresponding reward times
                if j < length(trigger_times)
                    idx = find(reward_times > trigger_times(j) & reward_times < trigger_times(j+1));
                else
                    idx = find(reward_times > trigger_times(j), 1);
                end

                if isempty(idx)
                    reward_time_this = NaN;
                    performance_this = 'Late';
                else
                    reward_time_this = reward_times(idx);
                    performance_this = 'Correct';
                end

                count_trial = count_trial+1;
                SessionID(end+1) = count_session;
                SessionName{end+1} = folder_this;
                TrialID(end+1) = count_trial;
                PressTime(end+1) = NaN;
                TriggerTime(end+1) = trigger_times(j);
                ReleaseTime(end+1) = NaN;
                RewardTime(end+1) = reward_time_this;
                Performance{end+1} = performance_this;
                FP(end+1) = NaN;
                Cue(end+1) = 1;
            end
        else
            for j = 1:length(press_times)
                if any(r.Behavior.DarkIndex == j)
                    continue
                end
    
                if strcmpi(r.Behavior.Outcome{j}, 'NaN')
                    continue
                end
    
                if j < length(press_times)
                    idx = find(reward_times > release_times(j) & reward_times < press_times(j+1));
                else
                    idx = find(reward_times > release_times(j), 1);
                end
    
                if isempty(idx)
                    reward_time_this = NaN;
                else
                    reward_time_this = reward_times(idx);
                end
                assert(~(~isnan(reward_time_this) & ~strcmpi(r.Behavior.Outcome{j}, 'Correct')));
    
                count_trial = count_trial+1;
                SessionID(end+1) = count_session;
                SessionName{end+1} = folder_this;
                TrialID(end+1) = count_trial;
                PressTime(end+1) = press_times(j);
                if (strcmpi(r.Behavior.Outcome{j}, 'Correct') || strcmpi(r.Behavior.Outcome{j}, 'Late'))...
                        && r.Behavior.CueIndex(j,2) == 1
                    TriggerTime(end+1) = press_times(j) + r.Behavior.Foreperiods(j);
                else
                    TriggerTime(end+1) = NaN;
                end
                ReleaseTime(end+1) = release_times(j);
                RewardTime(end+1) = reward_time_this;
                Performance{end+1} = r.Behavior.Outcome{j};
                FP(end+1) = r.Behavior.Foreperiods(j);
                Cue(end+1) = r.Behavior.CueIndex(j,2);
            end
        end

        fprintf('%s done!\n', folder_this);
    end
end

%% save to a table
tbl = table();

tbl.SessionID = SessionID';
tbl.SessionName = SessionName';
tbl.TrialID = TrialID';
tbl.PressTime = PressTime';
tbl.TriggerTime = TriggerTime';
tbl.ReleaseTime = ReleaseTime';
tbl.RewardTime = RewardTime';
tbl.Performance = Performance';
tbl.FP = FP';
tbl.Cue = Cue';

writetable(tbl, ['./BehaviorTable_', rat_name, '.csv']);
