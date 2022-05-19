%% Meta Info
global idx_bodypart_side_left_hand idx_bodypart_side_right_hand idx_bodypart_side_eye idx_bodypart_side_ear
global idx_bodypart_top_left_ear idx_bodypart_top_right_ear idx_bodypart_top_head_center idx_bodypart_top_tail
global p_threshold vid_press_idx notation_left_hand color_left_hand notation_right_hand color_right_hand
global notation_eye color_eye notation_left_ear color_left_ear
global notation_right_ear color_right_ear notation_head_center color_head_center notation_tail color_tail
r_path = 'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat';
load(r_path)

save_filename_pdf = './TrackingQuality.pdf';
save_filename_png = './TrackingQuality.png';
save_resolution = 1200;

press_idx = 50;
vid_top = VideoReader(['D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_top\RawVideo\Press',num2str(press_idx,'%03d'),'.avi']);
vid_side = VideoReader(['D:\Ephys\ANMs\Urey\Videos\20211124_video\VideoFrames_side\RawVideo\Press',num2str(press_idx,'%03d'),'.avi']);
vid_press_idx = find([r.VideoInfos_side.Index] == press_idx);

bodypart_top = 'right_ear';
bodypart_side = 'left_paw';

t_approach = -300;
t_lift = -150;
t_hold = 500;
t_release = 1320;

p_threshold = 0.8;

idx_bodypart_side_left_hand = find(strcmp('left_paw',r.VideoInfos_side(vid_press_idx).Tracking.BodyParts));
idx_bodypart_side_right_hand = find(strcmp('right_paw',r.VideoInfos_side(vid_press_idx).Tracking.BodyParts));
idx_bodypart_side_ear = find(strcmp('left_ear',r.VideoInfos_side(vid_press_idx).Tracking.BodyParts));
idx_bodypart_side_eye = find(strcmp('left_eye',r.VideoInfos_side(vid_press_idx).Tracking.BodyParts));

idx_bodypart_top_left_ear = find(strcmp('left_ear',r.VideoInfos_top(vid_press_idx).Tracking.BodyParts));
idx_bodypart_top_right_ear = find(strcmp('right_ear',r.VideoInfos_top(vid_press_idx).Tracking.BodyParts));
idx_bodypart_top_head_center = find(strcmp('light',r.VideoInfos_top(vid_press_idx).Tracking.BodyParts));
idx_bodypart_top_tail = find(strcmp('tail',r.VideoInfos_top(vid_press_idx).Tracking.BodyParts));

notation_left_hand = 'x';
color_left_hand = 'red';
notation_right_hand = 'd';
color_right_hand = 'green';
notation_eye = 'o';
color_eye = 'blue';
notation_left_ear = '*';
color_left_ear = 'yellow';

notation_right_ear = '+';
color_right_ear = 'red';
notation_head_center = 's';
color_head_center = 'blue';
notation_tail = 'p';
color_tail = 'green';

%% Figure Configuration
margin_left = 2;
margin_right = 0.5;
margin_up = 0.5;
margin_bottom = 1;
space_col = 0.1;
space_row = 0.1;

img_width_side = size(vid_side.read(1),2);
img_width_top = size(vid_top.read(1),2);
img_height_side = size(vid_side.read(1),1);
img_height_top = size(vid_top.read(1),1);

width_traj = 3;
height_traj_side = width_traj/img_width_side*img_height_side;
height_traj_top = width_traj/img_width_top*img_height_top;

h = figure('Units','centimeters');
figure_width = margin_left + margin_right + width_traj*4 + space_col*3;
figure_height = margin_up + margin_bottom + height_traj_side + height_traj_top + space_row;
h.Position = [15,15,figure_width,figure_height];

annotation(h,'textbox',[0.022,0.71,0.1,0.05],'FontWeight','bold','String','Sideview','EdgeColor','none','FontSize',8.25,'HorizontalAlignment','center','VerticalAlignment','middle');
annotation(h,'textbox',[0.022,0.2932,0.1,0.05],'FontWeight','bold','String','Topview','EdgeColor','none','FontSize',8.25,'HorizontalAlignment','center','VerticalAlignment','middle');

