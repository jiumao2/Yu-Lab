%% Meta Info
% r_path1 = 'D:\Ephys\ANMs\Urey\Videos\20211123_video\RTarrayAll.mat';
% r_path2 = 'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat';
% load('D:\Ephys\ANMs\Urey\Sessions\r_all_20211123_20211128.mat')
% r = MergingR({r_path1,r_path2},r_all,'MergeIndex',[1,2],'Wave',false);
r_path = 'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat';
load(r_path)
save_resolution = 1200;

% vid_side = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press056.avi');
% bg_side_traj1 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);
% vid_side = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press055.avi');
% bg_side_traj2 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);
vid_side = VideoReader('D:\Ephys\ANMs\Russo\Sessions\20210820_video\VideoFrames_side\RawVideo\Press056.avi');
bg_side_traj1 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);
vid_side = VideoReader('D:\Ephys\ANMs\Russo\Sessions\20210820_video\VideoFrames_side\RawVideo\Press055.avi');
bg_side_traj2 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);

bodypart = 'left_paw';
idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts,bodypart));

unit_num = 3; % 1,3,7
n_post_framenum = 0;
n_pre_framenum = 0;
binwidth = 1;
gaussian_kernel = 25;

marker_size = 50;
colors_num = 256;
colors = parula(256);

