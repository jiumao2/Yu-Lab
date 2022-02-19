load RTarrayAll_side.mat
idx1 = find(strcmp({r.VideoInfos.Performance},'Correct'));

sorted_window_pre = 0;
sorted_window_post = 750;
su_all = find(r.Units.SpikeNotes(:,3)==1);

% for su_idx = 1:length(su_all)
% su_idx = 1;
spknum = zeros(length(idx1),1);
% unitnum = su_all(su_idx);
unitnum = 7;
for k = 1:length(idx1)
    spknum(k) = sum(r.VideoInfos(idx1(k)).Units.SpikeTimes(unitnum).timings<r.VideoInfos(idx1(k)).Time+sorted_window_post & ...
        r.VideoInfos(idx1(k)).Units.SpikeTimes(unitnum).timings>r.VideoInfos(idx1(k)).Time+sorted_window_pre);
end

[spknum_new,idx2] = sort(spknum);

idx3 = idx1(idx2);

path_video = './video_out_side';
if ~exist(path_video,'dir')
    mkdir(path_video);
end
for j = 211:10:round(-r.VideoInfos(1).t_pre/10)+11
    vidObj = VideoWriter(fullfile(path_video,['/','Unit',num2str(unitnum),'_',num2str(round(r.VideoInfos(1).t_pre+(j-1)*10)),'ms.avi']));
    vidObj.FrameRate = 5;
    open(vidObj);
    for k = 1:length(idx3)
        vidRead = VideoReader(['VideoFrames_side\RawVideo\Press',num2str(r.VideoInfos(idx3(k)).Index,'%03d'),'.avi']);
        img = vidRead.read(j);
        img = insertText(img,[10,10],['Sorted by Unit ',num2str(unitnum)],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        img = insertText(img,[10,50],['Sorted Window: ',num2str(sorted_window_pre),'ms to ',num2str(sorted_window_post),'ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        img = insertText(img,[10,90],['Spike Number: ',num2str(spknum_new(k))],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        img = insertText(img,[10,130],['Time related to Press: ',num2str(round(r.VideoInfos(1).t_pre+(j-1)*10)),'ms'],'FontSize',24,'TextColor','yellow','BoxOpacity', 0);
        writeVideo(vidObj,img);
%         close(vidRead);
    end
    close(vidObj);
end

% end