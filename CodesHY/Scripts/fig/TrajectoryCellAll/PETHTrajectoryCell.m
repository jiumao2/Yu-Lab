SetNeurons;
%% Extract spike time
count = 0;
Neurons = [];

for r_idx = 1:3:length(r_traj_all)

    if ~(r_idx>1 && strcmp(r_traj_all{r_idx},r_traj_all{r_idx-3}))
        load(r_traj_all{r_idx})
        disp(['Loading from file: ',r_traj_all{r_idx}]);
    end
    
    idx = getIndexVideoInfos(r,...
        "Hand","Left",...
        "Performance","Correct",...
        "Trajectory",r_traj_all{r_idx+2},...
        'LiftStartTimeLabeled','On');

    idx_all = [r.VideoInfos_side.Index];
    vid_idx = findSeq(idx_all,idx);
    
    lift_time = [r.VideoInfos_side(vid_idx).LiftStartTime];
    

    count = count+1;
    Neurons(count).spike_time = r.Units.SpikeTimes(r_traj_all{r_idx+1}).timings;
    Neurons(count).lift_times = lift_time;
end

save Neurons.mat Neurons

%% Extract PETH
clear
load Neurons.mat

t_pre = -1000;
t_post = 500;
binwidth = 1;

params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth;

psth_lift = [];
for k = 1:length(Neurons)

    params_temp = params;
    params_temp.pre = 2000;
    params_temp.pose = 2000;
    [psth_temp, ~] = jpsth(Neurons(k).spike_time, Neurons(k).lift_times', params_temp);

    [psth, tpsth] = jpsth(Neurons(k).spike_time, Neurons(k).lift_times', params);
    psth = smoothdata(psth,'gaussian',50);    

    mean_psth = mean(psth_temp);
    std_psth = std(psth_temp);

    psth = (psth-mean_psth)./std_psth;
    psth_lift = [psth_lift;psth];
end

% sort by max response time
[~, max_t] = max(psth_lift,[],2);
[~, sort_idx] = sort(max_t);
psth_lift = psth_lift(sort_idx,:);

%% Make figures press PETH
fig = EasyPlot.figure('Width',10,'Height',10);
ax_peth = EasyPlot.createAxesAgainstFigure(fig,"leftTop",...
    "Height",3,...
    'Width',5,...
    'MarginLeft',0.8,...
    'MarginBottom',0.8);

imagesc(ax_peth,psth_lift,'XData',tpsth);

EasyPlot.setYLim(ax_peth,[0.5,length(Neurons)+0.5]);

EasyPlot.colorbar(ax_peth,...
    "label",'Normalized firing rate',...
    'colormap', EasyPlot.ColorMap.Diverging.seismic,...
    'zeroCenter', true,...
    'MarginRight',0.8);

yticks(ax_peth,[1,length(Neurons)]);

ylabel(ax_peth,'Neurons')
xlabel(ax_peth,'Time from lift (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'LiftPETHTrajectoryCell','type','png','dpi',1200)



