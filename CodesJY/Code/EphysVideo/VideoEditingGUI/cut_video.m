function cut_video(path,x_pos,y_pos,threshold_type,threshold_input,frame_rate,sec_before,sec_after)
% path = path_jpg
load([path,'.mat'])
disp('开始剪切')
tic
if exist([path,'_cut'])
    disp('已存在剪切后的视频')
    return
end

% get filenames of all image
dir_output = dir(fullfile(path,'*.jpg'));

filenames = {dir_output.name};
filebytes = [dir_output.bytes];

% find background
bg = uint8(255*ones(x_pos(2)-x_pos(1)+1,y_pos(2)-y_pos(1)+1));
min_sum = sum(bg(:));
for k = 100:150
    img = imread([path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.jpg']);
    img = img(x_pos(1):x_pos(2),y_pos(1):y_pos(2));
    tmp_sum = sum(img(:));
    if tmp_sum < min_sum
        bg = img;
        min_sum = tmp_sum;
    end
end


% find if light is on
ison = zeros(length(filenames),1);
diff_img = zeros(length(filenames),1);

parfor k = (sec_before*100+1):(length(filenames)-2000)
        if exist([path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.jpg'],'file')
            img = imread([path,'/',path(end-16:end),'.',num2str(k,'%06d'),'.jpg']);
            img = img(x_pos(1):x_pos(2),y_pos(1):y_pos(2));
            tmp_diff = int32(img)-int32(bg);
            diff_img(k) = sum(tmp_diff(:));
        end
end

% set threshold
sort_diff = sort(diff_img,'Descend');
threshold = sort_diff(200)-1e5;

figure;
plot(diff_img)
hold on
yline(threshold);
pause(0);

if strcmp(threshold_type,'自动设定')
    threshold = threshold;
elseif strcmp(threshold_type,'手动设定')
    threshold = threshold_input;
else
    tmp_threshold = input('请输入阈值，输入0则继续，q则退出\n','s');
    disp(tmp_threshold);
    if ~strcmp(tmp_threshold,'0')
        if strcmp(tmp_threshold,'q')
            return
        else
            threshold = str2num(tmp_threshold);
        end
    end
end
save check_point
ison = (diff_img > threshold);

my_time = time;
new_path = [path,'_cut'];
mkdir(new_path);
video_range = -sec_before*100:1:sec_after*100;
parfor k = (sec_before*100+1):length(filenames)-sec_after*100
    % decide whether to make a video
    
    if ison(k) == 1 && ~any(ison(k-2:k-1)) && ~any(~ison(k+1:k+5))
        % make a video      
        idx_time = round(my_time(k));
        aviobj = VideoWriter([new_path,'/',path(end-16:end),'.',num2str(idx_time,'%06d'),'.avi']);
        aviobj.FrameRate = frame_rate;
        open(aviobj)
        for j = 1:length(video_range)
            idx = k+video_range(j);
            if exist([path,'/',path(end-16:end),'.',num2str(idx,'%06d'),'.jpg'],'file')
                writeVideo(aviobj,imread([path,'/',path(end-16:end),'.',num2str(idx,'%06d'),'.jpg']));
            end
        end
        close(aviobj);
    end
    
end
toc
end