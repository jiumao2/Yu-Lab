r_hand_all = {
    'D:\Ephys\ANMs\Chen\Video\20220507_video\RTarrayAll.mat',... % r_path
    'D:\Ephys\ANMs\Chen\Video\20220513_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220519_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Chen\Video\20220606_video\RTarrayAll.mat',...
    'D:\Ephys\ANMs\Russo\Sessions\20210908_video\RTarrayAll.mat'
};

%% Uncomment this seciton to re-extract spike time
% count = 0;
% Neurons = [];
% 
% for r_idx = 1:length(r_hand_all)
%     load(r_hand_all{r_idx})
%     
%     hand1_idx = getIndexVideoInfos(r,"Hand","Left","Performance","Correct");
%     hand2_idx = getIndexVideoInfos(r,"Hand","Right_Both","Performance","Correct");
%     disp(['Loading from file: ',r_hand_all{r_idx}]);
%     disp(['Number of trials in hand 1: ',num2str(length(hand1_idx))]);
%     disp(['Number of trials in hand 2: ',num2str(length(hand2_idx))]);
% 
%     idx_all = [r.VideoInfos_side.Index];
%     hand1_vid_idx = findSeq(idx_all,hand1_idx);
%     hand2_vid_idx = findSeq(idx_all,hand2_idx);
%     
%     hand1_press_time = [r.VideoInfos_side(hand1_vid_idx).Time];
%     hand2_press_time = [r.VideoInfos_side(hand2_vid_idx).Time];
%     
%     hand1_trigger_time = hand1_press_time+[r.VideoInfos_side(hand1_vid_idx).Foreperiod];
%     hand2_trigger_time = hand2_press_time+[r.VideoInfos_side(hand2_vid_idx).Foreperiod];
%     
%     hand1_release_time = hand1_trigger_time+[r.VideoInfos_side(hand1_vid_idx).ReactTime];
%     hand2_release_time = hand2_trigger_time+[r.VideoInfos_side(hand2_vid_idx).ReactTime];
%     
%     for k = 1:length(r.Units.SpikeTimes)
%         if r.Units.SpikeNotes(k,3) ~= 1
%             continue
%         end
% 
%         count = count+1;
% 
%         Neurons(count).spike_time = r.Units.SpikeTimes(k).timings;
%         Neurons(count).press_times{1} = hand1_press_time;
%         Neurons(count).press_times{2} = hand2_press_time;
%         Neurons(count).trigger_times{1} = hand1_trigger_time;
%         Neurons(count).trigger_times{2} = hand2_trigger_time;
%         Neurons(count).release_times{1} = hand1_release_time;
%         Neurons(count).release_times{2} = hand2_release_time;
%     end
% end
% 
% save Neurons_hand.mat Neurons
%% Extract PETH
clear
load Neurons_hand.mat

t_pre_press = -500;
t_post_press = 500;
binwidth_press = 1;

params_press.pre = -t_pre_press;
params_press.post = t_post_press;
params_press.binwidth = binwidth_press;

t_pre_trigger = -500;
t_post_trigger = 500;
binwidth_trigger = 1;

params_trigger.pre = -t_pre_trigger;
params_trigger.post = t_post_trigger;
params_trigger.binwidth = binwidth_trigger;

t_pre_release = -500;
t_post_release = 500;
binwidth_release = 1;

params_release.pre = -t_pre_release;
params_release.post = t_post_release;
params_release.binwidth = binwidth_release;

psthPreffered_press = [];
psthNonPreffered_press = [];
psthPreffered_trigger = [];
psthNonPreffered_trigger = [];
psthPreffered_release = [];
psthNonPreffered_release = [];
preference_index_press = [];
preference_index_trigger = [];
preference_index_release = [];
difference_index_press = [];
difference_index_trigger = [];
difference_index_release = [];
for k = 1:length(Neurons)
    [psth1_press, psth2_press, tpsth_press, pi_press, diff_press] = ExtractPETH(Neurons(k).spike_time,Neurons(k).press_times,params_press);
    [psth1_trigger, psth2_trigger,  tpsth_trigger, pi_trigger, diff_trigger] = ExtractPETH(Neurons(k).spike_time,Neurons(k).trigger_times,params_trigger);
    [psth1_release, psth2_release,  tpsth_release, pi_release, diff_release] = ExtractPETH(Neurons(k).spike_time,Neurons(k).release_times,params_release);

    psthPreffered_press = [psthPreffered_press;psth1_press];
    psthNonPreffered_press = [psthNonPreffered_press;psth2_press];
    psthPreffered_trigger = [psthPreffered_trigger;psth1_trigger];
    psthNonPreffered_trigger = [psthNonPreffered_trigger;psth2_trigger];
    psthPreffered_release = [psthPreffered_release;psth1_release];
    psthNonPreffered_release = [psthNonPreffered_release;psth2_release];
    preference_index_press = [preference_index_press, pi_press];
    preference_index_trigger = [preference_index_trigger, pi_trigger];
    preference_index_release = [preference_index_release, pi_release];
    difference_index_press = [difference_index_press, diff_press];
    difference_index_trigger = [difference_index_trigger, diff_trigger];
    difference_index_release = [difference_index_release, diff_release];
