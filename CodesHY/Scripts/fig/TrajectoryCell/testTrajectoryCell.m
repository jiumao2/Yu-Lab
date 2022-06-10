%% Meta Info
% r_path = 'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat';
r_path = 'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat';
% load(r_path)

% save_filename_bmp = './fig.bmp';
save_filename_pdf = './GestureAnalysis.pdf';
save_filename_png = './GestureAnalysis.png';
save_filename_eps = 'C:\Users\jiumao\Desktop\figuresHY\GestureAnalysis.eps';
save_resolution = 1200;

% vid_top = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_top\RawVideo\Press007.avi');
% bg_top = vid_top.read(-r.VideoInfos_top(1).t_pre/10);
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

unit_num = 3;
binwidth = 50;

marker_size = 200;
colors_num = 256;
colors = parula(256);

color_max_percentage = 0.95;
color_min_percentage = 0.00;
%%
h0 = figure('Renderer','opengl');
ax0 = axes(h0,'NextPlot','add');
image(ax0,bg_side_traj2);
set(ax0,'YDir','reverse','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)])
title(ax0,'All');
colorbar();
ax0.XAxis.Visible = 'off';ax0.YAxis.Visible = 'off';

% h1 = figure;
% ax1 = axes(h1,'NextPlot','add');
% image(ax1,bg_side_traj2);
% set(ax1,'YDir','reverse')
% ax1.XAxis.Visible = 'off';ax1.YAxis.Visible = 'off';
% title(ax1,'High');
% 
% h2 = figure;
% ax2 = axes(h2,'NextPlot','add');
% image(ax2,bg_side_traj2);
% set(ax2,'YDir','reverse')
% ax2.XAxis.Visible = 'off';ax2.YAxis.Visible = 'off';
% title(ax2,'Low');

idx_all = [r.VideoInfos_side.Index];
press_idx = getIndexVideoInfos(r,'Hand','Left','LiftStartTimeLabeled','On');
vid_press_idx = findSeq(idx_all,press_idx);

firing_rate_all_flattened = [];
firing_rate_all = cell(length(press_idx),1);
traj_all = cell(length(press_idx),1);
frame_num_all = zeros(1,length(press_idx));

firing_rate_threshold = -0.1;
for k = 1:length(vid_press_idx)
    frame_num_temp = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
    [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp(10:end)));
    frame_num = frame_num_temp(1:i_maxy+10);
%     frame_num = frame_num_temp;
    frame_num_all(k) = length(frame_num);
    
    times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
    traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
        r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';
    firing_rate_this = getFiringRate(r.Units.SpikeTimes(unit_num).timings,times_this,binwidth);
    firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_this];
    firing_rate_all{k} = firing_rate_this;
end

mean_traj = getMeanTrajectory(traj_all, round(mean(frame_num_all)));
plot(ax0,mean_traj(1,:),mean_traj(2,:),'o-','MarkerSize',10)

firing_rate_all_flattened = sort(firing_rate_all_flattened);
firing_rate_max = firing_rate_all_flattened(floor(length(firing_rate_all_flattened)*color_max_percentage));
firing_rate_min = firing_rate_all_flattened(ceil(length(firing_rate_all_flattened)*color_min_percentage)+1);

for k = 1:length(vid_press_idx)
    frame_num_temp = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
    [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
    frame_num = frame_num_temp(1:i_maxy);
%     frame_num = frame_num_temp;
    
    times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
    firing_rate_this = getFiringRate(r.Units.SpikeTimes(unit_num).timings,times_this,binwidth);
    firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
    firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
    colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
    scatter(ax0,r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num(firing_rate_this>firing_rate_threshold)),...
        r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num(firing_rate_this>firing_rate_threshold)),...
        marker_size,...
        colors_this(firing_rate_this>firing_rate_threshold,:),'.');
    
%     if mean(firing_rate_this)>0.2
%         scatter(ax1,r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
%             r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num),...
%             marker_size,...
%             colors_this,'.');      
%     else
%         scatter(ax2,r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
%             r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num),...
%             marker_size,...
%             colors_this,'.');  
%     end
    
end

