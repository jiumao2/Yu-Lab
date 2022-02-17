function maskout = ExtractMaskSeq(vidFile, frmindex)

% Jianing Yu 
% 5/20/2021
% Draw mask from selected frame in vidFile
% frmindex gives the beginning and end of frame selection

maskout = [];

%% extract ROI that matters
% read 100 frames:

filename = vidFile;
% read one min of data
framebeg = frmindex(1);
frameend = frmindex(2);
% Construct a multimedia reader object associated with file
[list_of_frames, headin_frames]         =   ReadJpegSEQ(filename, [framebeg frameend]);

% read one min of data
frames = [];
 for i = 1:size(list_of_frames, 1)
     frames(:, :, i) = double(list_of_frames{i, 1});
 end;
maxproj_frames = max(frames, [], 3);

% plot the max projection of these frames:
figure(13); clf
set(gcf, 'name', 'ROI selection', 'units', 'centimeters', 'position', [15 5 20 20])
imagesc(maxproj_frames);
colormap('gray')
axis off

clc
sprintf('Please select region of interests')

roi_selected = drawfreehand();
maskout = createMask(roi_selected); % this mask determines what pixels are included. this is the mask to use in the future.

% save this fig
print (gcf,'-dpng', ['ROI_mask']);