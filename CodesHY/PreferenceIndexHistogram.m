function PreferenceIndexHistogram(r)
% 2023.3.17 by HY
t_pre_lift = -500;
t_post_lift = 500;
binwidth_lift = 1;
gaussian_kernel = 25;

params.pre = -t_pre_lift;
params.post = t_post_lift;
params.binwidth = binwidth_lift;

preference_index_press = [];
preference_index_release = [];
for k = 1:length(r.Units.SpikeTimes)
    idx_all = [r.VideoInfos_side.Index];
    idx_traj1 = getIndexVideoInfos(r,"Hand","Left","Trajectory",1);
    idx_traj2 = getIndexVideoInfos(r,"Hand","Left","Trajectory",2);
    vid_idx_traj1 = findSeq(idx_all, idx_traj1);
    vid_idx_traj2 = findSeq(idx_all, idx_traj2);
    press_times_traj1 = [r.VideoInfos_side(vid_idx_traj1).Time];
    press_times_traj2 = [r.VideoInfos_side(vid_idx_traj2).Time];
    release_times_traj1 = [r.VideoInfos_side(vid_idx_traj1).Time] + [r.VideoInfos_side(vid_idx_traj1).Foreperiod] + [r.VideoInfos_side(vid_idx_traj1).ReactTime]; 
    release_times_traj2 = [r.VideoInfos_side(vid_idx_traj2).Time] + [r.VideoInfos_side(vid_idx_traj2).Foreperiod] + [r.VideoInfos_side(vid_idx_traj2).ReactTime]; 
    [psth1, ~] = jpsth(r.Units.SpikeTimes(k).timings, press_times_traj1', params);
    [psth2, ~] = jpsth(r.Units.SpikeTimes(k).timings, press_times_traj2', params);

    psth1 = smoothdata(psth1,'gaussian',gaussian_kernel*5);
    psth2 = smoothdata(psth2,'gaussian',gaussian_kernel*5);   
    if max(psth2)>max(psth1)
        [psth1, psth2] = swap(psth1, psth2);
    end
    pi_press = preferenceIndex(max(psth1),max(psth2));
    preference_index_press = [preference_index_press, pi_press];

    [psth1, ~] = jpsth(r.Units.SpikeTimes(k).timings, release_times_traj1', params);
    [psth2, ~] = jpsth(r.Units.SpikeTimes(k).timings, release_times_traj2', params);

    psth1 = smoothdata(psth1,'gaussian',gaussian_kernel*5);
    psth2 = smoothdata(psth2,'gaussian',gaussian_kernel*5);   
    if max(psth2)>max(psth1)
        [psth1, psth2] = swap(psth1, psth2);
    end
    pi_release = preferenceIndex(max(psth1),max(psth2));
    preference_index_release = [preference_index_release, pi_release];    
end
%% Preferrence Index Histogram
fig = EasyPlot.figure();
ax_press = EasyPlot.createAxesAgainstFigure(fig,"leftTop",'Height',3,'Width',3,...
    'MarginBottom',0.8,'MarginLeft',0.8);
ax_release = EasyPlot.createAxesAgainstAxes(fig, ax_press, "right");

histogram(ax_press,preference_index_press,'BinWidth',0.1);
histogram(ax_release,preference_index_release,'BinWidth',0.1);
EasyPlot.setXLim({ax_press,ax_release},[0,1]);
EasyPlot.setXTicks({ax_press,ax_release},[0,0.5,1]);
xlabel(ax_press, 'PI of press')
xlabel(ax_release, 'PI of release')
ylabel(ax_press, 'Number of neurons')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'Fig/PreferenceIndexHistogram','type','png','dpi',1200);

end