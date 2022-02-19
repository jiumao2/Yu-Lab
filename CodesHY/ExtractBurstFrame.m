function ExtractBurstFrame(r,unit_num,varargin)
FrameNum = 1000;
FrameRate = 20;
view = 'side';

if nargin>=3
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'FrameNum'
                FrameNum = varargin{i+1};
            case 'FrameRate'
                FrameRate = varargin{i+1};
            case 'view'
                view = varargin{i+1};                 
            otherwise
                errordlg('unknown argument')
        end
    end
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
threshold = temp(FrameNum);
histogram(temp(temp>2));
xline(threshold);
xlabel('Spike Count')
title('Spike Count Histogram')
%%
dir_name = ['VideoFrames_',view,'\BurstFrames'];
if ~exist(dir_name,'dir')
    mkdir(dir_name);
end
vid_out = VideoWriter([dir_name,'/Unit',num2str(unit_num),'.avi']);
vid_out.FrameRate = FrameRate;
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
