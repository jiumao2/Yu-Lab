function roi_collect = CheckAVIFrameTrigger(b, FrameInfo)

% 4/29/2021
% extract and check  frames immediately following trigger stimuli

steps                =     [-4:1:4];
midstep            =     ceil(length(steps)/2);

mask                =    FrameInfo.mask;

tbeh_trigger     =     b.TimeTone*1000;  % in ms
tframeb            =     FrameInfo.tFramesInB; % frame timestamps in b's time domain
IndTrigger        =      find(tbeh_trigger>tframeb(1) + 2000 & tbeh_trigger< tframeb(end)-2000);
tTrigger            =      tbeh_trigger(IndTrigger);

IndSelected     =     randperm(length(IndTrigger), 4);

%% Plot several frames around the trigger stimulus
figure(19); clf,
set(gcf, 'name', 'Check press', 'units', 'centimeters', 'position', [5 5 40 20], 'paperpositionmode', 'auto');

for i =1:length(IndSelected)
    % Trigger
    itTrigger                   =      tTrigger(IndSelected(i));
    IndFrameTrigger     =      find(tframeb >=itTrigger, 1, 'first');
    Frames2Extract      =      steps+IndFrameTrigger;
    % time of these frames
    tFrames2Extract     =       tframeb(Frames2Extract);
    
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
            text(50, 950, sprintf('Trigger at %2.0f ms', itTrigger), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        else
            text(50, 950, sprintf('%2.0f ms', tFrames2Extract(j)-tFrames2Extract(midstep)), 'fontsize', 8, 'fontweight', 'bold', 'color', 'c')
        end;
    end;
end;

uicontrol('Parent', 19, 'style', 'text', 'units', 'centimeters', 'position', [13, 18.5, 10, 1], 'string', 'Trigger-surrounding frames', 'fontsize', 12)
print (gcf,'-djpeg', ['Trigger-surrounding frames']);

% go through all trigger stimulus 

steps                =     [-3:1:3];
roi_collect = zeros(length(tTrigger), length(steps));
ROIs                =     FrameInfo.ROI;
for i=1:length(tTrigger)
    itrigger = tTrigger(i);  % in ms
    ind_LEDon = find(tframeb>=itrigger, 1, 'first');
      % extract these frames
    ind_frames_to_extract = ind_LEDon + steps;    
    for j =1:length(ind_frames_to_extract)
        roi_seg = ROIs(ind_frames_to_extract(j));        
        roi_collect(i, j) = roi_seg;
    end;
    roi_collect(i, :) = roi_collect(i, :) - mean(roi_collect(i, [1 2]));
end;

figure(20); clf,
set(gcf, 'name', 'Check press', 'units', 'centimeters', 'position', [5 5 10 10], 'paperpositionmode', 'auto');
haroi = axes('units', 'centimeters', 'position', [2 2 6 6], 'nextplot', 'add', 'xlim', [min(steps) max(steps)], 'ylim', [0 1000])

plot(steps, roi_collect, 'k')
axis 'auto y'
xlabel('Frames relative to trigger stimulus')
ylabel('ROI intensity');

print (gcf,'-dpng', ['CheckTriggerFrames']);
