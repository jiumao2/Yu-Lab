%% Uncommented this section to get the figure from Chen
% r_path = 'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat';
% load(r_path)
% ind_correct = find(strcmp({r.VideoInfos_side.Performance},'Correct'));
% cat = {r.VideoInfos_side.Hand};
% cat = cat(ind_correct);
% vid_left_filename = 'D:\Ephys\ANMs\Chen\Video\20220507_video\VideoFrames_side\RawVideo\Press070.avi';
% vid_right_filename = 'D:\Ephys\ANMs\Chen\Video\20220507_video\VideoFrames_side\RawVideo\Press114.avi';
% animal_name = 'Chen';
% unit_num = 2;
% event = 'press';
% ntrial_raster = 30;
% index_cat1 = find(strcmp(cat,'Left'));
% index_cat2 = find(strcmp(cat,'Right'));
%% Uncommented this section to get the figure from Russo
% r_path = 'D:\Ephys\ANMs\Russo\Sessions\20210908_video\RTarrayAll.mat';
% load(r_path)
% ind_correct = find(strcmp({r.VideoInfos_side.Performance},'Correct'));
% cat1 = {r.VideoInfos_side.Hand};
% cat1 = cat1(ind_correct);
% cat2 = [r.VideoInfos_top.Trajectory];
% index_cat1 = find(strcmp(cat1,'Left') & cat2==1);
% index_cat2 = find((strcmp(cat1,'Right') | strcmp(cat1,'Both')) & cat2==1);
% vid_left_filename = 'D:\Ephys\ANMs\Russo\Sessions\20210908_video\VideoFrames_side\RawVideo\Press070.avi';
% vid_right_filename = 'D:\Ephys\ANMs\Russo\Sessions\20210908_video\VideoFrames_side\RawVideo\Press012.avi';
% animal_name = 'Russo';
% unit_num = 3;
% event = 'press';
% ntrial_raster = 20;
%% 
save_filename_pdf = ['./HandComparing_',animal_name,'.pdf'];
save_filename_png = ['./HandComparing_',animal_name,'.png'];
save_filename_eps = ['./HandComparing_',animal_name,'.eps'];
save_resolution = 1200;

vid_side_left = VideoReader(vid_left_filename);
bg_side_left = vid_side_left.read(-r.VideoInfos_side(1).t_pre/10);
vid_side_right = VideoReader(vid_right_filename);
bg_side_right = vid_side_right.read(-r.VideoInfos_side(1).t_pre/10);

bodypart_top = 'right_ear';
bodypart_side = 'left_paw';
p_threshold = 0.8;
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


%% Figure Configuration
margin_left = 1;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_col_traj = 1;
space_row_raster = 0.2;
space_row_traj = 0.2;
space_col_raster = 1;

width_traj = 3;
height_traj = 3;
width_raster = 3;
height_raster = 3;
width_PSTH = 3;
height_PSTH = 3;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_traj*2 + space_col_traj*1;
figure_height = margin_up + margin_bottom + height_traj + height_raster + height_PSTH + space_row_raster + space_row_traj;
h.Position = [10,10,figure_width,figure_height];

