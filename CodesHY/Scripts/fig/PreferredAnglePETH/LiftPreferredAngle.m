r_traj_all = {
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',... % r_path
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220505_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220512_video\RTarrayAll.mat'
};
%% Uncomment this seciton to re-extract spike time
% count = 0;
% Neurons = [];
% 
% for r_idx = 1:length(r_traj_all)
%     load(r_traj_all{r_idx})
%     
%     traj1_idx = getIndexVideoInfos(r,"Hand","Left","Performance","Correct","Trajectory",1,'LiftStartTimeLabeled','On');
%     traj2_idx = getIndexVideoInfos(r,"Hand","Left","Performance","Correct","Trajectory",2,'LiftStartTimeLabeled','On');
%     disp(['Loading from file: ',r_traj_all{r_idx}]);
%     disp(['Number of trials in trajectory 1: ',num2str(length(traj1_idx))]);
%     disp(['Number of trials in trajectory 2: ',num2str(length(traj2_idx))]);
% 
%     idx_all = [r.VideoInfos_side.Index];
%     traj1_vid_idx = findSeq(idx_all,traj1_idx);
%     traj2_vid_idx = findSeq(idx_all,traj2_idx);
%     
%     traj1_lift_time = [r.VideoInfos_side(traj1_vid_idx).LiftStartTime];
%     traj2_lift_time = [r.VideoInfos_side(traj2_vid_idx).LiftStartTime];
%     
%     for k = 1:length(r.Units.SpikeTimes)
%         if r.Units.SpikeNotes(k,3) ~= 1
%             continue
%         end
% 
%         count = count+1;
% 
%         Neurons(count).spike_time = r.Units.SpikeTimes(k).timings;
%         Neurons(count).lift_times{1} = traj1_lift_time;
%         Neurons(count).lift_times{2} = traj2_lift_time;
%     end
% end
% 
% save Neurons_traj_lift.mat Neurons
%% Extract PETH
clear
load Neurons_traj_lift.mat

t_pre_lift = -500;
t_post_lift = 500;
binwidth_lift = 1;

params_lift.pre = -t_pre_lift;
params_lift.post = t_post_lift;
params_lift.binwidth = binwidth_lift;

psthPreffered_lift = [];
psthNonPreffered_lift = [];
preference_index_lift = [];
for k = 1:length(Neurons)
    [psth1_lift, psth2_lift, tpsth_lift, pi_lift] = ExtractPETH(Neurons(k).spike_time,Neurons(k).lift_times,params_lift);

    psthPreffered_lift = [psthPreffered_lift;psth1_lift];
    psthNonPreffered_lift = [psthNonPreffered_lift;psth2_lift];
    preference_index_lift = [preference_index_lift, pi_lift];
end

% sort by max response time
[~, max_t] = max(psthPreffered_lift,[],2);
[~, sort_idx] = sort(max_t);
psthPreffered_lift = psthPreffered_lift(sort_idx,:);
psthNonPreffered_lift = psthNonPreffered_lift(sort_idx,:);

%% Make figures press PETH
fig = EasyPlot.figure('Width',10,'Height',10);
ax_preferred = EasyPlot.createAxesAgainstFigure(fig,"leftTop",...
    "Height",3,...
    'Width',5,...
    'MarginLeft',0.8);
ax_nonpreferred = EasyPlot.createAxesAgainstAxes(fig,ax_preferred,'bottom',...
    'Height',3,...
    'Width',5,...
    'MarginLeft',0.8,...
    'MarginBottom',0.8);

imagesc(ax_preferred,psthPreffered_lift,'XData',tpsth_lift);
imagesc(ax_nonpreferred,psthNonPreffered_lift,'XData',tpsth_lift);

EasyPlot.setYLim({ax_preferred,ax_nonpreferred},[0.5,length(Neurons)+0.5]);
EasyPlot.setCLim({ax_preferred,ax_nonpreferred});

EasyPlot.colorbar(ax_preferred,...
    "label",'Normalized firing rate',...
    'colormap', EasyPlot.ColorMap.Diverging.seismic,...
    'zeroCenter', true,...
    'MarginRight',0.8);
EasyPlot.colorbar(ax_nonpreferred,...
    "label",'Normalized firing rate',...
    'colormap', EasyPlot.ColorMap.Diverging.seismic,...
    'zeroCenter', true,...
    'MarginRight',0.8);

yticks(ax_preferred,[1,length(Neurons)]);
yticks(ax_nonpreferred,[1,length(Neurons)]);

EasyPlot.setYLabelColumn({ax_preferred,ax_nonpreferred},'Neurons')
EasyPlot.setXLabelColumn({ax_preferred,ax_nonpreferred},'Time from lift (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'LiftPETH','type','png','dpi',1200)
%% Preferrence Index Histogram
fig = EasyPlot.figure();
ax_lift = EasyPlot.createAxesAgainstFigure(fig,"leftTop",'Height',3,'Width',3,...
    'MarginBottom',0.8,'MarginLeft',0.8);
histogram(ax_lift,preference_index_lift,'BinWidth',0.1);
xlim([0,1])
xticks([0,0.5,1]);
xlabel('PI of lift')
ylabel('Number of neurons')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'PreferenceIndexHistogramLift','dpi',1200);
