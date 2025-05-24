function drawTraj(r, bodypart)

if nargin < 2
    bodypart = 'right_ear';
end

vid_dir = './VideoFrames_top/RawVideo/';
colors = {...
    {[62,84,172]/255,[191,172,226]/255},...
    {[179,0,94]/255,[255,95,158]/255},...
    {[189,205,214]/255,[238,233,218]/255},...
    {[0,128,0]/255,[141,182,0]/255},...
    {[255,162,0]/255,[155,107,25]/255}};
lineWidth = 0.2;

ind_bodypart = find(strcmp(r.VideoInfos_top(1).Tracking.BodyParts, bodypart));
p_threshold = 0.95;
N_traj = max([r.VideoInfos_top.Trajectory])-1;
idx_all = [r.VideoInfos_top.Index];
vid_idx = cell(1,N_traj+1);
for k = 1:length(vid_idx)
    vid_idx{k} = findSeq(idx_all, getIndexVideoInfos(r,"Trajectory",k));
end

bg = cell(N_traj+1,1);
for k = 1:length(bg)
    vid_obj = VideoReader(fullfile(vid_dir,['Press',num2str(r.VideoInfos_top(vid_idx{k}(1)).Index,'%03d'),'.avi']));
    bg{k} = vid_obj.read(round(-r.VideoInfos_top(vid_idx{k}(1)).t_pre/10));
end

traj_before = cell(1,N_traj+1);
traj_after = cell(1,N_traj+1);

for k = 1:length(r.VideoInfos_top)
    if isempty(r.VideoInfos_top(k).Trajectory)
        continue
    end
    x = r.VideoInfos_top(k).Tracking.Coordinates_x{ind_bodypart};
    y = r.VideoInfos_top(k).Tracking.Coordinates_y{ind_bodypart};
    p = r.VideoInfos_top(k).Tracking.Coordinates_p{ind_bodypart};
    frame_before = round(-r.VideoInfos_top(k).t_pre/10);
    frame_after = findNearestPoint(r.VideoInfos_top(k).VideoFrameTime,...
        r.VideoInfos_top(k).Time+r.VideoInfos_top(k).Foreperiod);

    idx_before = 1:frame_before;
    idx_before = idx_before(p(idx_before)>p_threshold);
    idx_after = frame_after:length(p);
    idx_after = idx_after(p(idx_after)>p_threshold);
    traj_before{r.VideoInfos_top(k).Trajectory}{end+1} = [x(idx_before),y(idx_before)];
    traj_after{r.VideoInfos_top(k).Trajectory}{end+1} = [x(idx_after),y(idx_after)];
end

fig = EasyPlot.figure();

ax_all = EasyPlot.createGridAxes(fig,3,N_traj+2,...
    'Height',3,...
    'Width',3,...
    'XAxisVisible','off',...
    'YAxisVisible','off',...
    'YTick',[],...
    'YDir','reverse');

for k = 1:3
    for j = 1:N_traj+2
        if k~=3
            if j==1
                image(ax_all{k,j}, bg{1});
                if k==1
                    for i = [N_traj+1, 1:N_traj]
                        [x_plot1, y_plot1] = getFlattenedTraj(traj_before{i});
                        plot(ax_all{k,j},x_plot1,y_plot1,'Color',colors{i}{1},'lineWidth',lineWidth);
                        [x_plot2, y_plot2] = getFlattenedTraj(traj_after{i});
                        plot(ax_all{k,j},x_plot2,y_plot2,'Color',colors{i}{2},'lineWidth',lineWidth);
                    end
                else
                    for i = [N_traj+1, 1:N_traj]
                        [x_plot, y_plot] = getFlattenedTraj(traj_before{i});
                        plot(ax_all{k,j},x_plot,y_plot,'Color',colors{i}{1},'lineWidth',lineWidth);
                    end
                end
            else
                image(ax_all{k,j}, bg{j-1});
                [x_plot, y_plot] = getFlattenedTraj(traj_before{j-1});
                plot(ax_all{k,j},x_plot,y_plot,'Color',colors{j-1}{1},'lineWidth',lineWidth);
            end
        end

        if k~=2
            if j==1
                if k~=1
                    image(ax_all{k,j}, bg{1});
                    for i = [N_traj+1, 1:N_traj]
                        [x_plot, y_plot] = getFlattenedTraj(traj_after{i});
                        plot(ax_all{k,j},x_plot,y_plot,'Color',colors{i}{2},'lineWidth',lineWidth);
                    end                    
                end
            else
                if k~=1
                    image(ax_all{k,j}, bg{j-1});
                end
                [x_plot, y_plot] = getFlattenedTraj(traj_after{j-1});
                plot(ax_all{k,j},x_plot,y_plot,'Color',colors{j-1}{2},'lineWidth',lineWidth);
            end
        end
    end
end

for k = 1:N_traj+2
    if k == 1
        title(ax_all{1,k},'Merge');
    elseif k == N_traj+2
        title(ax_all{1,k}, 'Unsorted')
    else
        title(ax_all{1,k}, ['Traj ',num2str(k-1)]);
    end
end

EasyPlot.setMargin(ax_all(:,1),'left',1);
EasyPlot.set(ax_all(:,1),'YAxisVisible','on');
ylabel(ax_all{1,1}, 'All');
ylabel(ax_all{2,1}, 'Before press');
ylabel(ax_all{3,1}, 'After trigger');

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig,['Fig/TrajClassification_',r.Meta(1).Subject,'_',datestr(r.Meta(1).DateTime,'yyyymmdd')]);
end

function [x_plot, y_plot] = getFlattenedTraj(traj)
    x_plot = [];
    y_plot = [];
    for k = 1:length(traj)
        x_plot = [x_plot, traj{k}(:,1)', NaN];
        y_plot = [y_plot, traj{k}(:,2)', NaN];
    end
end