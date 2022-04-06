%% Meta Info
r_path = 'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat';
vid_top = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_top\RawVideo\Press004.avi');
bg_top = vid_top.read(1);
vid_side = VideoReader('D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press004.avi');
bg_side = vid_side.read(1);

bodypart_top = 'right_ear';
bodypart_side = 'left_paw';
p_threshold = 0.99;
unit_num = 3;
t_pre = -1000;
t_post = 500;
binwidth_PSTH = 20;
colors = {'red','blue'};

ntrial_raster = 20;
% load(r_path)

%% Figure Configuration
margin_left = 0.5;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_raster_traj = 0.2;
space_col_traj = 0.2;
space_row_raster = 0.2;
space_col_raster = 1;

width_traj = 3;
height_traj = 3;
width_raster = 3;
height_raster = 3;
width_PSTH = 3;
height_PSTH = 3;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_traj*3 + space_col_traj*2;
figure_height = margin_up + margin_bottom + height_traj + height_raster + height_PSTH + space_row_raster + space_col_traj;
h.Position = [10,10,figure_width,figure_height];

% traj topview
ax_topview = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_topview.Position = [margin_left,margin_bottom+space_row_raster+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
image(ax_topview,bg_top);
ax_topview.XAxis.Visible = 'off';ax_topview.YAxis.Visible = 'off';
title(ax_topview,'topview');

% traj sideview1
ax_sideview1 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview1.Position = [margin_left+width_traj*1+space_col_traj*1,margin_bottom+space_row_raster+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview1.XAxis.Visible = 'off';ax_sideview1.YAxis.Visible = 'off';
title(ax_sideview1,'sideview');
image(ax_sideview1,bg_side);
xlim(ax_sideview1,[0,size(bg_side,2)])
ylim(ax_sideview1,[0,size(bg_side,2)])

% traj sideview1
ax_sideview2 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview2.Position = [margin_left+width_traj*2+space_col_traj*2,margin_bottom+space_row_raster+space_raster_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview2.XAxis.Visible = 'off';ax_sideview2.YAxis.Visible = 'off';
title(ax_sideview2,'sideview');
image(ax_sideview2,bg_side);
xlim(ax_sideview2,[0,size(bg_side,2)])
ylim(ax_sideview2,[0,size(bg_side,2)])

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
    x1 = r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_top}(r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_top}>p_threshold);
    y1 = r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_top}(r.VideoInfos_top(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_top}>p_threshold);
    x1 = x1(1:interval_top:end);
    y1 = y1(1:interval_top:end);

    X = x1(1:end-1);
    Y = y1(1:end-1);
    x_diff = diff(x1);
    y_diff = diff(y1);
    quiver(ax_topview,X,Y,x_diff,y_diff,0,'Color',colors{1});
end

for k = 1:length(index_cat2)        
    x2 = r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_top}(r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_top}>p_threshold);
    y2 = r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_top}(r.VideoInfos_top(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_top}>p_threshold);
    x2 = x2(1:interval_top:end);
    y2 = y2(1:interval_top:end);

    X = x2(1:end-1);
    Y = y2(1:end-1);
    x_diff = diff(x2);
    y_diff = diff(y2);
    quiver(ax_topview,X,Y,x_diff,y_diff,0,'Color',colors{2});
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
    x1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
    y1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
    x1 = x1(1:interval_side:end);
    y1 = y1(1:interval_side:end);    
    
    X = x1(1:end-1);
    Y = y1(1:end-1);
    x_diff = diff(x1);
    y_diff = diff(y1);
%     plot(ax_sideview1,x1,y1,'.','Color',colors{1});
    quiver(ax_sideview1,X,Y,x_diff,y_diff,0,'Color',colors{1});
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
    x2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
    y2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
    x2 = x2(1:interval_side:end);
    y2 = y2(1:interval_side:end);
    
    X = x2(1:end-1);
    Y = y2(1:end-1);
    x_diff = diff(x2);
    y_diff = diff(y2);
%     plot(ax_sideview2,x2,y2,'.','Color',colors{2});
    quiver(ax_sideview2,X,Y,x_diff,y_diff,0,'Color',colors{2});
end
% raster
rand('seed',123);
rnd_trial = randperm(ntrial_raster);

for k = 1:length(rnd_trial)
    ind_this = ind_correct(index_cat1(rnd_trial(k)));
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
        plot(ax_raster1,xx,yy,'-','Color',colors{1});
    end
end
for k = 1:length(rnd_trial)
    ind_this = ind_correct(index_cat2(rnd_trial(k)));
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
        plot(ax_raster2,xx,yy,'-','Color',colors{2});
    end
end

% PSTH
params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth_PSTH;
trigtimes1 = [r.VideoInfos_top(ind_correct(index_cat1)).Time];
trigtimes2 = [r.VideoInfos_top(ind_correct(index_cat2)).Time];
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes1', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes2', params);

plot(ax_PSTH1,tpsth1,psth1,'Color',colors{1})
plot(ax_PSTH2,tpsth2,psth2,'Color',colors{2})

ylim_max = max(ax_PSTH1.YLim(2),ax_PSTH2.YLim(2));
ax_PSTH1.YLim = [0,ylim_max];
ax_PSTH2.YLim = [0,ylim_max];


%% Save Figure
print(h,'C:/Users/jiumao/Desktop/fig.bmp','-dbmp','-r1200')
print(h,'C:/Users/jiumao/Desktop/fig.png','-dpng','-r1200')
print(h,'C:/Users/jiumao/Desktop/fig.pdf','-dpdf','-r1200')