%% Hypothesis 1: fire at a fixed duration from lift (same information as PETH)
h_h1 = figure('Renderer','opengl');
% ax_h1 = axes(h_h1);
% params.pre = 500;
% params.post = 2000;
% params.binwidth = binwidth;
% [psth, tpsth] = jpsth(r.Units.SpikeTimes(unit_num).timings,[r.VideoInfos_side(vid_press_idx).LiftStartTime]',params);
% plot(ax_h1,tpsth,psth,'-')

ax_h1_2 = axes(h_h1,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
title(ax_h1_2,'PETH')
image(ax_h1_2,bg_side_traj2);
set(ax_h1_2,'YDir','reverse')
ax_h1_2.XAxis.Visible = 'off';ax_h1_2.YAxis.Visible = 'off';
colorbar(ax_h1_2);

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
scatter(ax_h1_2,mean_traj(1,:),mean_traj(2,:),500,colors(round(firing_rate_all_mat_mean*(colors_num-1)+1),:),'.');

disp(['Hypothesis 1: ',num2str(max(firing_rate_all_mat_mean))]);
%% Hypothesis 2: fire at a certain position (heat map)
h_h2 = figure('Renderer','opengl');
ax_h2 = axes(h_h2,'NextPlot','add','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)]);
image(ax_h2,bg_side_traj2);
title(ax_h2,'Position')
set(ax_h2,'YDir','reverse','XLim',[0,size(bg_side_traj2,2)],'YLim',[0,size(bg_side_traj2,1)])
ax_h2.XAxis.Visible = 'off';ax_h2.YAxis.Visible = 'off';
colorbar(ax_h2);

gaussian_kernel = 25;

h_h2_heatmap = figure('Renderer','opengl');
ax_h2_heatmap = axes(h_h2_heatmap,'NextPlot','add');
colorbar(ax_h2_heatmap);
set(ax_h2_heatmap,'YDir','reverse')
ax_h2_heatmap.XAxis.Visible = 'off';ax_h2_heatmap.YAxis.Visible = 'off';
x = 1:5:904;
y = 1:5:800;
[X,Y] = meshgrid(x,y);
z = zeros(length(x),length(y));
for k = 1:length(x)
    for j = 1:length(y)
        z(k,j) = getGraphFiringRate(x(k),y(j),traj_all,firing_rate_all,gaussian_kernel);
    end
end
imagesc(ax_h2_heatmap,z','XData',x,'YData',y);

firing_rate_pos = zeros(1,round(mean(frame_num_all)));
for k = 1:round(mean(frame_num_all))
    firing_rate_pos(k) = getGraphFiringRate(mean_traj(1,k),mean_traj(2,k),traj_all,firing_rate_all,gaussian_kernel);
end
firing_rate_pos = (firing_rate_pos-firing_rate_min)./(firing_rate_max-firing_rate_min);
firing_rate_pos(firing_rate_pos>1)=1;firing_rate_pos(firing_rate_pos<0)=0;
scatter(ax_h2,mean_traj(1,:),mean_traj(2,:),500,colors(round(firing_rate_pos*(colors_num-1)+1),:),'.');    
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
image(ax_h3,bg_side_traj2);
title(ax_h3,'warped PETH')
set(ax_h3,'YDir','reverse')
ax_h3.XAxis.Visible = 'off';ax_h3.YAxis.Visible = 'off';

% for k = 1:length(vid_press_idx)
%     frame_num = r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum:round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10);
%     times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
%     firing_rate_this = getFiringRate(r.Units.SpikeTimes(unit_num).timings,times_this,binwidth);
%     firing_rate_this = (firing_rate_this-firing_rate_min)./(firing_rate_max-firing_rate_min);
%     firing_rate_this(firing_rate_this>1)=1;firing_rate_this(firing_rate_this<0)=0;
%     colors_this = colors(round(firing_rate_this*(colors_num-1)+1),:);
%     scatter(ax_h3,r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
%         r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num),...
%         marker_size,...
%         colors_this,'.');
% end

[~, traj_all_resized, firing_rate_all_resized] = getMeanTrajectory(traj_all, round(mean(frame_num_all)), firing_rate_all);
firing_rate_all_resized_mean = mean(firing_rate_all_resized,2);    
    
firing_rate_all_resized_mean = (firing_rate_all_resized_mean-firing_rate_min)./(firing_rate_max-firing_rate_min);
scatter(ax_h3,mean_traj(1,:),mean_traj(2,:),500,colors(round(firing_rate_all_resized_mean*(colors_num-1)+1),:),'.');    
disp(['Hypothesis 3: ',num2str(max(firing_rate_all_resized_mean))]);
%% Save Figure
% print(h0,'traj_all','-dpng',['-r',num2str(save_resolution)])
% print(h_h1,'time','-dpng',['-r',num2str(save_resolution)])
% print(h_h2,'position','-dpng',['-r',num2str(save_resolution)])
% print(h_h2_heatmap,'position_heatmap','-dpng',['-r',num2str(save_resolution)])
% print(h_h3,'warped_time','-dpng',['-r',num2str(save_resolution)])

% print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])
% print(h,save_filename_eps,'-depsc',['-r',num2str(save_resolution)])


function firing_rate = getGraphFiringRate(x,y,traj_all,firing_rate_all,gaussian_kernel)
    traj_all_flattened = [];
    firing_rate_all_flattened = [];
    for k = 1:length(traj_all)
        traj_all_flattened = [traj_all_flattened,traj_all{k}];
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_all{k}];
    end
    
    gaussian_value = mvnpdf(traj_all_flattened',[x,y],gaussian_kernel*eye(2));
    gaussian_value(gaussian_value<1e-6) = 0;
    if sum(gaussian_value) < 1e-5
        firing_rate = 0;
    else
        firing_rate = dot(firing_rate_all_flattened,gaussian_value)./sum(gaussian_value);
    end
end