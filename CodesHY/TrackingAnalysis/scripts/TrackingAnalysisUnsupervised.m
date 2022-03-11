%% Plot all trajectories
% set the parameters below
load RTarrayAll.mat
analysis_mode = 'both'; % pre / post / both
bodypart = 'right_ear';
bg_path = 'bg.png';
p_threshold = 0.95;
event = 'Press';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('Fig','dir')
    mkdir('Fig')
end
%% Do classification
ind_bodypart = find(strcmp(r.VideoInfos_top(1).Tracking.BodyParts, bodypart));
ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));
x_all = [];
y_all = [];
p_all = [];
for k = 1:length(ind_correct)
    x_all = [x_all,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_x{ind_bodypart}];
    y_all = [y_all,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_y{ind_bodypart}];
    p_all = [p_all,r.VideoInfos_top(ind_correct(k)).Tracking.Coordinates_p{ind_bodypart}];
end
x_all(p_all<p_threshold) = nan;
y_all(y_all<p_threshold) = nan;
%%
d_mat = zeros(length(ind_correct));
for k = 1:length(ind_correct)
    parfor j = k+1:length(ind_correct)
        d_mat(k,j) = trajDistance([x_all(:,k),y_all(:,k)],[x_all(:,j),y_all(:,j)]);
    end
end
for k = 1:length(ind_correct)
    for j = k+1:length(ind_correct)
        d_mat(j,k) = d_mat(k,j);
    end
end
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

[idx,C,~,d_all] = kmeans(Y,n_cluster,'Replicates',10,'MaxIter',2000);

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
%%
d_mat_sorted = zeros(length(ind_correct));
new_idx = [];
for k = 1:n_cluster+1
    new_idx = [new_idx,cluster_idx{k}];
end
for k = 1:length(ind_correct)
    for j = k+1:length(ind_correct)
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

for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    idx_good = find(r.VideoInfos_top(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold);

    plot(r.VideoInfos_top(ind_this).Tracking.Coordinates_x{ind_bodypart},r.VideoInfos_top(ind_this).Tracking.Coordinates_y{ind_bodypart},'.-','Color',colors(cat(k),:))
end   
saveas(gcf,'Fig/Traj_classification.png');
%% save to R
for k = 1:length(ind_correct)
    r.VideoInfos_top(ind_correct(k)).Trajectory = cat(k);
end
r.DistanceMatrix = d_mat;
save RTarrayAll.mat r
%% Draw Trajectories
for k = 1:n_cluster+1
    drawTraj(r,k);
end
%% Make Figures
for num_unit = 1:length(r.Units.SpikeTimes)
PlotComparingTrajPSTH(r,num_unit,'event',event);
close all
end
