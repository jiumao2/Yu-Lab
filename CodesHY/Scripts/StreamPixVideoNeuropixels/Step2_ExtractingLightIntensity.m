rat_name = 'Pierce';
% folder_r = fullfile('../Sessions/');
folder_video = './';
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
    load(fullfile(folder_video, folder_this, 'timestamps.mat'));

    %% this is the function to extract time stamps from a seq file
    ts_top = struct('ts', [], 'skipind', []);
    for i = 1:length(ts.topviews)
        ts_top(i) = findts(fullfile(folder_video, ts.topviews{i}));
    end
     
    ts_side = struct('ts', [], 'skipind', []);
    for i = 1:length(ts.sideviews)
        ts_side(i) = findts(fullfile(folder_video, ts.sideviews{i}));
    end
    
    ts.top = ts_top;
    ts.side = ts_side;
    
    save(fullfile(folder_video, folder_this, 'timestamps.mat'), 'ts');
    
    % Extract intensity
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
    
                img = ReadJpegSEQ2(fullfile(folder_video, ts.sideviews{k}), j);
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
        save(fullfile(folder_video, folder_this, 'timestamps.mat'), 'ts');
    end
    %% set threshold
    % Manually set the threshold
    % figure;
    % plot(ts.intensity,'x-');
    % xlabel('Frame number');
    % ylabel('Intensity');
    % disp('Please set the threshold')
    % p = drawpoint();    
    % yline(p.Position(2));
    % ts.threshold = p.Position(2);
    
    % Automatically set the threshold
    temp = sort(ts.intensity(~isnan(ts.intensity)), 'descend');
    th1 = mean(temp(1:10));
    th2 = mode(round(temp));
    
    ts.threshold = th2 + 0.6*(th1-th2);
    
    % refine the unsampled points
    count = 0;
    for k = 1:length(ts.sideviews)
        for j = 1:length(ts.side(k).ts)
            count = count+1;
            if isnan(ts.intensity(count)) || ts.intensity(count)<ts.threshold
                continue
            end
            
            i = count-1;
            j_this = j-1;
            while isnan(ts.intensity(i)) && j_this>0
                img = ReadJpegSEQ2(fullfile(folder_video, ts.sideviews{k}), j_this);
                ts.intensity(i) = mean(img(ts.mask));
                i = i-1;
                j_this = j_this-1;
            end
    
            i = count+1;
            j_this = j+1;
            while isnan(ts.intensity(i)) && j_this<=length(ts.side(k).ts)
                img = ReadJpegSEQ2(fullfile(folder_video, ts.sideviews{k}), j_this);
                ts.intensity(i) = mean(img(ts.mask));
                i = i+1;
                j_this = j_this+1;
            end
        end
    end
    
    save(fullfile(folder_video, folder_this, 'timestamps.mat'), 'ts');
    %% Save the threshold figure
    h = figure;
    plot(ts.intensity, 'x-');
    hold on;
    yline(ts.threshold);
    yline(th1); yline(th2);
    xlabel('Frame number');
    ylabel('Intensity');
    
    print(h, fullfile(folder_video, folder_this, 'Threshold.png'), '-dpng', '-r600');

    close all;
end