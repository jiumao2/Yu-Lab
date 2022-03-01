load RTarrayAll.mat
camview = 'top';
%%
if strcmp(camview,'side')
    VideoInfos_this = r.VideoInfos_side;
elseif strcmp(camview,'top')
    VideoInfos_this = r.VideoInfos_top;
end

if ~exist(['.\VideoFrames_',camview,'\Video\'],'dir')
    mkdir(['.\VideoFrames_',camview,'\Video\']);
end

for i = 1:length(VideoInfos_this)
    idx = VideoInfos_this(i).Index;

    
    notes = ['Performance: ',VideoInfos_this(i).Performance,...
        '; FP=',num2str(VideoInfos_this(i).Foreperiod),...
        'ms; RT=',num2str(VideoInfos_this(i).ReactTime),...
        'ms;'];
    
    % Trajectory
    if isfield(VideoInfos_this(i),'Trajectory')
        if ~isempty(VideoInfos_this(i).Trajectory) && (VideoInfos_this(i).Trajectory==1 || VideoInfos_this(i).Trajectory==2)
            traj = ['No.',num2str(VideoInfos_this(i).Trajectory)];
        else
            traj = 'None';
        end    
        notes = [notes,'Traj: ',traj];
    end
    
    t_seq = VideoInfos_this(i).VideoFrameTime - VideoInfos_this(i).Time;
    for k = 1:length(VideoInfos_this(i).Units.SpikeTimes)
        spiketime_seq{k} = VideoInfos_this(i).Units.SpikeTimes(k).timings - VideoInfos_this(i).Time;
    end
    
    vid_read = VideoReader(['.\VideoFrames_',camview,'\RawVideo\',VideoInfos_this(1).Event,num2str(idx,'%03d'),'.avi']);
    for k = 1:vid_read.NumFrames
        img_seq{k} = vid_read.read(k);
    end

    moviename = ['.\VideoFrames_',camview,'\Video\',VideoInfos_this(1).Event,num2str(idx,'%03d'),'.avi'];
    MakeFrameRasterVideo(img_seq,spiketime_seq,t_seq,moviename,notes);
    
end