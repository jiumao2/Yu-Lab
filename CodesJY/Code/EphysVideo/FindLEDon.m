function tLEDon = FindLEDon(tsROI, SummedROI)

% Jianing Yu
% 4/27/2021
% Track the change in ROI intensity to judge when LED is on

imhappy = 0;

while ~imhappy
    figure(14); clf(14)
    set(gcf, 'name', 'ROI dynamics', 'units', 'centimeters', 'position', [15 5 25 15])
    % High-pass filter ROI signal
    [bf, af] = butter(2, [1  10]*2/50, 'bandpass');
    SROI_filt = filtfilt(bf, af, detrend(SummedROI));
    ha1= subplot(2, 2 ,1)
    set(ha1, 'nextplot', 'add')
    plot(tsROI, SROI_filt, 'k');
    axis tight
    
    ha2=subplot(2, 2, [3])
    set(ha2, 'nextplot', 'add')
    histogram(SROI_filt, 200);
    set(gca, 'ylim', [0 1000]);
    
    % select threshold
    clc
    disp('Select threshold, end selection by right click')
    [x_thrh, y_thrh] = getpts(gcf);
    roi_th = min(x_thrh); % this is the threshold to extract LED_on times
    line( [roi_th roi_th], get(gca, 'ylim'), 'color', 'g', 'linestyle', ':', 'linewidth', 1)
    
    axes(ha1)
    line(get(gca, 'xlim'), [roi_th roi_th], 'color', 'g', 'linestyle', ':', 'linewidth', 1)
    
    % find those ROIs that are above threshold
    above_th = find(SROI_filt > roi_th);
    
    % find begs
    above_th_begs = above_th([1 1+find(diff(above_th)>1)]);
    above_th_ends = above_th([find(diff(above_th)>1), end]);
    
    
    % Short
    cutoff = 150; % diff(above_th_begs) has to be larger than 150, otherwise, the same epoch was double counted
    short_begs = find(diff(above_th_begs)<cutoff)+1;
    
    above_th_begs(short_begs) = [];
    above_th_ends(short_begs) = [];
    
    plot(tsROI(above_th_begs), SROI_filt(above_th_begs), 'go');
    plot(tsROI(above_th_ends), SROI_filt(above_th_ends), 'go');
    
    % check the duration of these LED on periods
    above_th_dur = tsROI(above_th_ends) - tsROI(above_th_begs);
    
    ha3=subplot(2, 2, [2])
    set(ha3, 'nextplot', 'add')
    histogram(above_th_dur, 100)
    title('LED duration')
    xlabel('(ms)')
    ylabel('Count')
    clc;
    % remove "bad" ROIs
    disp('Select two points defining min and max of ROI dur, end selection by right click')
    [x_thrh, y_thrh] = getpts(gcf);
    roidur_min = min(x_thrh); % this is the threshold to extract LED_on times
    roidur_max = max(x_thrh); % this is the threshold to extract LED_on times
    
    line([roidur_min roidur_min], get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 1)
    line([roidur_max roidur_max], get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 1)
    falseindex_LEDon = find(above_th_dur<=roidur_min |  above_th_dur >= roidur_max);
    
    axes(ha1)
    plot(tsROI(above_th_begs(falseindex_LEDon)), SROI_filt(above_th_begs(falseindex_LEDon)), 'r*', 'markersize', 8);
    plot(tsROI(above_th_ends(falseindex_LEDon)), SROI_filt(above_th_ends(falseindex_LEDon)), 'r*', 'markersize', 8);
    
    above_th_begs(falseindex_LEDon)         = [];
    above_th_ends(falseindex_LEDon)         = [];
    above_th_dur(falseindex_LEDon)            = [];
       
    % empirically, push the onset time by one frame
    above_th_begs = above_th_begs-1;
    
    ha4=subplot(2, 2, [4])
    set(ha4, 'nextplot', 'add')
    
    abv_seg =[];
    
    for j =1:length(above_th_begs)
        abv_seg{j} = SROI_filt(above_th_begs(j):above_th_ends(j));
        plot(abv_seg{j}, 'k')
    end;    
   
    clc
    reply = input('Are you happy? Y/N [Y]', 's');
    if isempty(reply)
        reply = 'Y';
    end;
    
    if strcmp(reply, 'Y')  ||  strcmp(reply, 'y') 
        imhappy = 1;
    else
        imhappy =0;
    end
    
end;

abv_seg =[];

cla(ha4);

for j =1:length(above_th_begs)
    abv_seg{j} = SummedROI(above_th_begs(j)-3:above_th_ends(j));
    tseg = [0:length(abv_seg{j})-1]-3;
    plot(tseg, abv_seg{j}, 'k')
end;

xlabel('Frames')
ylabel('ROI')


tLEDon = tsROI(above_th_begs);

print (gcf,'-dpng', ['ROI_LEDon']);
