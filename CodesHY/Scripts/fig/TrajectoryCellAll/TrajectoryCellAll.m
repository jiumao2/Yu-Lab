r_traj_all = {
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',      1,  1,  ... % r_path, # unit, # traj
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',      12, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     5,  1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     10, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     12, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     14, 1,  ...
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',     15, 1,  ...
    'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat',   3,  1,  ...
    'D:\Ephys\ANMs\Russo\Sessions\20210908_video\RTarrayAll.mat',   11,  1,  ...
    'D:\Ephys\ANMs\Russo\Sessions\20210908_video\RTarrayAll.mat',   18,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      4,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      5,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',      6,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220406_video\RTarrayAll.mat',      1,  'All',  ...
    'D:\Ephys\ANMs\Davis\Video\20220406_video\RTarrayAll.mat',      3,  'All',  ...
    'D:\Ephys\ANMs\Davis\Video\20220406_video\RTarrayAll.mat',      4,  'All',  ...    
    'D:\Ephys\ANMs\Davis\Video\20220406_video\RTarrayAll.mat',      5,  'All',  ...   
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',      2,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',      5,  1,  ...
    'D:\Ephys\ANMs\Davis\Video\20220512_video\RTarrayAll.mat',      1,  2,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       1,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       2,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',       3,  1,  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       1,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       2,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       3,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       4,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',       6,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220519_video\RTarrayAll.mat',       3,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220519_video\RTarrayAll.mat',       5,  'All',  ...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',       4,  2,  ...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',       6,  2,  ...
};

n_post_framenum = 30;
n_pre_framenum = 30;
binwidth = 1;
gaussian_kernel = 25;
color_max_percentage = 1.00;
color_min_percentage = 0.00;
save_fig = 'off';
    
% mean y vs t
% align to the highest point

r_path = cell(round(length(r_traj_all)/3),1);
idx_unit = cell(round(length(r_traj_all)/3),1);
idx_traj = cell(round(length(r_traj_all)/3),1);
for k = 1:round(length(r_traj_all)/3)
    r_path{k} = r_traj_all{3*k-2};
    idx_unit{k} = r_traj_all{3*k-1};
    idx_traj{k} = r_traj_all{3*k};
end

bodypart = 'left_paw';
mean_firing_rate = nan(length(r_path),n_post_framenum+200);
mean_y = nan(length(r_path),n_post_framenum+200);

for idx_path = 1:length(r_path)
    load(r_path{idx_path})
    idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts,bodypart));
    press_indexes = getIndexVideoInfos(r,'Hand','Left','LiftStartTimeLabeled','On','Trajectory',idx_traj{idx_path});
    unit_num = idx_unit{idx_path};
    
    idx_all = [r.VideoInfos_side.Index];
    vid_press_idx = findSeq(idx_all,press_indexes); 
    
    t_all = cell(length(press_indexes),1);
    traj_all = cell(length(press_indexes),1); 
    highest_point = zeros(length(press_indexes),2);
    frame_num_all = zeros(1,length(press_indexes));
    firing_rate_all_flattened = [];
%     firing_rate_all = cell(length(press_indexes),1);
    firing_rate_all = nan(length(press_indexes),size(mean_firing_rate,2));
    y_all = nan(length(press_indexes),size(mean_firing_rate,2));
    
    [spike_counts, t_spike_counts] = bin_timings(r.Units.SpikeTimes(unit_num).timings, binwidth);
    spike_counts_all = smoothdata(spike_counts,'gaussian',gaussian_kernel*5)./binwidth*1000;
    
    for k = 1:length(vid_press_idx)
        frame_num_temp = max(r.VideoInfos_side(vid_press_idx(k)).LiftStartFrameNum-n_pre_framenum,1):round(-r.VideoInfos_side(vid_press_idx(k)).t_pre/10+n_post_framenum);
        [~, i_maxy] = min(r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num_temp));
        frame_num = frame_num_temp(1:i_maxy+n_post_framenum);
        frame_num_all(k) = length(frame_num);

        times_this = r.VideoInfos_side(vid_press_idx(k)).VideoFrameTime(frame_num);
        traj_all{k} = [r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_x{idx_bodypart}(frame_num),...
            r.VideoInfos_side(vid_press_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_num)]';
        highest_point(k,:) = traj_all{k}(:,end-n_post_framenum)';
        t_all{k} = (0:10:10*(length(frame_num)-1))-10*(i_maxy-1);
        
        firing_rate_this = getFiringRate_spike_train(spike_counts_all,t_spike_counts,times_this,binwidth);
        firing_rate_all_flattened = [firing_rate_all_flattened,firing_rate_this];
        firing_rate_all(k,end-length(frame_num)+1:end) = firing_rate_this;
        y_all(k,end-length(frame_num)+1:end) = traj_all{k}(1,:);
    end    
    