% traj sideview1
ax_sideview1 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview1.Position = [margin_left,margin_bottom+space_row_raster+space_row_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview1.XAxis.Visible = 'off';ax_sideview1.YAxis.Visible = 'off';
title(ax_sideview1,'Contralateral forelimb');
image(ax_sideview1,bg_side_left);
xlim(ax_sideview1,[0,size(bg_side_left,2)])
ylim(ax_sideview1,[0,size(bg_side_left,2)])

% traj sideview2
ax_sideview2 = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_sideview2.Position = [margin_left+width_traj*1+space_col_traj*1,margin_bottom+space_row_raster+space_row_traj+height_raster+height_PSTH,width_traj,height_traj];
ax_sideview2.XAxis.Visible = 'off';ax_sideview2.YAxis.Visible = 'off';
title(ax_sideview2,'Ipsilateral forelimb');
image(ax_sideview2,bg_side_right);
xlim(ax_sideview2,[0,size(bg_side_right,2)])
ylim(ax_sideview2,[0,size(bg_side_right,2)])

% raster1
ax_raster1 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster1.Position = [margin_left,margin_bottom+space_row_raster+height_PSTH,width_raster,height_raster];
ax_raster1.YTick = [1,ntrial_raster];
ax_raster1.YLim = [0.5,ntrial_raster+0.5];
ax_raster1.XAxis.Visible = 'off';
ylabel(ax_raster1,'Trials');
xline(ax_raster1,0,'-k','LineWidth',1);

% raster2
ax_raster2 = axes(h,'Units','centimeters','NextPlot','add');
ax_raster2.Position = [margin_left+space_col_raster+width_raster,margin_bottom+space_row_raster+height_PSTH,width_raster,height_raster];
ax_raster2.YTick = [1,ntrial_raster];
ax_raster2.YLim = [0.5,ntrial_raster+0.5];
ax_raster2.XAxis.Visible = 'off';ax_raster2.YAxis.Visible = 'off';
xline(ax_raster2,0,'-k','LineWidth',1);

% PSTH1
ax_PSTH1 = axes(h,'Units','centimeters','NextPlot','add');
ax_PSTH1.Position = [margin_left,margin_bottom,width_PSTH,height_PSTH];
ylabel(ax_PSTH1,'Firing rate (Hz)');
xlim(ax_PSTH1,[t_pre,t_post])
xline(ax_PSTH1,0,'-k','LineWidth',1);

annotation(h,'textbox',[0.3,0,.4,.05],'String','Time from press (ms)','EdgeColor','none','FontSize',8.25,'HorizontalAlignment','center','VerticalAlignment','middle');

% PSTH2
ax_PSTH2 = axes(h,'Units','centimeters','NextPlot','add');
ax_PSTH2.Position = [margin_left+space_col_raster+width_raster,margin_bottom,width_PSTH,height_PSTH];
ax_PSTH2.YAxis.Visible = 'off';
xlim(ax_PSTH2,[t_pre,t_post])
xline(ax_PSTH2,0,'-k','LineWidth',1);
%% Plotting
% ind_bodypart_side = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts, bodypart_side));
ind_correct = find(strcmp({r.VideoInfos_side.Performance},'Correct'));

cat = {r.VideoInfos_side.Hand};
cat = cat(ind_correct);

