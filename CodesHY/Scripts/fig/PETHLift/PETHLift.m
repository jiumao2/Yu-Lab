r_all = {
    'D:\Ephys\ANMs\Urey\Videos\20211124_video\RTarrayAll.mat',... % r_path
    'D:\Ephys\ANMs\Eli\Sessions\20210923_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Russo\Sessions\20210820_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220331_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220426_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220505_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Davis\Video\20220512_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220519_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Russo\Sessions\20210908_video\RTarrayAll.mat'
};

%% Extract spike time
count = 0;
Neurons = [];

for r_idx = 1:length(r_all)
    load(r_all{r_idx})
    
    idx = getIndexVideoInfos(r,...
        "Hand","Left",...
        "Performance","Correct",...
        "Trajectory",'All',...
        'LiftStartTimeLabeled','On');
    disp(['Loading from file: ',r_all{r_idx}]);
    disp(['Number of trials: ',num2str(length(idx))]);
    disp(['Number of neurons: ',num2str(length(r.Units.SpikeTimes))]);

    idx_all = [r.VideoInfos_side.Index];
    vid_idx = findSeq(idx_all,idx);
    
    lift_time = [r.VideoInfos_side(vid_idx).LiftStartTime];
    
    for k = 1:length(r.Units.SpikeTimes)
        if r.Units.SpikeNotes(k,3) ~= 1
            continue
        end

        count = count+1;

        Neurons(count).spike_time = r.Units.SpikeTimes(k).timings;
        Neurons(count).lift_times = lift_time;
    end
end

save Neurons.mat Neurons

%% Extract PETH
clear
load Neurons.mat

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
EasyPlot.exportFigure(fig,'LiftPETH','type','png','dpi',1200)



