%% Extract intensity
load timestamps.mat

if exist('./FrameInfo.mat', 'file')
    load('./FrameInfo.mat');
    if isfield(FrameInfo, 'tFramesInB')
        ts.FrameTimes = FrameInfo.tFramesInB;
        save timestamps.mat ts;
        return
    end
end

sample_interval = 10; % shorter than the LED-on duration

n_frame = sum(ts.Nframe);
threshold = NaN;
intensity = nan(1,n_frame);

tic
for k = 1:length(ts.VidFilenames)
    disp(['Processing ', ts.VidFilenames{k}, '...']);
    vidObj = VideoReader(ts.VidFilenames{k});
    n_frames_done = sum(ts.Nframe(1:k-1));

    lenTiming = 100;
    parfor_progress(ceil(floor(ts.Nframe(k)/sample_interval)./lenTiming));
    temp_intensity = zeros(1, floor(ts.Nframe(k)/sample_interval));
    parfor j = 1:floor(ts.Nframe(k)/sample_interval)
        if rem(j, lenTiming)==0
            parfor_progress;
        end

        img = vidObj.read(j*sample_interval);
        temp_intensity(j) = mean(img(ts.mask));
    end
    intensity(n_frames_done+sample_interval*(1:length(temp_intensity))) = temp_intensity;
end

ts.intensity = intensity;
save timestamps ts;
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
tic
count = 0;
for k = 1:length(ts.VidFilenames)
    vidObj = VideoReader(ts.VidFilenames{k});

    idx_to_refine = [];
    idx_in_intensity = [];
    for j = 1:ts.Nframe(k)
        count = count+1;
        if isnan(ts.intensity(count)) || ts.intensity(count)<ts.threshold
            continue
        end
        
        i = count-1;
        j_this = j-1;
        while i>0 && isnan(ts.intensity(i)) && j_this>0
            idx_to_refine = [idx_to_refine, j_this];
            idx_in_intensity = [idx_in_intensity, i];
%             img = vidObj.read(j_this);
%             ts.intensity(i) = mean(img(ts.mask));
            i = i-1;
            j_this = j_this-1;
        end

        i = count+1;
        j_this = j+1;
        while isnan(ts.intensity(i)) && j_this<=ts.Nframe(k)
            idx_to_refine = [idx_to_refine, j_this];
            idx_in_intensity = [idx_in_intensity, i];
%             img = vidObj.read(j_this);
%             ts.intensity(i) = mean(img(ts.mask));
            i = i+1;
            j_this = j_this+1;
        end
    end

    intensity_refine = zeros(1, length(idx_to_refine));
    parfor j = 1:length(idx_to_refine)
        img = vidObj.read(idx_to_refine(j));
        intensity_refine(j) = mean(img(ts.mask));
    end
    ts.intensity(idx_in_intensity) = intensity_refine;

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
for k = 1:length(ts.intensity)-11
    if all(ts.intensity(k:k+11)>ts.threshold)
        if ~flag
            trigger_times_start_idx = [trigger_times_start_idx, k];
        end
        flag = true;
    else
        flag = false;
    end
end

trigger_times_start_vid = ts.Timestamps(trigger_times_start_idx);
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

frames_times_side = align_times(ts.Timestamps, time_maps);

time_diff_corrected = trigger_times(idx_out)-frames_times_side(trigger_times_start_idx);
time_diff_corrected = time_diff_corrected-time_diff_corrected(1);

h = figure;
plot(time_diff ,'bx-')
hold on
plot(time_diff_corrected ,'ro-')

print(h, 'Alignment.png', '-dpng', '-r600');

ts.FrameTimes = frames_times_side;
save timestamps.mat ts;

close all;
