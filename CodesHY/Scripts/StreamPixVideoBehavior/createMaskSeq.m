%% Get all filenames
dir_out = dir('./*.seq');
vid_filenames = {dir_out.name};

% sort by top/side and time
vid_filenames_top = {};
vid_filenames_side = {};
for k = 1:length(vid_filenames)
    for j = k+1:length(vid_filenames)
        if get_seq_time(vid_filenames{k}) > get_seq_time(vid_filenames{j})
            temp = vid_filenames{k};
            vid_filenames{k} = vid_filenames{j};
            vid_filenames{j} = temp;
        end
    end
end

for k = 1:length(vid_filenames)
    img = ReadJpegSEQ2(vid_filenames{k},1);
    if size(img, 1) == 530 ||  size(img, 1) == 704
        vid_filenames_top{end+1} = vid_filenames{k};
    elseif size(img, 1) == 800 || size(img, 1) == 900
        vid_filenames_side{end+1} = vid_filenames{k};
    else
        error('wrong video!');
    end
end

dir_out = dir('./*_Subject*.txt');
med_filename = dir_out.name;

ts = struct();
ts.topviews = vid_filenames_top;
ts.sideviews = vid_filenames_side;
ts.MedFilename = med_filename;

%% Extract timestamps
nFramesTop = zeros(1, length(ts.topviews));
nFramesSide = zeros(1, length(ts.sideviews));

for k = 1:length(ts.topviews)
    nFramesTop(k) = ReadFrameNumSEQ(ts.topviews{k});
end

for k = 1:length(ts.sideviews)
    nFramesSide(k) = ReadFrameNumSEQ(ts.sideviews{k});
end

ts.NframeTop = nFramesTop;
ts.NframeSide = nFramesSide;

%% check whether last mask is good 
if ~isnan(mask_last)
    figure;
    imshow(ReadJpegSEQ2(ts.sideviews{1},10000));
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

%% 
step_slow = 5;
step_fast = 100;
if ~isfield(ts, 'mask')
    k = 1;
    figure;
    while true
        imshow(ReadJpegSEQ2(ts.sideviews{1},k));
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
    save timestamps.mat ts
end


function t = get_seq_time(seqname)
% year = str2double(seqname(1:4));
% month = str2double(seqname(5:6));
% month = str2double(seqname(7:8));
hour = str2double(seqname(10:11));
min = str2double(seqname(13:14));
sec = str2double(seqname(16:17));
t = sec+60*min+60*60*hour;
end