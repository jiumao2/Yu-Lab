clear
load('RTarray_Max_20220721.mat')
fr = 10;
% there are filenames = { 'datafile001.ns6',  'datafile002.ns6',  'datafile003.ns6'};
topviews = {
    '20220721-18-40-35.000.seq' % session 001
    '20220721-19-20-20.000.seq' % session 002
    '20220721-20-27-38.000.seq' % session 003
    };
 
sideviews ={
    '20220721-18-40-46.000.seq' % session 001
    '20220721-19-20-17.000.seq' % session 002
    '20220721-20-27-26.000.seq' % session 003
    };
 
%% this is the function to extract time stamps from a seq file
ts_top = struct('ts', [], 'skipind', []);
for i = 1:length(topviews)
    ts_top(i) = findts(topviews{i});
end
 
ts_side = struct('ts', [], 'skipind', []);
for i = 1:length(sideviews)
    ts_side(i) = findts(sideviews{i});
end
clear ts
ts.top = ts_top;
ts.topviews = topviews;
ts.side = ts_side;
ts.sideviews = sideviews;

save timestamps ts

%% get trigger times from videos
load timestamps.mat
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
    save timestamps ts
end
%% Extract intensity
sample_interval = 20; % shorter than the LED-on duration

figure;
if ~isfield(ts, 'intensity')
    n_frame = 0;
    for k = 1:length(ts.sideviews)
        n_frame = n_frame+length(ts.side(k).ts);
    end
    threshold = NaN;
    intensity = nan(1,n_frame);
    count = 0;
    for k = 1:length(ts.sideviews)
        for j = 1:length(ts.side(k).ts)
            count = count+1;
            if mod(count, sample_interval)~=1
                continue
            end

            img = ReadJpegSEQ2(ts.sideviews{k},j);
            intensity(count) = mean(img(ts.mask));
            
            if mod(count, 1000) == 1
                disp([num2str(count), ' out of ', num2str(n_frame), ' frames have been extracted!']);
                cla;
                plot(intensity(1:count-1),'x-');
                drawnow;
            end
        end
    end
    
    ts.intensity = intensity;
    save timestamps ts
end
%% set threshold
figure;
plot(ts.intensity,'x-');
xlabel('Frame number');
ylabel('Intensity');
disp('Please set the threshold')
p = drawpoint();    
yline(p.Position(2));
threshold = p.Position(2);

% refine the unsampled points
count = 0;
for k = 1:length(ts.sideviews)
    for j = 1:length(ts.side(k).ts)
        count = count+1;
        if isnan(ts.intensity(count)) || ts.intensity(count)<threshold
            continue
        end
        
        i = count-1;
        j_this = j-1;
        while isnan(ts.intensity(i)) && j_this>0
            img = ReadJpegSEQ2(ts.sideviews{k},j_this);
            ts.intensity(i) = mean(img(ts.mask));
            i = i-1;
            j_this = j_this-1;
        end

        i = count+1;
        j_this = j+1;
        while isnan(ts.intensity(i)) && j_this<=length(ts.side(k).ts)
            img = ReadJpegSEQ2(ts.sideviews{k},j_this);
            ts.intensity(i) = mean(img(ts.mask));
            i = i+1;
            j_this = j_this+1;
        end
    end
end
    
%% get trigger times from videos
trigger_times_start_idx = [];
trigger_times_end_idx = [];
flag = false;
for k = 1:length(ts.intensity)-24
    if all(ts.intensity(k:k+24)>threshold)
        if ~flag
            trigger_times_start_idx = [trigger_times_start_idx, k];
        end
        flag = true;
    else
        if flag
            trigger_times_end_idx = [trigger_times_end_idx, k];
        end
        flag = false;
    end
end

t_side_all = [];
t_top_all = [];
for k = 1:length(ts.sideviews)
    t_side_all = [t_side_all, ts.side(k).ts+ReadTimestampSEQ(ts.sideviews{k},1)];
    t_top_all = [t_top_all, ts.top(k).ts+ReadTimestampSEQ(ts.topviews{k},1)];