% traj side approach
ax_side_approach = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_side_approach.Position = [margin_left,margin_bottom+space_row+height_traj_top,width_traj,height_traj_side];
ax_side_approach.XAxis.Visible = 'off';ax_side_approach.YAxis.Visible = 'off';
title(ax_side_approach,'Approach')
xlim(ax_side_approach,[0,img_width_side])
ylim(ax_side_approach,[0,img_height_side])

% traj side lift
ax_side_lift = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_side_lift.Position = [margin_left+width_traj+space_col,margin_bottom+space_row+height_traj_top,width_traj,height_traj_side];
ax_side_lift.XAxis.Visible = 'off';ax_side_lift.YAxis.Visible = 'off';
title(ax_side_lift,'Lift')
xlim(ax_side_lift,[0,img_width_side])
ylim(ax_side_lift,[0,img_height_side])

% traj side hold
ax_side_hold = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_side_hold.Position = [margin_left+width_traj*2+space_col*2,margin_bottom+space_row+height_traj_top,width_traj,height_traj_side];
ax_side_hold.XAxis.Visible = 'off';ax_side_hold.YAxis.Visible = 'off';
title(ax_side_hold,'Hold')
xlim(ax_side_hold,[0,img_width_side])
ylim(ax_side_hold,[0,img_height_side])

% traj side release
ax_side_release = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_side_release.Position = [margin_left+width_traj*3+space_col*3,margin_bottom+space_row+height_traj_top,width_traj,height_traj_side];
ax_side_release.XAxis.Visible = 'off';ax_side_release.YAxis.Visible = 'off';
title(ax_side_release,'Release')
xlim(ax_side_release,[0,img_width_side])
ylim(ax_side_release,[0,img_height_side])


% traj top approach
ax_top_approach = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_top_approach.Position = [margin_left,margin_bottom,width_traj,height_traj_top];
ax_top_approach.XTick = {};
ax_top_approach.YAxis.Visible = 'off';
xlim(ax_top_approach,[0,img_width_top])
ylim(ax_top_approach,[0,img_height_top])
xlabel(ax_top_approach,['t = ',num2str(t_approach),' ms'])

% traj top lift
ax_top_lift = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_top_lift.Position = [margin_left+width_traj+space_col,margin_bottom,width_traj,height_traj_top];
ax_top_lift.XTick = {};
ax_top_lift.YAxis.Visible = 'off';
xlim(ax_top_lift,[0,img_width_top])
ylim(ax_top_lift,[0,img_height_top])
xlabel(ax_top_lift,['t = ',num2str(t_lift),' ms'])

% traj top hold
ax_top_hold = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_top_hold.Position = [margin_left+width_traj*2+space_col*2,margin_bottom,width_traj,height_traj_top];
ax_top_hold.XTick = {};
ax_top_hold.YAxis.Visible = 'off';
xlim(ax_top_hold,[0,img_width_top])
ylim(ax_top_hold,[0,img_height_top])
xlabel(ax_top_hold,['t = ',num2str(t_hold),' ms'])

% traj top release
ax_top_release = axes(h,'Units','centimeters','NextPlot','add','YDir','reverse');
ax_top_release.Position = [margin_left+width_traj*3+space_col*3,margin_bottom,width_traj,height_traj_top];
ax_top_release.XTick = {};
ax_top_release.YAxis.Visible = 'off';
xlim(ax_top_release,[0,img_width_top])
ylim(ax_top_release,[0,img_height_top])
xlabel(ax_top_release,['t = ',num2str(t_release),' ms'])

%% Plotting
n_frame_approach = round((t_approach-r.VideoInfos_side(1).t_pre)/10+1);
n_frame_lift = round((t_lift-r.VideoInfos_side(1).t_pre)/10+1);
n_frame_hold = round((t_hold-r.VideoInfos_side(1).t_pre)/10+1);
n_frame_release = round((t_release-r.VideoInfos_side(1).t_pre)/10+1);

