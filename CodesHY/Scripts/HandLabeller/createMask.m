%% Get all filenames
dir_out = dir('./*.avi');
vid_filenames = {dir_out.name};

% sort by file length
for k = 1:length(vid_filenames)
    for j = k+1:length(vid_filenames)
        if length(vid_filenames{k}) > length(vid_filenames{j})
            temp = vid_filenames{k};
            vid_filenames{k} = vid_filenames{j};
            vid_filenames{j} = temp;
        end
    end
end

txt_filenames = cell(1, length(vid_filenames));
for k = 1:length(txt_filenames)
    txt_filenames{k} = [vid_filenames{k}(1:end-3), 'txt'];
end

dir_out = dir('./*_Subject*.txt');
med_filename = dir_out.name;

ts = struct();
ts.VidFilenames = vid_filenames;
ts.TxtFilenames = txt_filenames;
ts.MedFilename = med_filename;

%% Extract timestamps
nFrames = zeros(1, length(ts.VidFilenames));
for k = 1:length(ts.VidFilenames)
    vidObj = VideoReader(ts.VidFilenames{k});
    nFrames(k) = vidObj.NumFrames;
end

timestamps = [];
for k = 1:length(ts.TxtFilenames)
    temp = readmatrix(ts.TxtFilenames{k});
    idx_zero = find(temp==0, 1);
    temp = temp(1:idx_zero-1);
    if length(temp) ~= nFrames(k)
        sprintf('%s have %d frames; %s have %d frames', ts.VidFilenames{k}, nFrames(k), ts.TxtFilenames{k}, length(temp));
    end
    if size(temp, 1) ~= 1
        temp = temp';
    end
    timestamps = [timestamps, temp];
end

timestamps = timestamps - timestamps(1);
ts.Timestamps = timestamps;
ts.Nframe = nFrames;

%% check whether last mask is good 
if ~isnan(mask_last)
    figure;
    vidObj = VideoReader(ts.VidFilenames{1});
    imshow(vidObj.read(1));
    hold on

    x_plot = [];
    y_plot = [];
    for k = 1:size(mask_last, 1)
        for j = 1:size(mask_last, 2)
            if mask_last(k, j)
                x_plot = [x_plot, j];
                y_plot = [y_plot, k];
            end
        end
    end
    plot(x_plot, y_plot, 'r.');
    while true
        s = input('Press 1 to confirm this ROI; Press 0 to manually label the ROI\n','s');
        if s == '1'
            close all;
            ts.mask = mask_last;
            save timestamps ts;
            return
        elseif s == '0'
            break
        end
    end
end


%% Create the mask
step_slow = 5;
step_fast = 100;
if ~isfield(ts, 'mask')
    k = 1;
    figure;
    while true
        vidObj = VideoReader(ts.VidFilenames{1});
        imshow(vidObj.read(k));
        s = input(['Press "Enter" to check next ',...
            num2str(step_slow),...
            ' frame\nEnter "1" to check next ',...
            num2str(step_fast),...
            ' frameEnter "q" to quit\n'],'s');
        if s == 'q'
            break
        elseif s == '1'
            k = k+step_fast;
        else
            k = k+step_slow;
        end
    end
    
    disp('Please draw ROI (the area of light)');
    roi = drawfreehand;
    mask = roi.createMask();
    
    close all;
    ts.mask = mask;
    save timestamps ts;
end

disp(ts)