end

trigger_times_start_vid = t_side_all(trigger_times_start_idx);
trigger_times_end_vid = t_side_all(trigger_times_end_idx);

% %% Some points might be removed manually
% idx_remove = findNearestPoint(trigger_times_start_vid, trigger_times_start_vid(1)+2304610);
% idx_remove = [1,2];
% trigger_times_start_vid(idx_remove) = [];
% trigger_times_start_idx(idx_remove) = [];
%% get trigger times from r
press_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
FPs = r.Behavior.Foreperiods;

% deal with problems of shape
if size(press_times,1)~=1
    press_times = press_times';
end
if size(FPs,1)~=1
    FPs = FPs';
end

trigger_times = press_times + FPs;
trigger_times = trigger_times(sort([r.Behavior.CorrectIndex,r.Behavior.LateIndex]));
%%  
idx_out = findseqmatch(trigger_times,trigger_times_start_vid);

figure;
plot(trigger_times-trigger_times(idx_out(1)),2, 'ro')
hold on
plot(trigger_times_start_vid-trigger_times_start_vid(1),1,'bx');
for k = 1:length(idx_out)
    plot([trigger_times_start_vid(k)-trigger_times_start_vid(1),...
        trigger_times(idx_out(k))-trigger_times(idx_out(1))],...
        [1,2], 'k-');
end

time_maps = [trigger_times(idx_out);trigger_times_start_vid];

time_diff = trigger_times(idx_out)-trigger_times_start_vid;
time_diff = time_diff-time_diff(1);

frames_times_side = align_times(t_side_all, time_maps);
frames_times_top = align_times(t_top_all, time_maps);

time_diff_corrected = trigger_times(idx_out)-frames_times_side(trigger_times_start_idx);
time_diff_corrected = time_diff_corrected-time_diff_corrected(1);

figure;
plot(time_diff ,'bx-')
hold on
plot(time_diff_corrected ,'ro-')

%% save to r
r.Video.t_frameon_side = frames_times_side;
r.Video.t_frameon_top = frames_times_top;
save RTarrayAll.mat r

%% Check minimum of frame intervals
frame_intervals_top = diff(frames_times_top);
frame_intervals_top = sort(frame_intervals_top, 'descend');
disp('Top frame intervals in top-view videos:')
disp(frame_intervals_top(frame_intervals_top>1000));
disp();

frame_intervals_side = diff(frames_times_side);
frame_intervals_side = sort(frame_intervals_side, 'descend');
disp('Frame intervals that is higher than 1000 in top-view videos:')
disp(frame_intervals_side(frame_intervals_side>1000));
disp();

% if the number is not equal to num_segment-1, the min_frame_interval below should be modified

%% Make video clips
load timestamps.mat
camview = 'top';
if isfield(r,'VideoInfos')
    r = rmfield(r,'VideoInfos');
end

ExtractEventFrameSignalVideo(r, ts, [], 'events', 'Press', 'time_range', [2100 2400], 'makemov', 1, 'camview', camview,...
    'make_video_with_spikes',false,'sort_by_unit',true,'frame_rate',10,'start_trial',1,'min_frame_interval',1000);

mat_dir = ['./VideoFrames_',camview,'/MatFile'];
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

save('RTarrayAll.mat','r')
% Make video clips
load timestamps.mat
camview = 'side';
if isfield(r,'VideoInfos')
    r = rmfield(r,'VideoInfos');
end

ExtractEventFrameSignalVideo(r, ts, [], 'events', 'Press', 'time_range', [2100 2400], 'makemov', 1, 'camview', camview,...
    'make_video_with_spikes',false,'sort_by_unit',true,'frame_rate',10,'start_trial',1,'min_frame_interval',1000);

mat_dir = ['./VideoFrames_',camview,'/MatFile'];
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

save('RTarrayAll.mat','r')