%% Meta Info
r_path = 'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat';
load(r_path)

save_filename_bmp = './fig.bmp';
save_filename_pdf = './fig.pdf';
save_filename_png = './fig.png';
save_resolution = 1200;

vid_top = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_top\RawVideo\Press007.avi');
bg_top = vid_top.read(-r.VideoInfos_top(1).t_pre/10);
vid_side = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press056.avi');
bg_side_traj1 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);
vid_side = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press055.avi');
bg_side_traj2 = vid_side.read(-r.VideoInfos_top(1).t_pre/10);

bodypart_top = 'right_ear';
bodypart_side = 'left_paw';
p_threshold = 0.8;
unit_num = 1;
t_pre = -1000;
t_post = 500;
binwidth_PSTH = 20;

% color settings
frame_short = 100;
frame_long = 175;
color1_all = hot(r.VideoInfos_side(1).total_frames-frame_short);
color1_short = [color1_all(1:210,:);repmat(color1_all(210,:),[frame_short,1]);color1_all(211:end,:)];
color1_long = [color1_all(1:210,:);repmat(color1_all(210,:),[frame_long,1]);color1_all(211:end-frame_long+frame_short,:)];

color2_all = winter(r.VideoInfos_side(1).total_frames-frame_short);
color2_short = [color2_all(1:210,:);repmat(color2_all(210,:),[frame_short,1]);color2_all(211:end,:)];
color2_long = [color2_all(1:210,:);repmat(color2_all(210,:),[frame_long,1]);color2_all(211:end-frame_long+frame_short,:)];

colors_short = {color1_short,color2_short};
colors_long = {color1_long,color2_long};

% markersize, linewidth ...
markersize_top = 0.1;
markersize_side = 1;
colors_name = {'red','blue'};
linewidth_PSTH = 1;


ntrial_raster = 20;

%% Figure Configuration
margin_left = 0.5;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_raster_traj = 0.2;
space_raster_yt = 0.5;
space_col_traj = 0.2;
space_row_raster = 0.2;
space_col_raster = 1;

width_traj = 3;
height_traj = 3;
width_yt = 3;
height_yt = 3;
width_raster = 3;
height_raster = 3;
width_PSTH = 3;
height_PSTH = 3;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_traj*3 + space_col_traj*2;
figure_height = margin_up + margin_bottom + height_traj + height_raster + height_PSTH + space_row_raster + space_raster_yt + height_yt + space_col_traj;
h.Position = [10,10,figure_width,figure_height];

