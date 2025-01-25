rat_name = 'Pierce';
folder_video = './';
dir_output = dir(fullfile(folder_video, '*.seq'));

filenames = {dir_output.name};
sessions = cell(1, length(filenames));
for k = 1:length(filenames)
    sessions{k} = filenames{k}(1:8);
end

sessions = unique(sessions);

folder_data = sessions;

disp(folder_data)

%%
fr = 10;

for i_folder = 1:length(folder_data)
    folder_this = folder_data{i_folder};
%     r_file = fullfile(folder_r, folder_this, ['RTarray_', rat_name, '_', folder_this, '.mat']);
% 
%     if isempty(r_file, 'file')
%         continue
%     end
%     load(r_file);
    
    dir_out = dir(fullfile(folder_video, [folder_this, '-*.seq']));
    vid_filenames = {dir_out.name};
    % sort by top/side and time
    topviews = {};
    sideviews = {};
    for k = 1:length(vid_filenames)
        for j = k+1:length(vid_filenames)
            if get_seq_time(vid_filenames{k}) > get_seq_time(vid_filenames{j})
                temp = vid_filenames{k};
                vid_filenames{k} = vid_filenames{j};
                vid_filenames{j} = temp;
            end
        end
    end
    
    % check the angle is from top / side
    for k = 1:length(vid_filenames)
        img = ReadJpegSEQ2(fullfile(folder_video, vid_filenames{k}), 1);
        if size(img, 1) == 530 || size(img, 1) == 704 || size(img, 1) == 752
            topviews{end+1} = vid_filenames{k};
        elseif size(img, 1) == 800 || size(img, 1) == 900
            sideviews{end+1} = vid_filenames{k};
        else
            disp('wrong video!');
        end
    end
    
    clear ts;
    ts.topviews = topviews;
    ts.sideviews = sideviews;

    if isempty(topviews) || isempty(sideviews)
        fprintf('No videos found in %s!\n', folder_this);
        continue
    end
    
    folder_output = fullfile(folder_video, [folder_this, '_videos']);
    if ~exist(folder_output, 'dir')
        mkdir(folder_output);
    end
    
    save(fullfile(folder_output, 'timestamps.mat'), 'ts');
    
    disp('Sideviews:');
    disp(sideviews)
    disp('Topviews:');
    disp(topviews)
    %% get trigger times from videos
    load(fullfile(folder_output, 'timestamps.mat'));
%     step_slow = 5;
%     step_fast = 100;
%     if ~isfield(ts, 'mask')
%         k = 1;
%         figure;
%         while true
%             imshow(ReadJpegSEQ2(fullfile(folder_video, ts.sideviews{1}), k));
%             s = input(['Press "Enter" to check next ',...
%                 num2str(step_slow),...
%                 ' frame\nEnter "1" to check next ',...
%                 num2str(step_fast),...
%                 ' frameEnter "q" to quit\n'],'s');
%             if s == 'q'
%                 break
%             elseif s == '1'
%                 k = k+step_fast;
%             else
%                 k = k+step_slow;
%             end
%         end
%         
%         disp('Please draw ROI (the area of light)');
%         roi = drawfreehand;
%         mask = roi.createMask();
%         
%         close all;
%         ts.mask = mask;
%         save(fullfile(folder_output, 'timestamps.mat'), 'ts');
%     end
    
    % for box 7
    mask = zeros(size(ReadJpegSEQ2(fullfile(folder_video, ts.sideviews{1}), 1)), 'logical');
    mask(1:30, 1:30) = 1;
    ts.mask = mask;
    save(fullfile(folder_output, 'timestamps.mat'), 'ts');
end

function t = get_seq_time(seqname)
    year = str2double(seqname(1:4));
    month = str2double(seqname(5:6));
    date = str2double(seqname(7:8));
    hour = str2double(seqname(10:11));
    min = str2double(seqname(13:14));
    sec = str2double(seqname(16:17));
    t = sec+60*min+60*60*hour+date*60*60*24+month*60*60*24*30+year*60*60*24*30*365;
end