% side
image(ax_side_approach,vid_side.read(n_frame_approach));
plot_side_tracking(r,ax_side_approach,n_frame_approach)

image(ax_side_lift,vid_side.read(n_frame_lift));
plot_side_tracking(r,ax_side_lift,n_frame_lift)

image(ax_side_hold,vid_side.read(n_frame_hold));
plot_side_tracking(r,ax_side_hold,n_frame_hold)
for k = 1:n_frame_hold
    if r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_side_left_hand}(k) > p_threshold
        plot(ax_side_hold,r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_side_left_hand}(k),...
            r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_side_left_hand}(k),...
            [notation_left_hand,color_left_hand]);
    end
end

image(ax_side_release,vid_side.read(n_frame_release));
plot_side_tracking(r,ax_side_release,n_frame_release)

% top
image(ax_top_approach,vid_top.read(n_frame_approach));
plot_top_tracking(r,ax_top_approach,n_frame_approach)

image(ax_top_lift,vid_top.read(n_frame_lift));
plot_top_tracking(r,ax_top_lift,n_frame_lift)

image(ax_top_hold,vid_top.read(n_frame_hold));
plot_top_tracking(r,ax_top_hold,n_frame_hold)

image(ax_top_release,vid_top.read(n_frame_release));
plot_top_tracking(r,ax_top_release,n_frame_release)

%% Save Figure
print(h,save_filename_png,'-dpng',['-r',num2str(save_resolution)])
print(h,save_filename_pdf,'-dpdf',['-r',num2str(save_resolution)])

%%
function plot_side_tracking(r,ax,n_frame)
global idx_bodypart_side_left_hand idx_bodypart_side_right_hand idx_bodypart_side_eye idx_bodypart_side_ear
global p_threshold
global vid_press_idx notation_left_hand color_left_hand notation_right_hand color_right_hand
global notation_eye color_eye notation_left_ear color_left_ear

if r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_side_left_hand}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_side_left_hand}(n_frame),...
        r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_side_left_hand}(n_frame),...
        [notation_left_hand,color_left_hand]);
end
if r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_side_right_hand}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_side_right_hand}(n_frame),...
        r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_side_right_hand}(n_frame),...
        [notation_right_hand,color_right_hand]);
end
if r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_side_eye}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_side_eye}(n_frame),...
        r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_side_eye}(n_frame),...
        [notation_eye,color_eye]);
end
if r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_side_ear}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_side_ear}(n_frame),...
        r.VideoInfos_side(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_side_ear}(n_frame),...
        [notation_left_ear,color_left_ear]);
end
end

function plot_top_tracking(r,ax,n_frame)
global idx_bodypart_top_left_ear idx_bodypart_top_right_ear idx_bodypart_top_head_center idx_bodypart_top_tail
global p_threshold
global vid_press_idx
global notation_left_ear color_left_ear notation_right_ear color_right_ear notation_head_center color_head_center notation_tail color_tail

if r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_top_left_ear}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_top_left_ear}(n_frame),...
        r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_top_left_ear}(n_frame),...
        [notation_left_ear,color_left_ear],'MarkerSize',6);
end
if r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_top_right_ear}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_top_right_ear}(n_frame),...
        r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_top_right_ear}(n_frame),...
        [notation_right_ear,color_right_ear],'MarkerSize',6);
end
if r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_top_head_center}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_top_head_center}(n_frame),...
        r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_top_head_center}(n_frame),...
        [notation_head_center,color_head_center],'MarkerSize',6);
end
if r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_p{idx_bodypart_top_tail}(n_frame) > p_threshold
    plot(ax,r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_x{idx_bodypart_top_tail}(n_frame),...
        r.VideoInfos_top(vid_press_idx).Tracking.Coordinates_y{idx_bodypart_top_tail}(n_frame),...
        [notation_tail,color_tail]);
end
end