% traj topview
ax_topview = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_topview.Position = [margin_left,margin_bottom+space_row_raster+space_raster_yt+height_yt+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
image(ax_topview,bg_top);
ax_topview.XAxis.Visible = 'off';ax_topview.YAxis.Visible = 'off';
title(ax_topview,'topview');

% traj sideview1
ax_sideview1 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview1.Position = [margin_left+width_traj*1+space_col_traj*1,margin_bottom+space_row_raster+space_raster_yt+height_yt+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview1.XAxis.Visible = 'off';ax_sideview1.YAxis.Visible = 'off';
title(ax_sideview1,'sideview');
image(ax_sideview1,bg_side_traj1);
xlim(ax_sideview1,[0,size(bg_side_traj1,2)])
ylim(ax_sideview1,[0,size(bg_side_traj1,2)])

% traj sideview2
ax_sideview2 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview2.Position = [margin_left+width_traj*2+space_col_traj*2,margin_bottom+space_row_raster+space_raster_yt+height_yt+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview2.XAxis.Visible = 'off';ax_sideview2.YAxis.Visible = 'off';
title(ax_sideview2,'sideview');
image(ax_sideview2,bg_side_traj2);
xlim(ax_sideview2,[0,size(bg_side_traj2,2)])
ylim(ax_sideview2,[0,size(bg_side_traj2,2)])

% y vs t
ax_yt1 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_yt1.Position = [(figure_width-space_col_raster)/2-width_raster,margin_bottom+space_row_raster+space_raster_yt+height_raster+height_PSTH,width_yt,height_yt];
ylabel(ax_yt1,'y (pixel)')
xlim(ax_yt1,[-1000,0])
ylim(ax_yt1,[200,900])

ax_yt2 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_yt2.Position = [(figure_width+space_col_raster)/2,margin_bottom+space_row_raster+space_raster_yt+height_raster+height_PSTH,width_yt,height_yt];
ax_yt2.YAxis.Visible = 'off';
xlim(ax_yt2,[-1000,0])
ylim(ax_yt2,[200,900])

% raster1
ax_raster1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster1.Position = [(figure_width-space_col_raster)/2-width_raster,margin_bottom+space_row_raster+height_PSTH,width_raster,height_raster];
ax_raster1.YTick = [1,ntrial_raster];
ax_raster1.YLim = [0.5,ntrial_raster+0.5];
ax_raster1.XAxis.Visible = 'off';
ylabel(ax_raster1,'Trials');

% raster2
ax_raster2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster2.Position = [(figure_width+space_col_raster)/2,margin_bottom+space_row_raster+height_PSTH,width_raster,height_raster];
ax_raster2.YTick = [1,ntrial_raster];
ax_raster2.YLim = [0.5,ntrial_raster+0.5];
ax_raster2.XAxis.Visible = 'off';ax_raster2.YAxis.Visible = 'off';

% PSTH1
ax_PSTH1 = axes(h,'Units','centimeters','NextPlot','add');
ax_PSTH1.Position = [(figure_width-space_col_raster)/2-width_raster,margin_bottom,width_PSTH,height_PSTH];
ylabel(ax_PSTH1,'Firing Rate (Hz)');

annotation(h,'textbox',[0.3,0,.4,.05],'String','Time from Press (ms)','EdgeColor','none','FontSize',8.25,'HorizontalAlignment','center','VerticalAlignment','middle');

% PSTH2
ax_PSTH2 = axes(h,'Units','centimeters','NextPlot','add');
ax_PSTH2.Position = [(figure_width+space_col_raster)/2,margin_bottom,width_PSTH,height_PSTH];
ax_PSTH2.YAxis.Visible = 'off';
%% Plotting
ind_bodypart_top = find(strcmp(r.VideoInfos_top(1).Tracking.BodyParts, bodypart_top));
ind_bodypart_side = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts, bodypart_side));
ind_correct = find(strcmp({r.VideoInfos_top.Performance},'Correct'));

cat = [r.VideoInfos_top.Trajectory];
index_cat1 = find(cat==1);
index_cat2 = find(cat==2);

% traj topview
interval_top = 10;

for k = 1:length(index_cat1)
    x1 = r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_top};
    y1 = r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_top};
    p1 = r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_top};
    x1(p1<p_threshold) = NaN;
    y1(p1<p_threshold) = NaN;
    if r.VideoInfos_top(ind_correct(index_cat1(k))).Foreperiod == 750
        scatter(ax_topview,x1,y1,markersize_top,colors_short{1},'filled');
    else
        scatter(ax_topview,x1,y1,markersize_top,colors_long{1},'filled');
    end
end

for k = 1:length(index_cat2)
    x2 = r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_top};
    y2 = r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_top};
    p2 = r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_top};
    x2(p2<p_threshold) = NaN;
    y2(p2<p_threshold) = NaN;
    if r.VideoInfos_top(ind_correct(index_cat2(k))).Foreperiod == 750
        scatter(ax_topview,x2,y2,markersize_top,colors_short{2},'filled');
    else
        scatter(ax_topview,x2,y2,markersize_top,colors_long{2},'filled');
    end
end

% sideview
frame_num_press = -r.VideoInfos_side(1).t_pre/10;
interval_side = 1;

for k = 1:length(index_cat1)
    p1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_side};
    n_start = 1;
    for j = frame_num_press:-1:1
        if p1(j)<p_threshold
            n_start = j+1;
            break
        end
    end
    x1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_side};
    y1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_side};
    x1(1:n_start-1) = NaN; x1(frame_num_press+1:end) = NaN;
    y1(1:n_start-1) = NaN; y1(frame_num_press+1:end) = NaN;
    
    scatter(ax_sideview1,x1,y1,markersize_side,colors_short{1},'filled');
end

for k = 1:length(index_cat2)        
    p2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_side};
    n_start = 1;
    for j = frame_num_press:-1:1
        if p2(j)<p_threshold
            n_start = j+1;
            break
        end
    end
    x2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_side};
    y2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_side};
    x2(1:n_start-1) = NaN; x2(frame_num_press+1:end) = NaN;
    y2(1:n_start-1) = NaN; y2(frame_num_press+1:end) = NaN;

    scatter(ax_sideview2,x2,y2,markersize_side,colors_short{2},'filled');
end
% y vs t
rand('seed',123);
t_start_lift = [r.VideoInfos_side.LiftStartTime] - [r.VideoInfos_side.Time];
t_start_lift = t_start_lift(ind_correct);

