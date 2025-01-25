%% Extract timestamps
load timestamps.mat
if ~isfield(ts, 'top') || ~isfield(ts, 'side')
    ts_top = struct('ts', [], 'skipind', []);
    for i = 1:length(ts.topviews)
        ts_top(i) = findts(ts.topviews{i});
    end
     
    ts_side = struct('ts', [], 'skipind', []);
    for i = 1:length(ts.sideviews)
        ts_side(i) = findts(ts.sideviews{i});
    end
    ts.top = ts_top;
    ts.side = ts_side;
    
    save timestamps ts;
end

%% Extract intensity
sample_interval = 20; % shorter than the LED-on duration

tic
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
toc
%% set threshold
% figure;
% plot(ts.intensity,'x-');
% xlabel('Frame number');
% ylabel('Intensity');
% disp('Please set the threshold')
% p = drawpoint();    
% yline(p.Position(2));
% ts.threshold = p.Position(2);

% top 10 intensity
temp = sort(ts.intensity(~isnan(ts.intensity)), 'descend');
th1 = mean(temp(1:10));
th2 = mode(round(temp));

ts.threshold = th2 + 0.8*(th1-th2);

%% refine the unsampled points
disp('Refining the unsampled points...');
count = 0;
for k = 1:length(ts.sideviews)
    for j = 1:length(ts.side(k).ts)
        count = count+1;
        if isnan(ts.intensity(count)) || ts.intensity(count)<ts.threshold
            continue
        end
        
        i = count-1;
        j_this = j-1;
        while i>0 && isnan(ts.intensity(i)) && j_this>0
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

save timestamps ts;
toc
%% Save the threshold figure
h = figure;
plot(ts.intensity, 'x-');
hold on;
yline(ts.threshold);
yline(th1); yline(th2);
xlabel('Frame number');
ylabel('Intensity');

print(h, 'Threshold.png', '-dpng', '-r600');
%% process med data
track_training_progress_advanced(ts.MedFilename);
dir_out = dir('B_*mat');
load(dir_out.name);

%% get trigger times from videos
trigger_times_start_idx = [];
flag = false;
for k = 1:length(ts.intensity)-21
    if all(ts.intensity(k:k+21)>ts.threshold)
        if ~flag
            trigger_times_start_idx = [trigger_times_start_idx, k];
        end
        flag = true;
    else
        flag = false;
    end
end
%%
t_side_all = [];
t_top_all = [];
for k = 1:length(ts.sideviews)
    t_side_all = [t_side_all, ts.side(k).ts+ReadTimestampSEQ(ts.sideviews{k},1)];
end

for k = 1:length(ts.topviews)
    t_top_all = [t_top_all, ts.top(k).ts+ReadTimestampSEQ(ts.topviews{k},1)];
end

trigger_times_start_vid = t_side_all(trigger_times_start_idx);
%% get trigger times from b
trigger_times = b.TimeTone*1000;

%% Align
if length(trigger_times_start_vid) > length(trigger_times)
    idx_match = findseqmatchHY(trigger_times_start_vid, trigger_times);
    trigger_times_start_vid = trigger_times_start_vid(idx_match);
    trigger_times_start_idx = trigger_times_start_idx(idx_match);
end

idx_out = findseqmatchHY(trigger_times, trigger_times_start_vid);

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

h = figure;
plot(time_diff ,'bx-')
hold on
plot(time_diff_corrected ,'ro-')

print(h, 'Alignment.png', '-dpng', '-r600');

ts.FrameTimesSide = frames_times_side;
ts.FrameTimesTop = frames_times_top;
save timestamps.mat ts;

close all;

function t = get_seq_time(seqname)
year = str2double(seqname(1:4));
month = str2double(seqname(5:6));
date = str2double(seqname(7:8));
hour = str2double(seqname(10:11));
min = str2double(seqname(13:14));
sec = str2double(seqname(16:17));
t = sec+60*min+60*60*hour+date*60*60*24+month*60*60*24*30+year*60*60*24*30*365;
end