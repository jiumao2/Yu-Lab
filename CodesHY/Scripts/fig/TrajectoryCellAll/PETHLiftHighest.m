SetNeurons;

bodypart = 'left_paw';
frame_pre = 30;
frame_post = 30;
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
    traj = cell(1,length(vid_idx));
    traj_pre = nan(length(vid_idx),frame_pre);
    traj_post = nan(length(vid_idx),frame_post);

    t_traj = cell(1,length(vid_idx));
    t_traj_pre = nan(length(vid_idx),frame_pre);
    t_traj_post = nan(length(vid_idx),frame_post);
    for k = 1:length(vid_idx)
        % Extract lift highest time
        frame_start = r.VideoInfos_side(vid_idx(k)).LiftStartFrameNum;
        frame_end = round(-r.VideoInfos_side(vid_idx(k)).t_pre/10);
        
        frame_range = frame_start:frame_end;
        [~, idx_highest] = min(r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_range));
        frame_highest = frame_range(idx_highest);

        lift_highest_time(k) = r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_highest);
        traj{k} = r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_start:frame_highest);
        t_traj{k} = r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_start:frame_highest)-r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_highest);
        
        % Extract frame previous to lift start
        frame_start = r.VideoInfos_side(vid_idx(k)).LiftStartFrameNum;
        while frame_start-1 >= max(r.VideoInfos_side(vid_idx(k)).LiftStartFrameNum-frame_pre,1)...
                && r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_p{idx_bodypart}(frame_start-1) > 0.8
            frame_start = frame_start-1;
        end

        frame_end = r.VideoInfos_side(vid_idx(k)).LiftStartFrameNum-1;
        frame_range = frame_start:frame_end;
        traj_pre(k,end-length(frame_range)+1:end) = r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_range);
        t_traj_pre(k,end-length(frame_range)+1:end) = r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_range)-r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_highest);

        % Extract frame post to lift start
%         frame_end = frame_highest;
%         while frame_end+1 <= min(frame_highest+frame_post,r.VideoInfos_side(vid_idx(k)).total_frames).....
%                 && r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_p{idx_bodypart}(frame_end+1) > 0.8
%             frame_end = frame_end+1;
%         end
        frame_end = frame_highest+frame_post;

        frame_start = frame_highest+1;
        frame_range = frame_start:frame_end;
        traj_post(k,1:length(frame_range)) = r.VideoInfos_side(vid_idx(k)).Tracking.Coordinates_y{idx_bodypart}(frame_range);    
        t_traj_post(k,1:length(frame_range)) = r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_range)-r.VideoInfos_side(vid_idx(k)).VideoFrameTime(frame_highest);
    end

    count = count+1;
    Neurons(count).spike_time = r.Units.SpikeTimes(r_traj_all{r_idx+1}).timings;
    Neurons(count).lift_highest_time = lift_highest_time;
    Neurons(count).traj = traj;
    Neurons(count).traj_pre = traj_pre;
    Neurons(count).traj_post = traj_post;

    Neurons(count).t_traj = t_traj;
    Neurons(count).t_traj_pre = t_traj_pre;
    Neurons(count).t_traj_post = t_traj_post;
end

save Neurons_lift_highest.mat Neurons frame_pre frame_post

%% Extract PETH
clear
load Neurons_lift_highest.mat

t_pre = -500;
t_post = 500;
binwidth = 1;

params.pre = -t_pre;
params.post = t_post;
params.binwidth = binwidth;

psth_lift_unsorted = [];
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
    psth_lift_unsorted = [psth_lift_unsorted;psth];
end

% sort by max response time
[~, max_t] = max(psth_lift_unsorted,[],2);
[~, sort_idx] = sort(max_t);
psth_lift = psth_lift_unsorted(sort_idx,:);

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
xlabel(ax_peth,'Time from lift highest (ms)')

EasyPlot.cropFigure(fig)
EasyPlot.exportFigure(fig,'LiftHighestPETHTrajectoryCell','type','png','dpi',1200)

%% Mean traj
NpointTraj = 200;

traj_all = [];
traj_pre_all = [];
traj_post_all = [];
traj_length_all = [];
t_traj_all = [];
t_Neurons = [];

