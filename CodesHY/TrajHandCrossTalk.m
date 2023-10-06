function TrajHandCrossTalk(r)
n_traj = max([r.VideoInfos_top.Trajectory])-1;
n_segment = length(r.Meta);

t_segment_start = zeros(1,n_segment);
for k = 1:n_segment
    t_segment_start(k) = get_t_start_session(r,k);
end

traj_count = zeros(n_segment,n_traj);
left_hand_count = zeros(n_segment,n_traj);

for k = 1:length(r.VideoInfos_top)
    i_segment = find(r.VideoInfos_side(k).Time-t_segment_start>0, 1, 'last');
    traj = r.VideoInfos_top(k).Trajectory;
    hand = r.VideoInfos_side(k).Hand;
    
    if isempty(traj) || traj>n_traj || isempty(hand) || all(isnan(hand))
        continue
    end

    traj_count(i_segment, traj) = traj_count(i_segment, traj)+1;
    if strcmpi(hand, 'left')
        left_hand_count(i_segment, traj) = left_hand_count(i_segment, traj)+1;
    end
end
%%
fig = EasyPlot.figure('MarginBottom',0);
ax_all = EasyPlot.createGridAxes(fig,2,n_segment);

traj_proportion = traj_count./sum(traj_count,2);
left_hand_proportion = left_hand_count./sum(left_hand_count,2);

for k = 1:n_segment
    bar(ax_all{1,k}, traj_proportion(k,:));
    bar(ax_all{2,k}, left_hand_proportion(k,:));
end

EasyPlot.setYLim(ax_all(1,:));
EasyPlot.setYLim(ax_all(2,:));
EasyPlot.setXLim(ax_all, [0.5, n_traj+0.5]);
EasyPlot.set(ax_all, 'XTick', 1:n_traj);

ylabel(ax_all{1,1}, 'Traj preferrence');
ylabel(ax_all{2,1}, 'Hand preferrence');
EasyPlot.HideYAxis(ax_all(:,2:end));
EasyPlot.setGeneralXLabel(ax_all(2,:), 'Traj #');
EasyPlot.setGeneralTitle(ax_all(1,:),...
    [r.Meta(1).Subject,' ',datestr(r.Meta(1).DateTime, 'yyyymmdd')]);
EasyPlot.set(ax_all(1,:), 'MarginLeft', 0.8);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, ['TrajHandCrossTalk',r.Meta(1).Subject,'_',datestr(r.Meta(1).DateTime, 'yyyymmdd')]);
end



