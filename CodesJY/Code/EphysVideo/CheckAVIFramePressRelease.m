function CheckAVIFramePressRelease(b, FrameInfo)

% 4/29/2021
% extract and check frames when press and release is on
% there should be stereotypical posture in these frames

steps           =     [-4:1:4];
midstep       =     ceil(length(steps)/2);

tPress              =     b.PressTime(b.Correct)*1000; % only use correct presses
tRelease          =     b.ReleaseTime(b.Correct)*1000;
tframeb            =     FrameInfo.tFramesInB;
IndPress          =     find(tPress> tframeb(1)+2000 & tRelease<tframeb(end)-2000);
tPress              =     tPress(IndPress);
tRelease          =     tRelease(IndPress);
IndSelected     =     randperm(length(IndPress), 4);

figure(19); clf,
set(gcf, 'name', 'Check press', 'units', 'centimeters', 'position', [5 5 40 20], 'paperpositionmode', 'auto');

for i =1:length(IndSelected)
    % Press
    itPress             =       tPress(IndSelected(i));
    IndFramePress = find(tframeb >itPress, 1, 'first');
    Frames2Extract = steps+IndFramePress;
    % time of these frames
    tFrames2Extract = tframeb(Frames2Extract);
    for j=1:length(Frames2Extract)
        iframe2extract = Frames2Extract(j);
        ind_vfile = FrameInfo.AviFile{FrameInfo.AviFileIndx(iframe2extract)}; % identify the correct video file
        vidObj = VideoReader(ind_vfile);
        ind_frame_toextract = FrameInfo.AviFrameIndx(iframe2extract);
        this_frame = read(vidObj, [ind_frame_toextract ind_frame_toextract]);  % extract the correct frame
        %
        ha_axes(i, 1) = axes('units', 'centimeters', 'position', [1+(j-1)*4 1+(i-1)*4.5 4 4], 'nextplot', 'add', 'xlim', [0 1000], 'ylim', [0 1000], 'ydir', 'reverse');
        imagesc(this_frame, [0 300]);
        line([0 1000], [0 0], 'color', 'c', 'linewidth',2)
        line([1000 1000], [0 10000], 'color', 'c', 'linewidth',2)
        line([0 1000], [1000 1000], 'color', 'c', 'linewidth',2)
        line([0 0], [0 10000], 'color', 'c', 'linewidth',2)
        
        axis off
        if j==midstep
            text(50, 950, sprintf('Press at %2.0f ms', itPress), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        else
            text(50, 950, sprintf('%2.0f ms', tFrames2Extract(j)-tFrames2Extract(midstep)), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        end;
    end;
end;

uicontrol('Parent', 19, 'style', 'text', 'units', 'centimeters', 'position', [13, 18.5, 10, 1], 'string', 'Press-surrounding frames', 'fontsize', 12)
print (gcf,'-djpeg', ['Press-surrounding frames']);

%%
figure(20); clf,
set(gcf, 'name', 'Check release', 'units', 'centimeters', 'position', [5 5 40 20], 'paperpositionmode', 'auto');

for i =1:length(IndSelected)
    % Right before release
    itRelease         =       tRelease(IndSelected(i));
    IndFrameRelease = find(tframeb >itRelease, 1, 'first'); % extract the frame just before lever release
    % time of these frames
    Frames2Extract = steps+IndFrameRelease;
    % time of these frames
    tFrames2Extract = tframeb(Frames2Extract);
    for j=1:length(Frames2Extract)
        iframe2extract = Frames2Extract(j);
        ind_vfile = FrameInfo.AviFile{FrameInfo.AviFileIndx(iframe2extract)}; % identify the correct video file
        vidObj = VideoReader(ind_vfile);
        ind_frame_toextract = FrameInfo.AviFrameIndx(iframe2extract);
        this_frame = read(vidObj, [ind_frame_toextract ind_frame_toextract]);  % extract the correct frame
        %
        ha_axes(i, 1) = axes('units', 'centimeters', 'position', [1+(j-1)*4 1+(i-1)*4.5 4 4], 'nextplot', 'add', 'xlim', [0 1000], 'ylim', [0 1000], 'ydir', 'reverse');
        imagesc(this_frame, [0 300]);
        line([0 1000], [0 0], 'color', 'c', 'linewidth',2)
        line([1000 1000], [0 10000], 'color', 'c', 'linewidth',2)
        line([0 1000], [1000 1000], 'color', 'c', 'linewidth',2)
        line([0 0], [0 10000], 'color', 'c', 'linewidth',2)
        
        axis off
        if j==midstep
            text(50, 950, sprintf('Release at %2.0f ms', itRelease), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        else
            text(50, 950, sprintf('%2.0f ms', tFrames2Extract(j)-tFrames2Extract(midstep)), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        end;
    end;
end;

uicontrol('Parent', 20, 'style', 'text', 'units', 'centimeters', 'position', [13, 18.5, 10, 1], 'string', 'Release-surrounding frames', 'fontsize', 12)
print (gcf,'-djpeg', ['Release-surrounding frames']);

