clear;
load('timestamps.mat')
load('RTarrayAll.mat')
fr = 10; % frame rate 100Hz
camview = 'top';

%%
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
if isempty(ind_break)
    t_seg{1} = t_frameon;
else
    ind_break = [1; ind_break+1];
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
        else
            t_seg{i}=t_frameon(ind_break(i):end);
        end
    end
end
for k = 1:length(t_seg)
    new_sideframe_inds{k} = getFrameInd(t_seg{k},ts.side(k).ts);
    new_topframe_inds{k} = getFrameInd(t_seg{k},ts.top(k).ts);
end

%%
r = UpdateRFrameSignal(r, 'time_stamps', ts, 'sidevideo_ind', new_sideframe_inds, 'topvideo_ind', new_topframe_inds);
%%
if isfield(r,'VideoInfos')
    r = rmfield(r,'VideoInfos');
end

ExtractEventFrameSignalVideo(r, ts, [], 'events', 'Press', 'time_range', [2100 2400], 'makemov', 1, 'camview', camview,...
    'make_video_with_spikes',false,'sort_by_unit',true,'frame_rate',10,'start_trial',1);
%
mat_dir = ['./VideoFrames_',camview,'/MatFile'];
output = dir([mat_dir,'/*.mat']);
filenames = {output.name};
filenames = sort(filenames);
if strcmp(camview,'top')
    for k = 1:length(filenames)
        temp_filename = [mat_dir,'/',filenames{k}];
        load(temp_filename);
        r.VideoInfos_top(k) = VideoInfo;
    end
elseif strcmp(camview,'side')
    for k = 1:length(filenames)
        temp_filename = [mat_dir,'/',filenames{k}];
        load(temp_filename);
        r.VideoInfos_side(k) = VideoInfo;
    end    
end
%
save('RTarrayAll.mat','r')