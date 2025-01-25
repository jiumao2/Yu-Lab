function plotTracking(folder)
% PLOTTRACKING plot the trackings of the left / right ear before and after
% lever press.
%
% - Only correct trials are included
% - Time is color-coded
% - Bad tracking points (p < p_thres) are excluded
%

bodypart = 'right_ear';
p_thres = 0.95;
t_pre_frame = -200; % from lever press
t_post_frame = 120; % from lever release

load(fullfile(folder, 'VideoInfos.mat'));
dir_out = dir(fullfile(folder, 'VideoFrames_top/RawVideo/Press*.avi'));
vid_example = VideoReader(fullfile(folder, 'VideoFrames_top/RawVideo', dir_out(1).name));

bg = {vid_example.read(round((VideoInfos(1).Foreperiod+VideoInfos(1).ReactTime+500-VideoInfos(1).t_pre)/10)),...
    vid_example.read(round((-100-VideoInfos(1).t_pre)/10))};
imwrite(bg{1}, fullfile(folder, 'bg_approaching.png'));
imwrite(bg{2}, fullfile(folder, 'bg_leaving.png'));

bg_width = size(bg{1}, 2);
bg_height = size(bg{1}, 1);
title_names = {'Approaching', 'Leaving'};

idx_bodypart = find(strcmpi(VideoInfos(1).Tracking.BodyParts, bodypart));

color_num = max(abs([t_pre_frame, t_post_frame]))+1;
colors = jet(color_num);

fig = EasyPlot.figure();
ax_approaching = EasyPlot.axes(fig,...
    'XAxisVisible', 'off',...
    'YAxisVisible', 'off',...
    'YDir', 'reverse',...
    'Width', 4,...
    'Height', 4);
EasyPlot.set(ax_approaching, 'Height', ax_approaching.Position(3)./bg_width*bg_height);

ax_leaving = EasyPlot.createAxesAgainstAxes(fig, ax_approaching, 'right',...
    'XAxisVisible', 'off',...
    'YAxisVisible', 'off',...
    'YDir','reverse');

ax_all = {ax_approaching, ax_leaving};

for k = 1:2
    image(ax_all{k}, bg{k});
    title(ax_all{k}, title_names{k});

    for j = 1:length(VideoInfos)
        p = VideoInfos(j).Tracking.Coordinates_p{idx_bodypart};
        x = VideoInfos(j).Tracking.Coordinates_x{idx_bodypart};
        y = VideoInfos(j).Tracking.Coordinates_y{idx_bodypart};

        x(p<p_thres) = NaN;
        y(p<p_thres) = NaN;        
        
        press_frame = -VideoInfos(j).t_pre / 10 + 1;
        release_time_this = VideoInfos(j).Time+VideoInfos(j).Foreperiod+VideoInfos(j).ReactTime;
        [~, release_frame] = min(abs(VideoInfos(j).VideoFrameTime-release_time_this));

        x_approach = x(press_frame+t_pre_frame:press_frame);
        y_approach = y(press_frame+t_pre_frame:press_frame);
        
        frame_end = min(release_frame+t_post_frame, length(x));
        x_leaving = x(release_frame:frame_end);
        y_leaving = y(release_frame:frame_end);

        color_approach = colors(length(x_approach):-1:end-length(x_approach)+1,:);
        scatter(ax_approaching, x_approach, y_approach, 0.5, color_approach, 'filled', 'o');

        color_leaving = colors(1:length(x_leaving),:);
        scatter(ax_leaving, x_leaving, y_leaving, 0.5, color_leaving, 'filled', 'o');
    end
end

EasyPlot.setXLim(ax_all, [0, bg_width]);
EasyPlot.setYLim(ax_all, [0, bg_height]);

color_ticks = [0, 50/(color_num-1), 1];
tick_labels = [0, 500, (color_num-1)*10];
EasyPlot.colorbar(ax_leaving,...
    'label', 'Time from press / release (ms)',...
    'MarginRight', 1,...
    'colormap', colors,...
    'Ticks', color_ticks,...
    'TickLabels', tick_labels);

rat_name = VideoInfos(1).AnimalName;
session = VideoInfos(1).SessionName;

h = EasyPlot.setGeneralTitle(ax_all, [rat_name, ' ', session, ' (', strrep(bodypart, '_', ' '), ')']);
EasyPlot.move(h, 'dy', 0.3);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile(folder, ['TopviewTracking_', rat_name, '_', session]));
EasyPlot.exportFigure(fig, fullfile(folder, ['TopviewTracking_', rat_name, '_', session]), 'type', 'pdf');
end