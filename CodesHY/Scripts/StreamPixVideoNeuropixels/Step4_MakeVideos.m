rat_name = 'Punch';
folder_video = './';
time_range_side = [-2400, 3000];
time_range_top = [-5000, 5000];

% read the folders
dir_output = dir(folder_video);

filenames = {dir_output.name};

folder_data = {};
for k = 1:length(filenames)
    folder_this = filenames{k};
    if length(folder_this) ~= 15
        continue
    end

    if ~exist(fullfile(folder_video, folder_this), 'dir')
        continue
    end

    folder_data{end+1} = folder_this;
end

disp(folder_data)


for i_folder = 1:length(folder_data)
    folder_this = folder_data{i_folder};
    session = folder_this(1:8);

    if str2double(session) <= 20241130
        continue
    end

    load(fullfile(folder_video, folder_this, 'timestamps.mat'));    
    r_file = fullfile(folder_video, folder_this, 'RTarrayAll.mat');

    if ~exist(r_file, 'file')
        continue
    end
    load(r_file);

    % validate r
    t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
    t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverRelease')));
    FPs = r.Behavior.Foreperiods;

    if length(t_press) > length(t_release)
        n_press = length(t_release);

        t_press = t_press(1:n_press);
        assert(all(t_release >= t_press));

        r.Behavior.Outcome = r.Behavior.Outcome(1:n_press);
        r.Behavior.Foreperiods = r.Behavior.Foreperiods(1:n_press);
        r.Behavior.CueIndex = r.Behavior.CueIndex(1:n_press, :);

        r.Behavior.CorrectIndex = r.Behavior.CorrectIndex(r.Behavior.CorrectIndex <= n_press);
        r.Behavior.PrematureIndex = r.Behavior.PrematureIndex(r.Behavior.PrematureIndex <= n_press);
        r.Behavior.LateIndex = r.Behavior.LateIndex(r.Behavior.LateIndex <= n_press);
        r.Behavior.DarkIndex = r.Behavior.DarkIndex(r.Behavior.DarkIndex <= n_press);

        idx = find(r.Behavior.EventMarkers == find(strcmp(r.Behavior.Labels, 'LeverPress')), 1, 'last');
        r.Behavior.EventMarkers(idx) = [];
        r.Behavior.EventTimings(idx) = [];

        t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
        t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverRelease')));
        FPs = r.Behavior.Foreperiods;

        assert(length(t_press) == length(t_release));
        assert(length(t_press) == length(FPs));
    end
    

    %% Make video clips
    if isfield(r,'VideoInfos')
        r = rmfield(r, 'VideoInfos');
    end
    
    if isfield(r,'VideoInfos_top')
        r = rmfield(r, 'VideoInfos_top');
    end

    if isfield(r,'VideoInfos_side')
        r = rmfield(r, 'VideoInfos_side');
    end

    load(fullfile(folder_video, folder_this, 'timestamps.mat'));
    camview = 'top';
    
    ExtractFramesR(r, ts,...
        'events', 'Press', 'time_range', time_range_top, 'camview', camview,...
        'frame_rate', 100, 'frame_rate_out', 50, 'start_trial', 1, 'folder', fullfile(folder_video, folder_this));
    
    mat_dir = fullfile(folder_video, folder_this, ['./VideoFrames_',camview,'/MatFile']);
    output = dir([mat_dir,'/*.mat']);
    filenames = {output.name};
    filenames = sort(filenames);
    if strcmp(camview,'top')
        for k = 1:length(filenames)
            temp_filename = [mat_dir,'/',filenames{k}];
            load(temp_filename);
            r.VideoInfos_top(k) = VideoInfo;
        end
    elseif strcmp(camview,'side')
        for k = 1:length(filenames)
            temp_filename = [mat_dir,'/',filenames{k}];
            load(temp_filename);
            r.VideoInfos_side(k) = VideoInfo;
        end    
    end
    
    save(fullfile(folder_video, folder_this, 'RTarrayAll.mat'), 'r');
    % Make video clips
    load(fullfile(folder_video, folder_this, 'timestamps.mat'));
    camview = 'side';
    
    ExtractFramesR(r, ts,...
        'events', 'Press', 'time_range', time_range_side, 'camview', camview,...
        'frame_rate', 100, 'frame_rate_out', 50, 'start_trial', 1, 'folder', fullfile(folder_video, folder_this));
    
    mat_dir = fullfile(folder_video, folder_this, ['./VideoFrames_',camview,'/MatFile']);
    output = dir([mat_dir,'/*.mat']);
    filenames = {output.name};
    filenames = sort(filenames);
    if strcmp(camview,'top')
        for k = 1:length(filenames)
            temp_filename = [mat_dir,'/',filenames{k}];
            load(temp_filename);
            r.VideoInfos_top(k) = VideoInfo;
        end
    elseif strcmp(camview,'side')
        for k = 1:length(filenames)
            temp_filename = [mat_dir,'/',filenames{k}];
            load(temp_filename);
            r.VideoInfos_side(k) = VideoInfo;
        end    
    end

    %% make sure the indices are same in r
    idx_side = [r.VideoInfos_side.Index];
    idx_top = [r.VideoInfos_top.Index];

    [idx_same, idx_save_side, idx_save_top] = intersect(idx_side, idx_top);
    idx_diff_side = setdiff(idx_side, idx_same);
    idx_diff_top = setdiff(idx_top, idx_same);

    if ~isempty(idx_diff_side) || ~isempty(idx_diff_top)
        disp('Side videos are different with top videos!');
    end

    % side
    r.VideoInfos_side = r.VideoInfos_side(idx_save_side);
    r.VideoInfos_top = r.VideoInfos_top(idx_save_top);
    
    for k = 1:length(idx_diff_side)
        delete(fullfile(folder_video, folder_this, 'VideoFrames_side', 'RawVideo',...
            ['Press', num2str(idx_diff_side(k), '%03d'), '.avi']));
        delete(fullfile(folder_video, folder_this, 'VideoFrames_side', 'MatFile',...
            ['Press', num2str(idx_diff_side(k), '%03d'), '.mat']));
    end

    for k = 1:length(idx_diff_top)
        delete(fullfile(folder_video, folder_this, 'VideoFrames_top', 'RawVideo',...
            ['Press', num2str(idx_diff_top(k), '%03d'), '.avi']));
        delete(fullfile(folder_video, folder_this, 'VideoFrames_top', 'MatFile',...
            ['Press', num2str(idx_diff_top(k), '%03d'), '.mat']));
    end

    assert(all([r.VideoInfos_side.Index] == [r.VideoInfos_top.Index]));

    save(fullfile(folder_video, folder_this, 'RTarrayAll.mat'), 'r');
    fprintf('%s done!\n', folder_this);
end