%     firing_rate_all_flattened = sort(firing_rate_all_flattened);
%     firing_rate_max = firing_rate_all_flattened(floor(length(firing_rate_all_flattened)*color_max_percentage));
%     firing_rate_min = firing_rate_all_flattened(ceil(length(firing_rate_all_flattened)*color_min_percentage)+1);
%     temp = (firing_rate_all-firing_rate_min)./(firing_rate_max-firing_rate_min);
    mean_firing_rate(idx_path,:) = mean(firing_rate_all,'omitnan');
    mean_firing_rate(idx_path,:) = (mean_firing_rate(idx_path,:)-mean(mean_firing_rate(idx_path,:),'all','omitnan'))./std(mean_firing_rate(idx_path,:),0,'all','omitnan');
    mean_y(idx_path,:) = mean(y_all,'omitnan');
end

% mean_firing_rate(mean_firing_rate<0) = 0;
% mean_firing_rate(mean_firing_rate>1) = 1;

%%
idx_nan = find(isnan(mean(mean_firing_rate,1)),1,'last')+1;

idx_nan = idx_nan + 25;
end_shift = 15;

marker_size = 30;
colors_num = 256;
colors = parula(256);
h = figure('Renderer','opengl');
ax = axes(h,'NextPlot','add');
%     image(ax0_yt,bg);
set(ax,'YDir','reverse','XDir','reverse')
title(ax,'All (y vs t)');
c0_yt = colorbar();
ylabel(c0_yt,'Normalized firing rate','FontSize',10);
ax.XAxis.Visible = 'off';ax.YAxis.Visible = 'off'; 

for k = 1:size(mean_y,1)
    hold on
    scatter(ax,...
        1:size(mean_y(k,idx_nan:end-end_shift),2),...
        mean_y(k,idx_nan:end-end_shift)+20*k,...
        marker_size,...
        mean_firing_rate(k,idx_nan:end-end_shift),'filled');
end
    

    
    
%%
firing_rate_cut = mean_firing_rate(:,idx_nan:end-end_shift);
% firing_rate_cut(firing_rate_cut>2) = 2;
% firing_rate_cut(firing_rate_cut>2) = 2;
y_cut = mean_y(:,idx_nan:end-end_shift);

% interpolate
dt = 0.1;
firing_rate_new = zeros(size(firing_rate_cut,1),length(1:dt:size(firing_rate_cut,2)));
for k = 1:size(firing_rate_cut,1)
    firing_rate_new(k,:) = interp1(1:length(firing_rate_cut(k,:)),firing_rate_cut(k,:),1:dt:length(firing_rate_cut(k,:)));
end

y_all_mean = mean(y_cut);
y_all_mean_new = zeros(length(1:dt:length(y_all_mean)),1);
y_all_mean_new = interp1(1:length(y_all_mean),y_all_mean,1:dt:length(y_all_mean));

[~,max_idx] = max(firing_rate_new,[],2);

[~,idx_sort] = sort(max_idx,'descend');


h2 = figure('Renderer','opengl');
ax2 = axes(h2,'NextPlot','add');
%     image(ax0_yt,bg);
set(ax2,'YDir','reverse','XDir','reverse')
title(ax2,'All (y vs t)');
c0_yt = colorbar();
ylabel(c0_yt,'Normalized firing rate','FontSize',10);
ax2.XAxis.Visible = 'off';ax2.YAxis.Visible = 'off'; 

for k = 1:size(mean_y,1)
    hold on
    scatter(ax2,...
        1:length(firing_rate_new),...
        y_all_mean_new+5*k,...
        marker_size,...
        firing_rate_new(idx_sort(k),:),'filled');
end
    
    
print(h2,'TrajetoryCellAll.png','-dpng','-r1200')
    
    
    
    
    
    