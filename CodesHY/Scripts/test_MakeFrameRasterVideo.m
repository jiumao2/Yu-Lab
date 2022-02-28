load RTarrayAll.mat

for i = 1:length(r.VideoInfos)
    idx = r.VideoInfos(i).Index;
    if ~isempty(r.VideoInfos(i).Trajectory) && (r.VideoInfos(i).Trajectory==1 || r.VideoInfos(i).Trajectory==2)
        traj = ['No.',num2str(r.VideoInfos(i).Trajectory)];
    else
        traj = 'None';
    end
    
    notes = ['Performance: ',r.VideoInfos(i).Performance,...
        '; FP=',num2str(r.VideoInfos(i).Foreperiod),...
        'ms; RT=',num2str(r.VideoInfos(i).ReactTime),...
        'ms; Traj: ',traj];
    
    t_seq = r.VideoInfos(i).VideoFrameTime - r.VideoInfos(i).Time;
    for k = 1:length(r.VideoInfos(i).Units.SpikeTimes)
        spiketime_seq{k} = r.VideoInfos(i).Units.SpikeTimes(k).timings - r.VideoInfos(i).Time;
    end
    
    vid_read = VideoReader(['Urey20211124_video\VideoFrames_side\RawVideo\Press',num2str(idx,'%03d'),'.avi']);
    for k = 1:vid_read.NumFrames
        img_seq{k} = vid_read.read(k);
    end

    moviename = ['Urey20211124_video\VideoFrames_side\Video\Press',num2str(idx,'%03d'),'.avi'];
    MakeFrameRasterVideo(img_seq,spiketime_seq,t_seq,moviename,notes);
    
end