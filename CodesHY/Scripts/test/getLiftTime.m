r_traj_all = {
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',      1,  1,  ... % r_path, # unit, # traj
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',      12, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     5,  1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     10, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     12, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     14, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     15, 1,  ...
    'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat',   3,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      4,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      5,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      6,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',      2,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',      5,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220512_video\RTarrayAll.mat',      1,  2,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       1,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       2,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       3,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       1,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       2,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       3,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       4,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       6,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',       4,  2,  ...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',       6,  2,  ...
};

n_post_framenum = 30;
n_pre_framenum = 30;
binwidth = 1;
gaussian_kernel = 25;
color_max_percentage = 1.00;
color_min_percentage = 0.00;
save_fig = 'off';
    
% mean y vs t
% align to the highest point

r_path = cell(round(length(r_traj_all)/3),1);
idx_unit = cell(round(length(r_traj_all)/3),1);
idx_traj = cell(round(length(r_traj_all)/3),1);
for k = 1:round(length(r_traj_all)/3)
    r_path{k} = r_traj_all{3*k-2};
    idx_unit{k} = r_traj_all{3*k-1};
    idx_traj{k} = r_traj_all{3*k};
end

load(r_path{1})
bodypart = 'left_paw';
idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts,bodypart));

X = zeros(210,3,1);
y = 0;
count = 1;
for idx_path = 1:length(r_path)
    if idx_path>1 && strcmp(r_path(idx_path),r_path(idx_path-1))
        continue
    end
    load(r_path{idx_path})
    press_indexes = getIndexVideoInfos(r,'Hand','Left','LiftStartTimeLabeled','On','Trajectory',idx_traj{idx_path});
    
    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes); 
    for k = 1:length(vid_press_idx)
        if count == 258
            disp(vid_press_idx(k))
            disp(r_path(idx_path))
        end
        X(:,1,count) = r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(1:210);
        X(:,2,count) = r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(1:210);
        X(:,3,count) = r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_p{idx_bodypart}(1:210);
        y(count) = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum;
        count = count+1;
    end
end
save testData X y
%% brute-force algorithm
clear;
load testData

thres1 = 2500;
thres2 = 200;
bias = 1;
movement_num = 4;
continue_num = 0;

y_predict = zeros(1,length(y));

for k = 1:length(y)
    X_this = X(:,1,k);
    Y_this = X(:,2,k);
    [X_this, Y_this] = filter_traj(X_this,Y_this);
    
    
    s_all = zeros(1,210);
    for j = 1+movement_num:210-movement_num
        s_all(j) = getMovement(X_this(j-movement_num:j+movement_num),Y_this(j-movement_num:j+movement_num));
    end

    flag = false;
    for j = 210:-1:1
        if ~flag && s_all(j)>thres1
            flag = true;
        end
        
        if flag && all(s_all(max(j-continue_num,1):j)<thres2)
            y_predict(k) = j+bias;
            break
        end
    end
    
%     figure;
%     if k == 258
%         plot(y(k)-50:210,s_all(y(k)-50:end),'b-')
%         hold on
%         plot(y(k),s_all(y(k)),'ro')
%         hold on
%         plot(y_predict(k),s_all(y_predict(k)),'go')
%         pause(0.5);
%     end
end

%
figure;
plot(y,'bx')
hold on
plot(y_predict,'ro')

figure;
err = y-y_predict;
plot(err,'x')

disp(mean(err.^2));
disp(std(err));

%%
function s = getMovement(X,Y)
%     s = (max(X)-min(X)).^2+(max(Y)-min(Y);
    s = sum((X-mean(X)).^2 + (Y-mean(Y)).^2,'all');
end

function [X_out,Y_out] = filter_traj(X,Y)
    for k = 2:length(X)-1
        p_mean = [X(k-1)*0.5+X(k+1)*0.5,Y(k-1)*0.5+Y(k+1)*0.5];
        if norm([X(k),Y(k)]-p_mean) >= norm(p_mean-[X(k-1),Y(k-1)])
            X(k) = p_mean(1);
            Y(k) = p_mean(2);
        end
    end
    X_out = X;
    Y_out = Y;
end