for k = 1:length(Neurons)
    for j = 1:length(Neurons(k).traj)
        traj_length_all = [traj_length_all, length(Neurons(k).traj{j})];
    end
end

NpointPre = round((NpointTraj-1)*frame_pre/mean(traj_length_all-1)+1);
NpointPost = round((NpointTraj-1)*frame_post/mean(traj_length_all-1)+1);

for k = 1:length(Neurons)
    t_Neuron = [];
    for j = 1:length(Neurons(k).traj)
        traj_interpolated = interp1(...
            1:length(Neurons(k).traj{j}),...
            Neurons(k).traj{j},...
            linspace(1,length(Neurons(k).traj{j}),NpointTraj));
        t_traj_interpolated = interp1(...
            1:length(Neurons(k).t_traj{j}),...
            Neurons(k).t_traj{j},...
            linspace(1,length(Neurons(k).t_traj{j}),NpointTraj));

        traj_pre_interpolated = interp1(...
            0:frame_pre,...
            [Neurons(k).traj_pre(j,:),Neurons(k).traj{j}(1)],...
            linspace(0,frame_pre,NpointPre));
        t_traj_pre_interpolated = interp1(...
            0:frame_pre,...
            [Neurons(k).t_traj_pre(j,:),Neurons(k).t_traj{j}(1)],...
            linspace(0,frame_pre,NpointPre));

        traj_post_interpolated = interp1(...
            0:frame_post,...
            [Neurons(k).traj{j}(end),Neurons(k).traj_post(j,:)],...
            linspace(0,frame_post,NpointPost));
        t_traj_post_interpolated = interp1(...
            0:frame_post,...
            [Neurons(k).t_traj{j}(end),Neurons(k).t_traj_post(j,:)],...
            linspace(0,frame_post,NpointPost));

        traj_all = [traj_all; [traj_pre_interpolated(1:end-1),traj_interpolated,traj_post_interpolated(2:end)]]; % remove repeated points
        t_traj_all = [t_traj_all; [t_traj_pre_interpolated(1:end-1),t_traj_interpolated,t_traj_post_interpolated(2:end)]];
        t_Neuron = [t_Neuron; [t_traj_pre_interpolated(1:end-1),t_traj_interpolated,t_traj_post_interpolated(2:end)]];
    end
    t_Neurons = [t_Neurons; mean(t_Neuron,'omitnan')];
end

meanTraj = mean(traj_all,'omitnan');

psth_unsorted = zeros(size(t_Neurons));
for k = 1:length(Neurons)

    params_temp = params;
    params_temp.pre = 1000;
    params_temp.pose = 1000;
    [psth_temp, tpsth_temp] = jpsth(Neurons(k).spike_time, Neurons(k).lift_highest_time', params_temp);
    psth_temp = smoothdata(psth_temp,'gaussian',50);    

    mean_psth = mean(psth_temp);
    std_psth = std(psth_temp);

    psth = (psth_temp-mean_psth)./std_psth;

    psth_unsorted(k,:) = interp1(tpsth_temp,psth,t_Neurons(k,:));
end
% sort by max response time
[~, max_t] = max(psth_unsorted,[],2);
[~, sort_idx] = sort(max_t,'descend');
psth = psth_unsorted(sort_idx,:);

%%
marker_size = 2;

fig_yt = EasyPlot.figure('Height',20,'Width',20);
ax_yt = EasyPlot.axes(fig_yt,...
    'YDir','reverse',...
    'XDir','reverse',...
    'Height',3,...
    'Width',5);
title(ax_yt,'y vs t');
for k = 1:size(psth,1)
    hold on
    scatter(ax_yt,...
        1:length(meanTraj),...
        meanTraj+10*k,...
        marker_size,...
        psth(k,:),'filled');
end

EasyPlot.colorbar(ax_yt,...
    "label",'Normalized firing rate',...
    'colormap', EasyPlot.ColorMap.Diverging.seismic,...
    'zeroCenter', true,...
    'MarginRight',0.8);
EasyPlot.setXLim(ax_yt,[0,length(meanTraj)+1]);

EasyPlot.HideXAxis(ax_yt);
EasyPlot.HideYAxis(ax_yt);

EasyPlot.cropFigure(fig_yt)
EasyPlot.exportFigure(fig_yt,'PETHTrajectoryCell','dpi',1200)





