function StimFrames = ExtractStimFrames(vidfile, PosData, ind)

if nargin<3  ||  isempty(ind) 
    ind = [1:size(PosData.StimTime, 1)];  % if ind is empty, extract all stim frames. 
end;

StimClus = PosData.StimClus{1}*1+PosData.StimClus{2}*2; 
% object

vidObj=VideoReader(vidfile);
StimPosSelected = PosData.PosTime(PosData.StimTime(ind, 2),[1 2]);

figure(42); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 10], 'paperpositionmode', 'auto' )
F= struct('cdata', [], 'colormap', []);

i1 = 0;
i2 = 0;


for i=1:length(ind)
    
    this_index = PosData.StimTime(ind(i), 2);  % this is the frame index
    this_cluster = StimClus(i);
    StimFrames(:, :, i) = rgb2gray(read(vidObj, [this_index this_index]));
    clf(42);
    ha=axes('unit', 'centimeters', 'position', [0 0 10 10],'xlim', [0 400], 'ylim', [0 400],  'ydir','reverse',  'nextplot', 'add');
    imagesc(StimFrames(:, :, i));
    colormap('gray')
    hold on
    plot(StimPosSelected(i, 1), StimPosSelected(i, 2), 'co', 'markersize', 6, 'linewidth', 1)
    text(20, 370, ['Cluster: ' num2str(this_cluster)], 'fontsize', 12, 'color', [255 180 0]/255);
    
    switch this_cluster
        case 1
            i1 = i1+1;
            F1(i1) =  getframe(42) ;
        case 2
            i2 = i2+1;
            F2(i2) =  getframe(42) ;
    end;
end;

xx=strsplit(vidfile, '\');
video_name1 = ['StimFramesClus1_' xx{end}(1:end-4)];
% make a video clip and save it to the correct location

writerObj = VideoWriter([video_name1 '.avi']);
writerObj.FrameRate = 10; % this is 10 x slower
% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
for ifrm=1:length(F1)
    % convert the image to a frame
    frame = F1(ifrm) ;
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);

video_name2 = ['StimFramesClus2_' xx{end}(1:end-4)];
% make a video clip and save it to the correct location

writerObj = VideoWriter([video_name2 '.avi']);
writerObj.FrameRate = 10; % this is 10 x slower
% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
for ifrm=1:length(F2)
    % convert the image to a frame
    frame = F2(ifrm) ;
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);