end

% sort by max response time
[~, max_t] = max(psthPreffered_press,[],2);
[~, sort_idx] = sort(max_t);
psthPreffered_press = psthPreffered_press(sort_idx,:);
psthNonPreffered_press = psthNonPreffered_press(sort_idx,:);

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

imagesc(ax_preferred,psthPreffered_press,'XData',tpsth_press);
imagesc(ax_nonpreferred,psthNonPreffered_press,'XData',tpsth_press);

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
EasyPlot.setXLabelColumn({ax_preferred,ax_nonpreferred},'Time from press (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'HandPressPETH','type','png','dpi',1200)

%% Trigger PETH figure
% sort by max response time
[~, max_t] = max(psthPreffered_trigger,[],2);
[~, sort_idx] = sort(max_t);
psthPreffered_trigger = psthPreffered_trigger(sort_idx,:);
psthNonPreffered_trigger = psthNonPreffered_trigger(sort_idx,:);

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

imagesc(ax_preferred,psthPreffered_trigger,'XData',tpsth_press);
imagesc(ax_nonpreferred,psthNonPreffered_trigger,'XData',tpsth_press);

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
EasyPlot.setXLabelColumn({ax_preferred,ax_nonpreferred},'Time from trigger (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'HandTriggerPETH','type','png','dpi',1200)

%% Release PETH figure
% sort by max response time
[~, max_t] = max(psthPreffered_release,[],2);
[~, sort_idx] = sort(max_t);
psthPreffered_release = psthPreffered_release(sort_idx,:);
psthNonPreffered_release = psthNonPreffered_release(sort_idx,:);

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

imagesc(ax_preferred,psthPreffered_release,'XData',tpsth_press);
imagesc(ax_nonpreferred,psthNonPreffered_release,'XData',tpsth_press);

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
EasyPlot.setXLabelColumn({ax_preferred,ax_nonpreferred},'Time from release (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'HandReleasePETH','type','png','dpi',1200)
%% Preferrence Index Histogram
fig = EasyPlot.figure();
ax_press = EasyPlot.createAxesAgainstFigure(fig,"leftTop",'Height',3,'Width',3,...
    'MarginBottom',0.8,'MarginLeft',0.8);
histogram(ax_press,preference_index_press,'BinWidth',0.1);
xlabel('PI of press')

ax_trigger = EasyPlot.createAxesAgainstAxes(fig,ax_press,'right','Height',3,'Width',3);
histogram(ax_trigger,preference_index_trigger,'BinWidth',0.1);
xlabel('PI of trigger')

ax_release = EasyPlot.createAxesAgainstAxes(fig,ax_trigger,'right','Height',3,'Width',3);
histogram(ax_release,preference_index_release,'BinWidth',0.1);
xlabel('PI of release')

EasyPlot.setXTicks({ax_press,ax_trigger,ax_release},[0,0.5,1]);
EasyPlot.setXLim({ax_press,ax_trigger,ax_release},[0,1]);
EasyPlot.setYLim({ax_press,ax_trigger,ax_release});
EasyPlot.setYLabelRow({ax_press,ax_trigger,ax_release},'Number of neurons')
EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'PreferenceIndexHistogramHand','dpi',1200);
%% Preferrence Index Histogram
fig = EasyPlot.figure();
ax_press = EasyPlot.createAxesAgainstFigure(fig,"leftTop",'Height',3,'Width',3,...
    'MarginBottom',0.8,'MarginLeft',0.8);
histogram(ax_press,difference_index_press,'BinWidth',0.1);
xlabel('PI of press')

ax_trigger = EasyPlot.createAxesAgainstAxes(fig,ax_press,'right','Height',3,'Width',3);
histogram(ax_trigger,difference_index_trigger,'BinWidth',0.1);
xlabel('PI of trigger')

ax_release = EasyPlot.createAxesAgainstAxes(fig,ax_trigger,'right','Height',3,'Width',3);
histogram(ax_release,difference_index_release,'BinWidth',0.1);
xlabel('PI of release')

EasyPlot.setXTicks({ax_press,ax_trigger,ax_release},[-1,-0.5,0,0.5,1]);
EasyPlot.setXLim({ax_press,ax_trigger,ax_release},[-1,1]);
EasyPlot.setYLim({ax_press,ax_trigger,ax_release});
EasyPlot.setYLabelRow({ax_press,ax_trigger,ax_release},'Number of neurons')
EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'DifferenceIndexHistogramHand','dpi',1200);
