function tLEDnew = CorrectLEDtime(b, FrameInfo)

% Jianing Yu
% 4/29/2021

% Note that we define LED on time as the time trigger stimulus is
% delivered. By definition, LED should not be lightened up yet at this
% point. Thus, we need to look at the ROI at tLEDout and revise the LED on definition if
% necessary. 

% use FrameInfo.ROI to get the ROI out 
 
tbeh_trigger     =     b.TimeTone*1000;  % in ms
tframeb            =     FrameInfo.tFramesInB; % frame timestamps in b's time domain
IndTrigger        =     find(tbeh_trigger>tframeb(1) & tbeh_trigger< tframeb(end));
tTrigger            =     tbeh_trigger(IndTrigger);

tframeVid         =     FrameInfo.tframe;
% go through all trigger stimulus 
steps                =     [-3:1:3];
midstep            =     floor(length(steps)/2);

roi_collect        =     zeros(length(tTrigger), length(steps));

allframes_extracted  = [];
ROIs                =     FrameInfo.ROI;

tLEDonOrg = 0;
alltframes_extracted =[];

for i=1:length(tTrigger)
    itrigger = tTrigger(i);  % in ms
    ind_LEDon = find(tframeb>=itrigger, 1, 'first');
    tLEDonOrg(i) = tframeVid(ind_LEDon);
    % extract these frames
    if ind_LEDon+steps(1) >=1 && ind_LEDon+steps(end)<length(tframeVid)
        
        ind_frames_to_extract = ind_LEDon + steps;
        allframes_extracted=[allframes_extracted; ind_frames_to_extract];
        alltframes_extracted = [alltframes_extracted; tframeVid(ind_frames_to_extract)];
        
        for j =1:length(ind_frames_to_extract)
            roi_seg = ROIs(ind_frames_to_extract(j));
            roi_collect(i, j) = roi_seg;
        end;
        roi_collect(i, :) = roi_collect(i, :) - mean(roi_collect(i, [1 2]));
    end;
    
end;

figure(14); clf(14)

set(gcf, 'name', 'ROI', 'units', 'centimeters', 'position', [15 5 20 15])

ha1=axes('units', 'centimeters', 'position', [1 8 8 6], 'nextplot', 'add', 'xlim', [-3 3], 'xtick', [-4:4],'xgrid', 'on');
plot(steps, roi_collect, 'ko-');
xlabel('steps')
 
roi_zero = roi_collect(:, midstep);
allmidROIs = roi_zero(:);

roi_pre = roi_collect(:, 1:midstep-1);
allpreROI = roi_pre(:);

roi_change = diff(roi_collect, 1, 2);
roi_change = [zeros(size(roi_collect, 1), 1) roi_change];

% plot distribution
ha2=axes('units', 'centimeters', 'position', [1 1 8 5], 'nextplot', 'add');

h_histall = histogram(roi_collect(:), 200, 'facecolor', 'b');

xlimorg = get(ha2, 'xlim');
xlabel('ROI')

text(min(get(gca, 'xlim')), 0.95*max(get(gca, 'ylim')), 'Select a threshold with a Left click')
text(min(get(gca, 'xlim')), 0.8*max(get(gca, 'ylim')), 'End the seleciton with a Right click')
text(min(get(gca, 'xlim')), 0.65*max(get(gca, 'ylim')), 'Hit "Enter" to quit the selection')

clc;
disp('Define the threshold');
[x_thrh, y_thrh] = getpts(ha2);

if isempty(x_thrh)
    tLEDnew = tLEDonOrg;
    sprintf('Done correcting')
    return;
end;

led_min = min(x_thrh); % this is the threshold to extract LED_on times
line([led_min led_min], get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 5);
line(ha1, [-3 3], [led_min led_min], 'color', 'm', 'linestyle', ':', 'linewidth', 5);
drawnow

disp('Threshold defined');

% plot distribution
ha3=axes('units', 'centimeters', 'position', [11 1 8 5], 'nextplot', 'add');
h_hist2 = histogram(roi_change, 100);
xlimorg2 = get(ha3, 'xlim');
xlabel('dROI/dt')
set(gca, 'xlim', [xlimorg2(1) xlimorg2(2)*1.5]);

text(min(get(gca, 'xlim')), 0.95*max(get(gca, 'ylim')), 'Select a threshold with a Left click')
text(min(get(gca, 'xlim')), 0.8*max(get(gca, 'ylim')), 'End the seleciton with a Right click')
text(min(get(gca, 'xlim')), 0.65*max(get(gca, 'ylim')), 'Hit "Enter" to quit the selection')

clc;
disp('Define the threshold');
[x_thrh2, y_thrh] = getpts(ha3);
if isempty(x_thrh2)
    tLEDnew = tLEDonOrg;
    sprintf('Done correcting')
    return;
end;
leddiff_min = min(x_thrh2); % this is the threshold to extract LED_on times
line([leddiff_min leddiff_min], get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 5); 
drawnow

disp('Threshold defined');

%% now we need to make sure ROI remains low at step = 0 and dROI/dt occurs at step =1
tLEDnew                 =       [];
tLEDonOrg2           =       tLEDonOrg;
for i =1:size(roi_collect, 1)
    % find when ROI starts to increase, this will be defined as step =1
    ind_rising = find(roi_collect(i, :)>led_min & roi_change(i, :)>leddiff_min, 1, 'first'); 
    if ~isempty(ind_rising)
        tLEDnew = [tLEDnew alltframes_extracted(i, ind_rising-1)];
        tLEDonOrg2(i) = alltframes_extracted(i, ind_rising-1);
    end;
end;

display('#############################')
display('######### Done correcting #######')
display('#############################')


%% Check the revised results
roi_collect_new = zeros(length(tLEDnew), length(steps));

for i=1:length(tLEDnew)
    ind_LEDon = find(tframeVid == tLEDnew(i));  % this is the frame corresponding to trigger stimulus (note, LED is on from next frame)
    roi_collect_new(i, :) = ROIs(ind_LEDon + steps);
    roi_collect_new(i, :) = roi_collect_new(i, :) - mean(roi_collect_new(i, [1 2]));
end;

ha4=axes('units', 'centimeters', 'position', [11 8 8 6], 'nextplot', 'add', 'xlim', [-3 3], 'xtick', [-4:4],'xgrid', 'on');
plot(steps, roi_collect_new, 'bo-');
xlabel('steps')
title('Corrected')
 


