load RTarrayAll.mat
camview = 'side';
frame_range = 1:r.VideoInfos_side(1).total_frames;
units = 1:length(r.Units.SpikeTimes);
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

    date_this = [num2str(r.Meta(1).DateTimeRaw(1),'%04d'),num2str(r.Meta(1).DateTimeRaw(2),'%02d'),num2str(r.Meta(1).DateTimeRaw(4),'%02d')];
    notes = {[r.Meta(1).Subject,' ',date_this,' Trial No.',num2str(idx)],...
        ['Performance: ',VideoInfos_this(i).Performance,...
        '; FP=',num2str(VideoInfos_this(i).Foreperiod),...
        'ms; RT=',num2str(VideoInfos_this(i).ReactTime),...
        'ms;']};
    
    % Trajectory
    if isfield(r.VideoInfos_top(i),'Trajectory')
        if ~isempty(r.VideoInfos_top(i).Trajectory) && (r.VideoInfos_top(i).Trajectory==1 || r.VideoInfos_top(i).Trajectory==2)
            traj = ['No.',num2str(r.VideoInfos_top(i).Trajectory)];
        else
            traj = 'None';
        end    
        notes = [notes,'Traj: ',traj];
    end
    
    t_seq = VideoInfos_this(i).VideoFrameTime - VideoInfos_this(i).Time;

    spiketime_seq = cell(1,length(units));
    for k = 1:length(units)
        spiketime_seq{k} = VideoInfos_this(i).Units.SpikeTimes(units(k)).timings - VideoInfos_this(i).Time;
    end
    
    vid_read = VideoReader(['.\VideoFrames_',camview,'\RawVideo\',VideoInfos_this(1).Event,num2str(idx,'%03d'),'.avi']);
    
    img_seq = cell(1,length(frame_range));
    for k = 1:length(frame_range)
        img_seq{k} = vid_read.read(frame_range(k));
    end

    moviename = ['.\VideoFrames_',camview,'\Video\',VideoInfos_this(1).Event,num2str(idx,'%03d'),'.avi'];
    MakeFrameRasterVideo(img_seq,spiketime_seq,t_seq,moviename,notes);
    
end