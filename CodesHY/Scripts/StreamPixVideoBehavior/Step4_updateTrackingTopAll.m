%% get the target folders
folder_root = 'E:\Videos';
rat_names = {'Jalan', 'Jaya', 'Klang', 'Putra', 'Sunway'};
folder_data = {};

for k = 1:length(rat_names)
    dir_out = dir(fullfile(folder_root, rat_names{k}));
    folder_out = {dir_out.name};
    for j = 1:length(folder_out)
        if length(folder_out{j}) ~= 8
            continue
        end
        folder_data{end+1} = fullfile(folder_root, rat_names{k}, folder_out{j});
    end
end

%% load DLC info in each folder
for i_folder = 1:length(folder_data)
    folder_this = folder_data{i_folder};
    fprintf('Start processing %s ...\n', folder_this);

    load(fullfile(folder_this, 'timestamps.mat'));

    dir_out = dir(fullfile(folder_this, 'B_*.mat'));
    if isempty(dir_out) || length({dir_out.name}) > 1
        error(['B file error in ', folder_this]);
    end
    load(fullfile(folder_this, dir_out.name));

    folder_video = fullfile(folder_this, 'VideoFrames_top/RawVideo/');
    dir_out = dir(fullfile(folder_video, 'Press*.avi'));
    vid_filenames = {dir_out.name};
    
    folder_mat = fullfile(folder_this, 'VideoFrames_top/MatFile/');
    dir_out = dir(fullfile(folder_mat, 'Press*.mat'));
    mat_filenames = {dir_out.name};
    
    output_csv = dir(fullfile(folder_video, '/*.csv'));
    csv_filenames = sort({output_csv.name});

    if length(mat_filenames) ~= length(csv_filenames)
        error('The number of mat files and csv files do not match!');
    end
    
    VideoInfos = [];
    for n = 1:length(csv_filenames)
        [data,txt,~] = xlsread(fullfile(folder_video, csv_filenames{n}));
        bodyParts = cell(round((size(txt,2)-1)/3),1);
        coordinates_x = cell(length(bodyParts),1);
        coordinates_y = cell(length(bodyParts),1);
        coordinates_p = cell(length(bodyParts),1);
        for k = 1:length(bodyParts)
            bodyParts{k} = txt{2,3*k-1};
            coordinates_x{k} = data(:,3*k-1);
            coordinates_y{k} = data(:,3*k);
            coordinates_p{k} = data(:,3*k+1);
        end
    
        load(fullfile(folder_mat, mat_filenames{n}));
    
        Tracking.BodyParts = bodyParts;
        Tracking.Coordinates_x = coordinates_x;
        Tracking.Coordinates_y = coordinates_y;
        Tracking.Coordinates_p = coordinates_p;
        VideoInfo.Tracking = Tracking;
        
        save(fullfile(folder_mat, mat_filenames{n}), 'VideoInfo');
    
        if isempty(VideoInfos)
            VideoInfos = VideoInfo;
        else
            VideoInfos(n) = VideoInfo;
        end
        
        if mod(n, 10) == 1
            fprintf('%d / %d done!\n', n, length(csv_filenames));
        end
    end
    
    save(fullfile(folder_this, 'VideoInfos.mat'), 'VideoInfos');
    fprintf('Saved to VideoInfos.mat! %s done!\n', folder_this);
end

%% plot the tracking results for each session
for i_folder = 1:length(folder_data)
    folder_this = folder_data{i_folder};
    plotTracking(folder_this);
    close all;
end

