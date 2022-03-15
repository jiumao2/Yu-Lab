%% Plot all trajectories
% set the parameters below
r_path = {'20210906_video/RTarrayAll.mat', ...
          '20210907_video/RTarrayAll.mat', ...
          '20210908_video/RTarrayAll.mat', ...
          '20210909_video/RTarrayAll.mat', ...
          '20210910_video/RTarrayAll.mat'};
analysis_mode = 'both'; % pre / post / both
bodypart = 'right_ear';
bg_path = '20210908_video/bg.png';
p_threshold = 0.99;
r_all_path = 'r_all_20210906_20210910.mat';
event = 'Press';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('Fig','dir')
    mkdir('Fig')
end
%% Do classification
x_all = [];
y_all = [];
r_traj_idx = {};
for path_id = 1:length(r_path)
    load(r_path{path_id});
    ind_bodypart = find(strcmp(r.VideoInfos_top(1).Tracking.BodyParts, bodypart));
    ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));
    ind_pre_press = 1:round(abs(r.VideoInfos_top(1).t_pre/10));
    ind_post_press = ind_pre_press(end)+1:r.VideoInfos_top(1).total_frames;
    
    if path_id == 1
        r_traj_idx{path_id} = 1:length(ind_correct);
    else
        r_traj_idx{path_id} = r_traj_idx{path_id-1}(end) + (1:length(ind_correct));
    end
    
    x_all_this = [];
    y_all_this = [];
    p_all_this = [];
    for k = 1:length(ind_correct)
        x_all_this = [x_all_this,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_x{ind_bodypart}];
        y_all_this = [y_all_this,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_y{ind_bodypart}];
        p_all_this = [p_all_this,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_p{ind_bodypart}];
    end
    x_all_this(p_all_this<p_threshold) = nan;
    y_all_this(p_all_this<p_threshold) = nan;
    x_all = [x_all, x_all_this];
    y_all = [y_all, y_all_this];
end
%%
d_mat = zeros(size(x_all,2));
for k = 1:length(d_mat)
    parfor j = k+1:length(d_mat)
        d_mat(k,j) = trajDistance([x_all(ind_pre_press,k),y_all(ind_pre_press,k)],[x_all(ind_pre_press,j),y_all(ind_pre_press,j)])...
            + trajDistance([x_all(ind_post_press,k),y_all(ind_post_press,k)],[x_all(ind_post_press,j),y_all(ind_post_press,j)]);
    end
    disp(k)
end
for k = 1:length(d_mat)
    for j = k+1:length(d_mat)
        d_mat(j,k) = d_mat(k,j);
    end
end
%%
figure;
imagesc(d_mat)
colorbar;
title('Unsorted Distance Matrix')
saveas(gcf,'Fig/UnsortedDistanceMatrix.png')
%%
Y = mdscale(d_mat,2);
close all
figure;
plot(Y(:,1),Y(:,2),'x')
n_cluster = 2;
n_cluster = input('Enter number of clusters:\n');

[idx,C,~,d_all] = kmeans(Y,n_cluster,'Replicates',100,'MaxIter',2000);

cluster_idx = cell(max(idx)+1,1);
for k = 1:n_cluster
    cluster_idx{k} = find(idx==k);
    d_all_this = d_all(cluster_idx{k});
    while true
        center_point = mean(Y(cluster_idx{k},:));
        d_all_this = sum((Y(cluster_idx{k},:)-center_point).^2,2);
        [b,idx_bad] = max(d_all_this);
        if b >= mean(d_all_this)+3*std(d_all_this)
            cluster_idx{n_cluster+1} = [cluster_idx{n_cluster+1};cluster_idx{k}(idx_bad)];
            cluster_idx{k}(idx_bad) = [];  
            d_all_this = d_all(cluster_idx{k});
        else
            break
        end
    end
end
cat = zeros(1,length(ind_correct));
for k = 1:n_cluster+1
    cat(cluster_idx{k}) = k;
end

figure;
colors = colororder;
colors(n_cluster+1,:) = [0.5,0.5,0.5];
for k = 1:n_cluster+1
    if k <= n_cluster
        plot(Y(cluster_idx{k},1),Y(cluster_idx{k},2),'x','Color',colors(k,:))
        hold on
    else
        plot(Y(cluster_idx{k},1),Y(cluster_idx{k},2),'k.');
    end
end
saveas(gcf,'Fig/Classification.png')
%
d_mat_sorted = zeros(size(d_mat));
new_idx = [];
for k = 1:n_cluster+1
    new_idx = [new_idx;cluster_idx{k}];
end
for k = 1:length(d_mat_sorted)
    for j = k+1:length(d_mat_sorted)
        d_mat_sorted(k,j) = d_mat(new_idx(k),new_idx(j));
        d_mat_sorted(j,k) = d_mat_sorted(k,j);
    end
end
figure;
imagesc(d_mat_sorted)
colorbar;
title('Sorted Distance Matrix')
saveas(gcf,'Fig/SortedDistanceMatrix.png')
%%
figure;
bg = imread(bg_path);
imshow(bg)
hold on
for path_id = 1:length(r_path) 
    load(r_path{path_id});
    cat_this = cat(r_traj_idx{path_id});
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    idx_good = find(r.VideoInfos_top(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold);

    plot(r.VideoInfos_top(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_good),r.VideoInfos_top(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_good),'.-','Color',colors(cat_this(k),:))
end   
end
saveas(gcf,'Fig/Traj_classification.png');
%% save to R
for path_id = 1:length(r_path)
load(r_path{path_id});
cat_this = cat(r_traj_idx{path_id});
ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));
for k = 1:length(ind_correct)
    r.VideoInfos_top(ind_correct(k)).Trajectory = cat_this(k);
end
temp_filename = ['TrackingAnalysis/',r_path{path_id}];
temp_dir = fileparts(temp_filename);
if ~exist(temp_dir,'dir')
    mkdir(temp_dir);
end
save(['TrackingAnalysis/',r_path{path_id}],'r');
end
load(r_all_path)
r_all.DistanceMatrix = d_mat;
save(r_all_path,'r_all')

%% Draw Trajectories
for k = 1:n_cluster+1
    drawTrajAll(r_path,k,bg_path);
end

%% Make Figures
load(r_all_path)
for k = 1:length(r_path)
    r_path{k} = ['TrackingAnalysis/',r_path{k}];
end
%%
for num_unit = 1:height(r_all.UnitsCombined)
    r_new = MergingR(r_path,r_all,'MergeIndex',r_all.UnitsCombined(num_unit,:).rIndex_RawChannel_Number{1}(:,1));
    PlotComparingTrajPSTH(r_new,num_unit,'event',event);
    close all
end