color_max_percentage = 1.00;
color_min_percentage = 0.00;
%%
h0 = figure('Renderer','opengl');
ax0 = axes(h0,'NextPlot','add');
image(ax0,bg_side_traj2);
set(ax0,'YDir','reverse','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)])
title(ax0,'All');
c0 = colorbar();
ylabel(c0,'Normalized firing rate','FontSize',10);
ax0.XAxis.Visible = 'off';ax0.YAxis.Visible = 'off';

idx_all = [r.VideoInfos_side.Index];
press_idx = getIndexVideoInfos(r,'Hand','Left','LiftStartTimeLabeled','On','Trajectory',1);
vid_press_idx = findSeq(idx_all,press_idx);

firing_rate_all_flattened = [];
firing_rate_all = cell(length(press_idx),1);
traj_all = cell(length(press_idx),1);
frame_num_all = zeros(1,length(press_idx));

firing_rate_threshold = -0.1;
[spike_counts, t_spike_counts] = bin_timings(r.Units.SpikeTimes(unit_num).timings, binwidth);
spike_counts_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000;
for k = 1:length(vid_press_idx)
    frame_num_temp = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum-n_pre_framenum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
    [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
    frame_num = frame_num_temp(1:i_maxy+n_post_framenum);
%     frame_num = frame_num_temp;
    frame_num_all(k) = length(frame_num);
    
    times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
    traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
        r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';
    
    firing_rate_this = getFiringRate_spike_train(spike_counts_all,t_spike_counts,times_this,binwidth);
    firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_this];
    firing_rate_all{k} = firing_rate_this;
end

mean_traj = getMeanTrajectory(traj_all, round(mean(frame_num_all)));

firing_rate_all_flattened = sort(firing_rate_all_flattened);
firing_rate_max = firing_rate_all_flattened(floor(length(firing_rate_all_flattened)*color_max_percentage));
firing_rate_min = firing_rate_all_flattened(ceil(length(firing_rate_all_flattened)*color_min_percentage)+1);

for k = 1:length(vid_press_idx)
    firing_rate_this = firing_rate_all{k};
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    s = scatter(ax0,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
        traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
    alpha(s,0.5);
end
% plot(ax0,mean_traj(1,:),mean_traj(2,:),'r.-','MarkerSize',20)
%% Confirming Lift-related cell
h_lift = figure('Renderer','opengl','Units','centimeters','Position',[10,10,8,4]);
ax_lift = axes(h_lift,'NextPlot','add','Units','centimeters','Position',[0.5,0.5,3,3]);
ax_press = axes(h_lift,'NextPlot','add','Units','centimeters','Position',[4.5,0.5,3,3]);
lift_times = [r.VideoInfos_side(vid_press_idx).LiftStartTime];
press_times = [r.VideoInfos_side(vid_press_idx).Time];
params_lift.pre = 1000;
params_lift.post = 1000;
params_lift.binwidth = 20;
params_press.pre = 2000;
params_press.post = 0;
params_press.binwidth = 20;
[psth_lift,t_psth_lift] = jpsth(r.Units.SpikeTimes(unit_num).timings,lift_times',params_lift);
[psth_press,t_psth_press] = jpsth(r.Units.SpikeTimes(unit_num).timings,press_times',params_press);
psth_lift = smoothdata(psth_lift,'gaussian',5);
psth_press = smoothdata(psth_press,'gaussian',5);
plot(ax_lift,t_psth_lift,psth_lift)
title(ax_lift,'Lift')
xlabel(ax_lift,'Time from lift (ms)')
plot(ax_press,t_psth_press,psth_press)
title(ax_press,'Press')
xlabel(ax_press,'Time from press (ms)')
ylim_max = max([ax_lift.YLim(2),ax_press.YLim(2)]);
ylim(ax_lift,[0,ylim_max]);ylim(ax_press,[0,ylim_max]);
%% Hypothesis 1: fire at a fixed duration from lift (same information as PETH)
h_h1 = figure('Renderer','opengl');
ax_h1 = axes(h_h1,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
title(ax_h1,'PETH')
image(ax_h1,bg_side_traj2);
set(ax_h1,'YDir','reverse')
ax_h1.XAxis.Visible = 'off';ax_h1.YAxis.Visible = 'off';
c_h1 = colorbar(ax_h1);
ylabel(c_h1,'Normalized firing rate','FontSize',10);

for k = 1:length(vid_press_idx)
    firing_rate_this = firing_rate_all{k};
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    s = scatter(ax_h1,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
        traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
    alpha(s,0.1);
end

firing_rate_all_mat = nan*zeros(length(firing_rate_all),round(mean(frame_num_all)));
for k = 1:length(firing_rate_all)
    if length(firing_rate_all{k})>round(mean(frame_num_all))
        firing_rate_all_mat(k,:) = firing_rate_all{k}(1:round(mean(frame_num_all)));
    else
        firing_rate_all_mat(k,1:length(firing_rate_all{k})) = firing_rate_all{k};
    end
end
firing_rate_all_mat_mean = mean(firing_rate_all_mat,'omitnan');
firing_rate_all_mat_mean = (firing_rate_all_mat_mean-firing_rate_min)./(firing_rate_max-firing_rate_min);
firing_rate_all_mat_mean(firing_rate_all_mat_mean>1)=1;firing_rate_all_mat_mean(firing_rate_all_mat_mean<0)=0;
scatter(ax_h1,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_mat_mean*(colors_num-1)+1),:),'filled');

disp(['Hypothesis 1: ',num2str(max(firing_rate_all_mat_mean))]);
%% Hypothesis 2: fire at a certain position (heat map)
h_h2 = figure('Renderer','opengl');
ax_h2 = axes(h_h2,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
image(ax_h2,bg_side_traj2);
title(ax_h2,'Position')
set(ax_h2,'YDir','reverse','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)])
ax_h2.XAxis.Visible = 'off';ax_h2.YAxis.Visible = 'off';
colorbar(ax_h2);
c_h2 = colorbar(ax_h2);
ylabel(c_h2,'Normalized firing rate','FontSize',10);

gaussian_kernel = 100;

h_h2_heatmap = figure('Renderer','opengl');
ax_h2_heatmap = axes(h_h2_heatmap,'NextPlot','add');
set(ax_h2_heatmap,'YDir','reverse')
ax_h2_heatmap.XAxis.Visible = 'off';ax_h2_heatmap.YAxis.Visible = 'off';
colorbar(ax_h2_heatmap,'Limits',[0,1]);
x = 1:5:904;
y = 1:5:800;
[X,Y] = meshgrid(x,y);
z = zeros(length(x),length(y));
for k = 1:length(x)
    for j = 1:length(y)
        z(k,j) = getGraphFiringRate(x(k),y(j),traj_all,firing_rate_all,gaussian_kernel);
    end
end
z = (z-firing_rate_min)./(firing_rate_max-firing_rate_min);
z(z>1)=1;z(z<0)=0;
imagesc(ax_h2_heatmap,z','XData',x,'YData',y);
ax_h2_heatmap.CLim = [0,1];

for k = 1:length(vid_press_idx)
    firing_rate_this = firing_rate_all{k};
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    s = scatter(ax_h2,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
        traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
    alpha(s,0.1)
end

firing_rate_pos = zeros(1,round(mean(frame_num_all)));
pos_length = zeros(1,round(mean(frame_num_all)));
% for k = 1:round(mean(frame_num_all))
%     firing_rate_pos(k) = getGraphFiringRate(mean_traj(1,k),mean_traj(2,k),traj_all,firing_rate_all,gaussian_kernel);
% end

firing_rate_pos_cell = cell(1,round(mean(frame_num_all)));
for k = 1:round(mean(frame_num_all))
    firing_rate_pos_cell{k} = [];
end
for k = 1:length(traj_all)
    for j = 1:length(traj_all{k})
        [~,idx] = min(sum((mean_traj-traj_all{k}(:,j)).^2));
        firing_rate_pos_cell{idx} = [firing_rate_pos_cell{idx},firing_rate_all{k}(j)];
    end
end
for k = 1:round(mean(frame_num_all))
    pos_length(k) = length(firing_rate_pos_cell{k});
    if isempty(firing_rate_pos_cell{k})
        firing_rate_pos(k) = firing_rate_pos(k-1);
    else
        firing_rate_pos(k) = mean(firing_rate_pos_cell{k});
    end
end

firing_rate_pos = (firing_rate_pos-firing_rate_min)./(firing_rate_max-firing_rate_min);
firing_rate_pos(firing_rate_pos>1)=1;firing_rate_pos(firing_rate_pos<0)=0;
scatter(ax_h2,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_pos*(colors_num-1)+1),:),'filled');   

h_h2_2 = figure();
ax_h2_2 = axes(h_h2_2,'NextPlot','add');
yyaxis(ax_h2_2,'left');
bar(ax_h2_2,pos_length);
ylabel('Number of points')
set(ax_h2_2,'ycolor','k');
yyaxis(ax_h2_2,'right');
plot(ax_h2_2,firing_rate_pos,'x-');
ylabel('Normalized firing rate');
set(ax_h2_2,'ycolor','k');

disp(['Hypothesis 2: ',num2str(max(firing_rate_pos))]);

% roi_pos = drawfreehand(ax_h2_heatmap);
% save roi_pos roi_pos
% 
% press_idx_1 = [];
% press_idx_2 = [];
% for k = 1:length(press_idx)
%     flag = true;
%     for j = 1:length(traj_all{k})
%         if roi_pos.inROI(traj_all{k}(1,j),traj_all{k}(2,j))
%             press_idx_1 = [press_idx_1,press_idx(k)];
%             flag = false;
%             break;
%         end
%     end
%     if flag
%         press_idx_2 = [press_idx_2,press_idx(k)];
%     end
% end
% 
% PlotComparing(r,unit_num,{press_idx_1,press_idx_2},{'In ROI', 'Not in ROI'},[],...
%     't_pre',-1000,...
%     't_post',500,...
%     'ntrial_raster',2,...
%     'video_path','D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\',...
%     'save_fig','off');
%% Hypothesis 3: fire at a percentage of trajectory (warped PETH)
h_h3 = figure('Renderer','opengl');
ax_h3 = axes(h_h3,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
colorbar(ax_h3);
c_h3 = colorbar(ax_h3);
ylabel(c_h3,'Normalized firing rate','FontSize',10);
image(ax_h3,bg_side_traj2);
title(ax_h3,'warped PETH')
set(ax_h3,'YDir','reverse')
ax_h3.XAxis.Visible = 'off';ax_h3.YAxis.Visible = 'off';

for k = 1:length(vid_press_idx)
    firing_rate_this = firing_rate_all{k};
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    s = scatter(ax_h3,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
        traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'filled');
    alpha(s,0.1)
end

[~, traj_all_resized, firing_rate_all_resized] = getMeanTrajectory(traj_all, round(mean(frame_num_all)), firing_rate_all);
firing_rate_all_resized_mean = mean(firing_rate_all_resized,2);    
    
firing_rate_all_resized_mean = (firing_rate_all_resized_mean-firing_rate_min)./(firing_rate_max-firing_rate_min);
firing_rate_all_resized_mean(firing_rate_all_resized_mean>1)=1;firing_rate_all_resized_mean(firing_rate_all_resized_mean<0)=0;
scatter(ax_h3,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_resized_mean*(colors_num-1)+1),:),'filled');    
disp(['Hypothesis 3: ',num2str(max(firing_rate_all_resized_mean))]);
%% Hypothesis 4: fire at a fixed duration from lift highest
h_h4 = figure('Renderer','opengl');
ax_h4 = axes(h_h4,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
title(ax_h4,'PETH')
image(ax_h4,bg_side_traj2);
set(ax_h4,'YDir','reverse')
ax_h4.XAxis.Visible = 'off';ax_h4.YAxis.Visible = 'off';
c_h4 = colorbar(ax_h4);
ylabel(c_h4,'Normalized firing rate','FontSize',10);

for k = 1:length(vid_press_idx)
    firing_rate_this = firing_rate_all{k};
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    s = scatter(ax_h4,traj_all{k}(1,firing_rate_this>firing_rate_threshold),...
        traj_all{k}(2,firing_rate_this>firing_rate_threshold),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'filled');  
    alpha(s,0.1);
end

firing_rate_all_mat2 = nan*zeros(length(firing_rate_all),round(mean(frame_num_all)));
for k = 1:length(firing_rate_all)
    if length(firing_rate_all{k})>round(mean(frame_num_all))
        firing_rate_all_mat2(k,:) = firing_rate_all{k}(end-round(mean(frame_num_all))+1:end);
    else
        firing_rate_all_mat2(k,end-length(firing_rate_all{k})+1:end) = firing_rate_all{k};
    end
end
firing_rate_all_mat_mean2 = mean(firing_rate_all_mat2,'omitnan');
firing_rate_all_mat_mean2 = (firing_rate_all_mat_mean2-firing_rate_min)./(firing_rate_max-firing_rate_min);
firing_rate_all_mat_mean2(firing_rate_all_mat_mean2>1)=1;firing_rate_all_mat_mean2(firing_rate_all_mat_mean2<0)=0;
scatter(ax_h1,mean_traj(1,:),mean_traj(2,:),marker_size/2,colors(round(firing_rate_all_mat_mean2*(colors_num-1)+1),:),'filled');

disp(['Hypothesis 4: ',num2str(max(firing_rate_all_mat_mean2))]);
%% Comparing
[max_h1,idx_max_h1] = max(firing_rate_all_mat_mean);
[max_h2,idx_max_h2] = max(firing_rate_pos);
[max_h3,idx_max_h3] = max(firing_rate_all_resized_mean);
[max_h4,idx_max_h4] = max(firing_rate_all_mat_mean2);
max_h1_points = firing_rate_all_mat(:,idx_max_h1);
max_h2_points = firing_rate_pos_cell{idx_max_h2};
max_h3_points = firing_rate_all_resized(idx_max_h3,:);
max_h4_points = firing_rate_all_mat2(:,idx_max_h4);
max_h1_points = (max_h1_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
max_h2_points = (max_h2_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
max_h3_points = (max_h3_points-firing_rate_min)./(firing_rate_max-firing_rate_min);
max_h4_points = (max_h4_points-firing_rate_min)./(firing_rate_max-firing_rate_min);

h_all = figure('Renderer','opengl','Units','centimeters','Position',[10,10,22,9]);
ax_all_fr = axes(h_all,'NextPlot','add','Units','centimeters','Position',[1,5,3,3]);
bar([max_h1,max_h2,max_h3,max_h4])
title(ax_all_fr,'Max firing rate');
ylim(ax_all_fr,[0,1]);
ylabel(ax_all_fr,'Normalized firing rate')
set(ax_all_fr,'XTick',[1,2,3],'XTickLabel',{'H1','H2','H3'})

ax_all_h1 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[5,1,3,3]);
histogram(ax_all_h1,max_h1_points,'BinWidth',0.1);
xlim([0,1])
title(ax_all_h1,'H1');

ax_all_h2 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[9,1,3,3]);
histogram(ax_all_h2,max_h2_points,'BinWidth',0.1);
xlim([0,1])
title(ax_all_h2,'H2');

ax_all_h3 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[13,1,3,3]);
histogram(ax_all_h3,max_h3_points,'BinWidth',0.1);
xlim([0,1])
title(ax_all_h3,'H3');

ax_all_h4 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[17,1,3,3]);
histogram(ax_all_h4,max_h4_points,'BinWidth',0.1);
xlim([0,1])
title(ax_all_h4,'H4');

ylim_max = max([ax_all_h1.YLim(2),ax_all_h2.YLim(2),ax_all_h3.YLim(2),ax_all_h4.YLim(2)]);
ylim(ax_all_h1,[0,ylim_max]);ylim(ax_all_h2,[0,ylim_max]);ylim(ax_all_h3,[0,ylim_max]);ylim(ax_all_h4,[0,ylim_max]);

ax_all_fr_h1 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[5,5,3,3]);
plot(10*(0:length(firing_rate_all_mat_mean)-1),firing_rate_all_mat_mean,'b-')
title(ax_all_fr_h1,'H1');

ax_all_fr_h2 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[9,5,3,3]);
plot(10*(0:length(firing_rate_pos)-1),firing_rate_pos,'b-')
title(ax_all_fr_h2,'H2');

ax_all_fr_h3 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[13,5,3,3]);
plot(10*(0:length(firing_rate_all_resized_mean)-1),firing_rate_all_resized_mean,'b-')
title(ax_all_fr_h3,'H3');

ax_all_fr_h4 = axes(h_all,'NextPlot','add','Units','centimeters','Position',[17,5,3,3]);
plot(10*(0:length(firing_rate_all_resized_mean)-1),firing_rate_all_resized_mean,'b-')
title(ax_all_fr_h4,'H4');

ylim_max = max([ax_all_fr_h1.YLim(2),ax_all_fr_h2.YLim(2),ax_all_fr_h3.YLim(2),ax_all_fr_h4.YLim(2)]);
ylim(ax_all_fr_h1,[0,ylim_max]);ylim(ax_all_fr_h2,[0,ylim_max]);ylim(ax_all_fr_h3,[0,ylim_max]);ylim(ax_all_fr_h4,[0,ylim_max]);
%% Save Figure
% print(h0,'traj_all','-dpng',['-r',num2str(save_resolution)])
% print(h_h1,'time','-dpng',['-r',num2str(save_resolution)])
% print(h_h2,'position','-dpng',['-r',num2str(save_resolution)])
% print(h_h2_heatmap,'position_heatmap','-dpng',['-r',num2str(save_resolution)])
% print(h_h2_2,'position_points_number','-dpng',['-r',num2str(save_resolution)])
% print(h_h3,'warped_time','-dpng',['-r',num2str(save_resolution)])
% print(h_h4,'comparison','-dpng',['-r',num2str(save_resolution)])

function firing_rate = getGraphFiringRate(x,y,traj_all,firing_rate_all,gaussian_kernel)
    traj_all_flattened = [];
    firing_rate_all_flattened = [];
    for k = 1:length(traj_all)
        traj_all_flattened = [traj_all_flattened,traj_all{k}];
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_all{k}];
    end
    
    gaussian_value = mvnpdf(traj_all_flattened',[x,y],gaussian_kernel*eye(2));
    gaussian_value(gaussian_value<1e-6) = 0;
    if sum(gaussian_value>0) <= 5
        gaussian_value(gaussian_value>0) = 0;
    end
    if sum(gaussian_value) < 1e-5
        firing_rate = 0;
    else
        firing_rate = dot(firing_rate_all_flattened,gaussian_value)./sum(gaussian_value);
    end
end