idx_cat1_start_lift_raw = find(~isnan(t_start_lift(index_cat1))); % good index of index_cat1
t_cat1_start_lift = t_start_lift(index_cat1(idx_cat1_start_lift_raw)); 
[~, idx_cat1_start_lift] = sort(t_cat1_start_lift);

idx_cat2_start_lift_raw = find(~isnan(t_start_lift(index_cat2)));
t_cat2_start_lift = t_start_lift(index_cat2(idx_cat2_start_lift_raw));
[~, idx_cat2_start_lift] = sort(t_cat2_start_lift);

rnd_cat1 = randperm(length(idx_cat1_start_lift));
rnd_cat1 = idx_cat1_start_lift_raw(idx_cat1_start_lift(sort(rnd_cat1(1:ntrial_raster))));
rnd_cat2 = randperm(length(idx_cat2_start_lift));
rnd_cat2 = idx_cat2_start_lift_raw(idx_cat2_start_lift(sort(rnd_cat2(1:ntrial_raster))));

for k = rnd_cat1
    p1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_side};
    n_start = 1;
    for j = frame_num_press:-1:1
        if p1(j)<p_threshold
            n_start = j+1;
            break
        end
    end
    x1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
    y1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
    x1 = x1(1:interval_side:end);
    y1 = y1(1:interval_side:end);
    plot(ax_yt1,r.VideoInfos_side(ind_correct(index_cat1(k))).VideoFrameTime(n_start:frame_num_press)-r.VideoInfos_side(ind_correct(index_cat1(k))).Time,y1,'Color',colors_name{1});
end
for k = rnd_cat2
    p2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_side};
    n_start = 1;
    for j = frame_num_press:-1:1
        if p2(j)<p_threshold
            n_start = j+1;
            break
        end
    end
    x2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
    y2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
    x2 = x2(1:interval_side:end);
    y2 = y2(1:interval_side:end);
    plot(ax_yt2,r.VideoInfos_side(ind_correct(index_cat2(k))).VideoFrameTime(n_start:frame_num_press)-r.VideoInfos_side(ind_correct(index_cat2(k))).Time,y2,'Color',colors_name{2});
end

% raster

for k = 1:length(rnd_cat1)
    ind_this = ind_correct(index_cat1(rnd_cat1(k)));
    spk_time = r.Units.SpikeTimes(unit_num).timings(r.VideoInfos_top(ind_this).Time+t_pre<=r.Units.SpikeTimes(unit_num).timings & r.VideoInfos_top(ind_this).Time+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - r.VideoInfos_top(ind_this).Time;
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;
        
        plot(ax_raster1,xx,yy,'-','Color',colors_name{1}); 
    end
    t_lift_this = r.VideoInfos_side(ind_this).LiftStartTime-r.VideoInfos_side(ind_this).Time;
    plot(ax_raster1,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','green');
end
xlim(ax_raster1,[t_pre t_post]);

for k = 1:length(rnd_cat2)
    ind_this = ind_correct(index_cat2(rnd_cat2(k)));
    spk_time = r.Units.SpikeTimes(unit_num).timings(r.VideoInfos_top(ind_this).Time+t_pre<=r.Units.SpikeTimes(unit_num).timings & r.VideoInfos_top(ind_this).Time+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - r.VideoInfos_top(ind_this).Time;
    if ~isempty(spk_time)
        numspikes=length(spk_time);
        xx=ones(3*numspikes,1)*nan;
        yy=ones(3*numspikes,1)*nan;

        yy(1:3:3*numspikes)=-0.5+k;
        yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;
        xx(1:3:3*numspikes)=spk_time;
        xx(2:3:3*numspikes)=spk_time;     
        
        plot(ax_raster2,xx,yy,'-','Color',colors_name{2});  
    end
    t_lift_this = r.VideoInfos_side(ind_this).LiftStartTime-r.VideoInfos_side(ind_this).Time;
    plot(ax_raster2,[t_lift_this,t_lift_this],[-0.5+k,0.5+k],'-','Color','green');
end
xlim(ax_raster2,[t_pre t_post]);

% PSTH
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
trigtimes1 = [r.VideoInfos_top(ind_correct(index_cat1)).Time];
trigtimes2 = [r.VideoInfos_top(ind_correct(index_cat2)).Time];
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes1', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes2', params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PSTH1,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PSTH2,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)

ylim_max = max(ax_PSTH1.YLim(2),ax_PSTH2.YLim(2));
ax_PSTH1.YLim = [0,ylim_max];
ax_PSTH2.YLim = [0,ylim_max];


%% Save Figure
print(h,save_filename_bmp,'-dbmp',['-r',num2str(save_resolution)])
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])
