load RTarrayAll_side.mat
view = 'top';
for unit_num = 1:length(r.Units.SpikeTimes)
% unit_num = 1;
if r.Units.SpikeNotes(unit_num,3)==2
    continue
end
spk_time = r.Units.SpikeTimes(unit_num).timings;
firing_rate_t_post = 100;
firing_rate_t_pre = -100;


firing_rate = zeros(length(r.VideoInfos),r.VideoInfos(unit_num).total_frames);
for k = 1:length(r.VideoInfos)
    for j = 1:r.VideoInfos(unit_num).total_frames
        firing_rate(k,j) = sum(spk_time+firing_rate_t_post>r.VideoInfos(k).VideoFrameTime(j)...
            & spk_time+firing_rate_t_pre<r.VideoInfos(k).VideoFrameTime(j));
    end
end

h = figure;
temp = sort(firing_rate(:),'descend');
threshold = temp(1000);
histogram(temp(temp>2));
xline(threshold);
%%
dir_name = ['VideoFrames_',view,'\BurstFrames'];
if ~exist(dir_name,'dir')
    mkdir(dir_name);
end
vid_out = VideoWriter([dir_name,'/Unit',num2str(unit_num),'.avi']);
vid_out.FrameRate = 20;
open(vid_out);
for k = 1:length(r.VideoInfos)
    for j = 1:r.VideoInfos(1).total_frames
        if firing_rate(k,j) > threshold
            vid_this = VideoReader(['VideoFrames_',view,'\RawVideo\Press',num2str(r.VideoInfos(k).Index,'%03d'),'.avi']);
            temp_frame = vid_this.read(j);
            temp_frame = insertText(temp_frame,[10,10],['Time: ',num2str(round(r.VideoInfos(k).VideoFrameTime(j))),' ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
            temp_frame = insertText(temp_frame,[10,50],['Firing Rate: ',num2str(firing_rate(k,j)/(firing_rate_t_post-firing_rate_t_pre)*1000),' Hz'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
            
            vid_out.writeVideo(temp_frame);
        end
    end
end
vid_out.close();
close(h);
end