rand('seed',123);
% % sideview
% frame_num_press = -r.VideoInfos_side(1).t_pre/10;
% interval_side = 1;
% 
% for k = 1:length(index_cat1)
%     p1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_side};
%     n_start = 1;
%     for j = frame_num_press:-1:1
%         if p1(j)<p_threshold
%             n_start = j+1;
%             break
%         end
%     end
%     x1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_side};
%     y1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_side};
%     x1(1:n_start-1) = NaN; x1(frame_num_press+1:end) = NaN;
%     y1(1:n_start-1) = NaN; y1(frame_num_press+1:end) = NaN;
%     
%     scatter(ax_sideview1,x1,y1,markersize_side,colors_short{1},'filled');
% end
% 
% for k = 1:length(index_cat2)        
%     p2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_side};
%     n_start = 1;
%     for j = frame_num_press:-1:1
%         if p2(j)<p_threshold
%             n_start = j+1;
%             break
%         end
%     end
%     x2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_side};
%     y2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_side};
%     x2(1:n_start-1) = NaN; x2(frame_num_press+1:end) = NaN;
%     y2(1:n_start-1) = NaN; y2(frame_num_press+1:end) = NaN;
% 
%     scatter(ax_sideview2,x2,y2,markersize_side,colors_short{2},'filled');
% end
% % y vs t
% t_start_lift = [r.VideoInfos_side.LiftStartTime] - [r.VideoInfos_side.Time];
% t_start_lift = t_start_lift(ind_correct);
% 
% idx_cat1_start_lift_raw = find(~isnan(t_start_lift(index_cat1))); % good index of index_cat1
% t_cat1_start_lift = t_start_lift(index_cat1(idx_cat1_start_lift_raw)); 
% [~, idx_cat1_start_lift] = sort(t_cat1_start_lift);
% 
% idx_cat2_start_lift_raw = find(~isnan(t_start_lift(index_cat2)));
% t_cat2_start_lift = t_start_lift(index_cat2(idx_cat2_start_lift_raw));
% [~, idx_cat2_start_lift] = sort(t_cat2_start_lift);
% 
% rnd_cat1 = randperm(length(idx_cat1_start_lift));
% rnd_cat1 = idx_cat1_start_lift_raw(idx_cat1_start_lift(sort(rnd_cat1(1:ntrial_raster))));
% rnd_cat2 = randperm(length(idx_cat2_start_lift));
% rnd_cat2 = idx_cat2_start_lift_raw(idx_cat2_start_lift(sort(rnd_cat2(1:ntrial_raster))));
% 
% for k = rnd_cat1
%     p1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_p{ind_bodypart_side};
%     n_start = 1;
%     for j = frame_num_press:-1:1
%         if p1(j)<p_threshold
%             n_start = j+1;
%             break
%         end
%     end
%     x1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
%     y1 = r.VideoInfos_side(ind_correct(index_cat1(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
%     x1 = x1(1:interval_side:end);
%     y1 = y1(1:interval_side:end);
%     plot(ax_yt1,r.VideoInfos_side(ind_correct(index_cat1(k))).VideoFrameTime(n_start:frame_num_press)-r.VideoInfos_side(ind_correct(index_cat1(k))).Time,y1,'Color',colors_name{1});
% end
% for k = rnd_cat2
%     p2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_p{ind_bodypart_side};
%     n_start = 1;
%     for j = frame_num_press:-1:1
%         if p2(j)<p_threshold
%             n_start = j+1;
%             break
%         end
%     end
%     x2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_x{ind_bodypart_side}(n_start:frame_num_press);
%     y2 = r.VideoInfos_side(ind_correct(index_cat2(k))).Tracking.Coordinates_y{ind_bodypart_side}(n_start:frame_num_press);
%     x2 = x2(1:interval_side:end);
%     y2 = y2(1:interval_side:end);
%     plot(ax_yt2,r.VideoInfos_side(ind_correct(index_cat2(k))).VideoFrameTime(n_start:frame_num_press)-r.VideoInfos_side(ind_correct(index_cat2(k))).Time,y2,'Color',colors_name{2});
% end

% raster
temp = randperm(length(index_cat1));
rnd_cat1 = temp(1:ntrial_raster);
temp = randperm(length(index_cat2));
rnd_cat2 = temp(1:ntrial_raster);
for k = 1:length(rnd_cat1)
    ind_this = ind_correct(index_cat1(rnd_cat1(k)));
    spk_time = r.Units.SpikeTimes(unit_num).timings(r.VideoInfos_side(ind_this).Time+t_pre<=r.Units.SpikeTimes(unit_num).timings & r.VideoInfos_side(ind_this).Time+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - r.VideoInfos_side(ind_this).Time;
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
    spk_time = r.Units.SpikeTimes(unit_num).timings(r.VideoInfos_side(ind_this).Time+t_pre<=r.Units.SpikeTimes(unit_num).timings & r.VideoInfos_side(ind_this).Time+t_post>=r.Units.SpikeTimes(unit_num).timings);
    spk_time = spk_time - r.VideoInfos_side(ind_this).Time;
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
trigtimes1 = [r.VideoInfos_side(ind_correct(index_cat1)).Time];
trigtimes2 = [r.VideoInfos_side(ind_correct(index_cat2)).Time];
[psth1, tpsth1] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes1', params);
[psth2, tpsth2] = jpsth(r.Units.SpikeTimes(unit_num).timings, trigtimes2', params);
psth1 = smoothdata (psth1, 'gaussian', 5);
psth2 = smoothdata (psth2, 'gaussian', 5);

plot(ax_PSTH1,tpsth1,psth1,'Color',colors_name{1},'LineWidth',linewidth_PSTH)
plot(ax_PSTH2,tpsth2,psth2,'Color',colors_name{2},'LineWidth',linewidth_PSTH)

ylim_max = max(ax_PSTH1.YLim(2),ax_PSTH2.YLim(2));
ax_PSTH1.YLim = [0,ylim_max];
ax_PSTH2.YLim = [0,ylim_max];
%% Annotation

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'A'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[-0.1,10.3,0.5,0.5]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'B'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[-0.1,6.8,0.5,0.5]);

h_annotation_press_text = annotation(h,'textbox',...
    [0.5,0.5,0.5,0.5],...
    'EdgeColor','none',...
    'Units','centimeters',...
    'VerticalAlignment','middle',...
    'String',{'C'},...
    'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'FitBoxToText','off');
set(h_annotation_press_text,'Position',[-0.1,3.6,0.5,0.5]);
%% Save Figure
% print(h,save_filename_bmp,'-dbmp',['-r',num2str(save_resolution)])
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
% print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])
% print(h,save_filename_eps,'-depsc',['-r',num2str(save_resolution)])