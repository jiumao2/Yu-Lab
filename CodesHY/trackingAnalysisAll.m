%% Plot all trajectories
% set the parameters below
r_path = {'20210906_video/RTarrayAll.mat', ...
          '20210907_video/RTarrayAll.mat', ...
          '20210908_video/RTarrayAll.mat', ...
          '20210909_video/RTarrayAll.mat', ...
          '20210910_video/RTarrayAll.mat'};
analysis_mode = 'both'; % pre / post / both
bg_path = '20210908_video/bg.png';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bg = imread(bg_path);      
h1 = figure;
ax1 = axes(h1);
imshow(bg);
title('Trajectories Before Press')
hold on

h2 = figure;
ax2 = axes(h2);
imshow(bg);
title('Trajectories Before Press')
hold on
for path_id = 1:length(r_path)
load(r_path{path_id})
bodypart = 'right_ear';
ind_bodypart = find(strcmp(r.VideoInfos(1).Tracking.BodyParts, bodypart));

p_threshold = 0.99;

idx_frame_pre = 1:abs(r.VideoInfos(1).t_pre/10);
idx_frame_post = abs(r.VideoInfos(1).t_pre/10)+1:r.VideoInfos(1).total_frames;

ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    idx_good = find(r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold);
    idx_pre = intersect(idx_good,idx_frame_pre);
    idx_post = intersect(idx_good,idx_frame_post);

    plot(ax1,r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_pre),r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_pre),'.-')
    plot(ax2,r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_post),r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_post),'.-')
end    

set(h1,'Renderer','opengl')
set(h2,'Renderer','opengl')
end
%% Do classification
% Make contraints in traj before press and traj after press respectively
colors = colororder;
trajectory = {};
count_traj = 0;
while true
    count_traj = count_traj+1;
    is_adding = input('Type 1 to add new trajectory. Type 0 to exit.\n');
    if ~is_adding
        break
    end

    trajectory{count_traj}{1} = {[0,0],[1,1]};
    trajectory{count_traj}{2} = {[0,0],[1,1]};

    if strcmp(analysis_mode,'both') || strcmp(analysis_mode,'pre')
        axes(ax1);
        [x,y] = ginput(2);
        plot(x,y,'-','LineWidth',5,'Color',colors(count_traj,:))

        trajectory{count_traj}{1} = {[x(1),y(1)],[x(2),y(2)]};
    end
    
    if strcmp(analysis_mode,'both') || strcmp(analysis_mode,'post')        
        axes(ax2);
        [x,y] = ginput(2);
        plot(x,y,'-','LineWidth',5,'Color',colors(count_traj,:))
        trajectory{count_traj}{2} = {[x(1),y(1)],[x(2),y(2)]};
    end

end
%% Use above constraints to classify the trajectories
colors = colororder;
colors(length(trajectory)+1,:) = [0.5,0.5,0.5];
figure;
set(gcf,'Renderer','opengl')
imshow(bg);
hold on
cat_all = cell(length(r_path),1);

for path_id = 1:length(r_path)
load(r_path{path_id})
ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
ind_bodypart = find(strcmp(r.VideoInfos(1).Tracking.BodyParts, bodypart));
idx_frame_pre = 1:abs(r.VideoInfos(1).t_pre/10);
idx_frame_post = abs(r.VideoInfos(1).t_pre/10)+1:r.VideoInfos(1).total_frames;
cat = [];

for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    hold on;
    
    idx_good = r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold;
    this_x = r.VideoInfos(ind_this).Tracking.Coordinates_x{ind_bodypart};
    this_y = r.VideoInfos(ind_this).Tracking.Coordinates_y{ind_bodypart};
    this_p = r.VideoInfos(ind_this).Tracking.Coordinates_p{ind_bodypart};
    
    flag = true;
    for i = 1:length(trajectory)
        if strcmp(analysis_mode,'pre')
            idx_pass = 2;
        elseif strcmp(analysis_mode,'post')
            idx_pass = 1;
        else
            idx_pass = [];
        end
        
        for j = 1:r.VideoInfos(1).total_frames-1
            for ii = 1:length(trajectory{i})
                if sum(idx_pass == ii)>0
                    continue;
                end
                if (ii==1 && j>=idx_frame_pre(end)) || (ii==2 && j<=idx_frame_pre(end))
                    continue;
                end
                if this_p(j)<p_threshold
                    continue;
                end                
                
                P1 = trajectory{i}{ii}{1};
                P2 = trajectory{i}{ii}{2};
                Q1 = [this_x(j),this_y(j)];
                count = 1;
                while j+count < r.VideoInfos(1).total_frames && this_p(j+count)<p_threshold
                    count = count + 1;
                end                
                Q2 = [this_x(j+count),this_y(j+count)];

                if ~isIntersect(P1,P2,Q1,Q2)
                    continue;
                else
                    idx_pass = [idx_pass,ii];
                    if length(idx_pass) == length(trajectory{i})
                        cat = [cat,i];
                        flag = false;
                        break;
                    end
                end
            end
            if ~flag
                break
            end
        end
        if ~flag
            break
        end
    end
    if flag
        cat = [cat,length(trajectory)+1];
    end
    hold on
    plot(this_x(idx_good),this_y(idx_good),'.-','Color',colors(cat(end),:));

end  
cat_all{path_id} = cat;
end
saveas(gcf,'Fig/Traj_classification.png');
%% save to R
for path_id = 1:length(r_path)
load(r_path{path_id});
ind_correct = find(strcmp({r.VideoInfos.Performance},'Correct'));
for k = 1:length(ind_correct)
    r.VideoInfos(ind_correct(k)).Trajectory = cat_all{path_id}(k);
end
temp_filename = ['TrackingAnalysis/',r_path{path_id}];
temp_dir = fileparts(temp_filename);
if ~exist(temp_dir,'dir')
    mkdir(temp_dir);
end
save(['TrackingAnalysis/',r_path{path_id}],'r');
end
%% Draw Trajectories
for k = 1:length(trajectory)+1
    drawTrajAll(r_path,k,bg_path);
end

%% Make Figures
load r_all_20210906_20210910.mat
for k = 1:length(r_path)
    r_path{k} = ['TrackingAnalysis/',r_path{k}];
end

for num_unit = 1:height(r_all.UnitsCombined)
    r_new = MergingR(r_path,r_all,'MergeIndex',r_all.UnitsCombined(num_unit,:).rIndex_RawChannel_Number{1}(:,1));
    PlotComparingTrajPSTH(r_new,num_unit,'event','Press');
end