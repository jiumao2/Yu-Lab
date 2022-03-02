%% Plot all trajectories
% set the parameters below
load RTarrayAll.mat
analysis_mode = 'both'; % pre / post / both
bodypart = 'right_ear';
bg_path = 'bg.png';
p_threshold = 0.95;
event = 'Press';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ind_bodypart = find(strcmp(r.VideoInfos_top(1).Tracking.BodyParts, bodypart));
bg = imread(bg_path);
h1 = figure;
ax1 = axes(h1);
imshow(bg);
title('Trajectories Before Press')
hold on

h2 = figure;
ax2 = axes(h2);
imshow(bg);
title('Trajectories After Press')
hold on

idx_frame_pre = 1:abs(r.VideoInfos_top(1).t_pre/10);
idx_frame_post = abs(r.VideoInfos_top(1).t_pre/10)+1:r.VideoInfos_top(1).total_frames;

ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    idx_good = find(r.VideoInfos_top(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold);
    idx_pre = intersect(idx_good,idx_frame_pre);
    idx_post = intersect(idx_good,idx_frame_post);

    plot(ax1,r.VideoInfos_top(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_pre),r.VideoInfos_top(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_pre),'.-')
    plot(ax2,r.VideoInfos_top(ind_this).Tracking.Coordinates_x{ind_bodypart}(idx_post),r.VideoInfos_top(ind_this).Tracking.Coordinates_y{ind_bodypart}(idx_post),'.-')
end    

set(h1,'Renderer','opengl')
set(h2,'Renderer','opengl')
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
imshow(bg);
hold on

cat = [];
for k = 1:length(ind_correct)
    ind_this = ind_correct(k);
    hold on;
    
    idx_good = r.VideoInfos_top(ind_this).Tracking.Coordinates_p{ind_bodypart} > p_threshold;
    this_x = r.VideoInfos_top(ind_this).Tracking.Coordinates_x{ind_bodypart};
    this_y = r.VideoInfos_top(ind_this).Tracking.Coordinates_y{ind_bodypart};
    this_p = r.VideoInfos_top(ind_this).Tracking.Coordinates_p{ind_bodypart};
    
    flag = true;
    for i = 1:length(trajectory)
        if strcmp(analysis_mode,'pre')
            idx_pass = 2;
        elseif strcmp(analysis_mode,'post')
            idx_pass = 1;
        else
            idx_pass = [];
        end
        
        for j = 1:r.VideoInfos_top(1).total_frames-1
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
                while j+count < r.VideoInfos_top(1).total_frames && this_p(j+count)<p_threshold
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
if ~exist('Fig','dir')
    mkdir('Fig')
end
saveas(gcf,'Fig/Traj_classification.png');
%% save to R
for k = 1:length(ind_correct)
    r.VideoInfos_top(ind_correct(k)).Trajectory = cat(k);
end
r.TrajectoryConstraints = trajectory;
save RTarrayAll.mat r
%% Draw Trajectories
for k = 1:length(trajectory)+1
    drawTraj(r,k);
end
%% Make Figures
for num_unit = 1:length(r.Units.SpikeTimes)
PlotComparingTrajPSTH(r,num_unit,'event',event);
close all
end
