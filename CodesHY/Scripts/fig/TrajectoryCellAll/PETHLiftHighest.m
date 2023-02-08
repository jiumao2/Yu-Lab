SetNeurons;

bodypart = 'left_paw';
frame_pre = 100;
frame_post = 20;
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
    
    idx_bodypart = find(strcmp(r.VideoInfos_side(1).Tracking.BodyParts,bodypart));
    
    lift_highest_time = zeros(1,length(idx_all));
    traj = zeros(1,1+frame_pre+frame_post);
    for k = 1:length(vid_idx)
        frame_start = r.VideoInfos_side(vid_idx(k)).LiftStartFrameNum;
        frame_end = round(-r.VideoInfos_side(vid_idx(k)).t_pre/10);
        
        frame_range = frame_start:frame_end;
        [~, idx_highest] = min(r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_range));
        frame_highest = frame_range(idx_highest);

        lift_highest_time(k) = r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_highest);
    end

    count = count+1;
    Neurons(count).spike_time = r.Units.SpikeTimes(r_traj_all{r_idx+1}).timings;
    Neurons(count).lift_highest_time = lift_highest_time;
    Neurons(count).traj = traj;
end

save Neurons_lift_highest.mat Neurons

%% Extract PETH
clear
load Neurons_lift_highest.mat

t_pre = -500;
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
    [psth_temp, ~] = jpsth(Neurons(k).spike_time, Neurons(k).lift_highest_time', params_temp);

    [psth, tpsth] = jpsth(Neurons(k).spike_time, Neurons(k).lift_highest_time', params);
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
EasyPlot.exportFigure(fig,'LiftHighestPETHTrajectoryCell','type','png','dpi',1200)



