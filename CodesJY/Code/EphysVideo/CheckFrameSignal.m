function r = CheckFrameSignal(r, ts, voff)

% Check if frame signal is correct 
% only check the first segment
if nargin<3
voff = zeros(1, length(ts.sideviews)); 
end;
events = {'Trigger'};


indtrigger = find(strcmp(r.Behavior.Labels, 'Trigger'));
t_trigger = r.Behavior.EventTimings(r.Behavior.EventMarkers == indtrigger);
% determine which segment
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);
indframe = find(strcmp(r.Behavior.Labels, 'FrameOff'));
t_frameoff = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
t_trigger_sort=[];

if isempty(ind_break)
    t_seg{1} = t_frameon;
    t_trigger_sort{1} = t_trigger;

else
    ind_break = [1; ind_break+1];
    
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1) & t_trigger<=t_seg{i}(end));

        else
            t_seg{i}=t_frameon(ind_break(i):end);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1));
        end;
    end;
end;

% sort t_trigger
figure(27); clf,
set(gcf, 'name', 'side view', 'units', 'centimeters', 'position', [5 5 45 8]);

for i=1:7
    ha(i)= axes;
    set(ha(i), 'units', 'centimeters', 'position', [1+6*(i-1) 1 6 6], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
    axis off
end;

mask=[];
roi_selected=[];
roi_data = cell(1, length(t_trigger_sort));
nstart = 0;

trigger_frameindex = cell(1, length(t_trigger_sort));

for n =1:length(t_trigger_sort);
    
    if n>1
        nstart = nstart + length(t_seg{n-1});  % frames of previous video segments
    end;
    t_trigger_n = t_trigger_sort{n};
    n_triggern = length(t_trigger_n);
    for i =1:n_triggern
        jcaj=[];
        % last frame before the light
        %         ind_frame_pretrigger = find(t_frameoff<t_trigger_n(i), 1, 'last'); % frame index before the trigger time
        ind_frame_posttrigger = find(t_frameon>t_trigger_n(i), 1, 'first')-nstart; % frame index before the trigger time
        
        frames_to_extract = [-3:3]+ind_frame_posttrigger+voff(n);  % voff is the offset between frame and frame signal. 
        indseq =[-3 : 3];
        
        trigger_frameindex{n}(i) = ind_frame_posttrigger+voff(n);
        
        for j=1:length(frames_to_extract)
            
            [jcaj, headerInfo] = ReadJpegSEQ(ts.sideviews{n},[frames_to_extract(j) frames_to_extract(j)]); % ica is image cell array
            axes(ha(j)); cla
            img = jcaj{1, 1};
            imagesc(img);
            title(num2str(indseq(j)))
            colormap('gray')
            
            % build a mask
            if i==1 && j==1 && n==1 % only define once
                clc
                sprintf('Please select region of interests')
                roi_selected = drawfreehand();
                mask = createMask(roi_selected); % this mask determines what pixels are included. this is the mask to use in the future.
            end;
            roi_data{n}(j, i) = sum(img(mask));
        end;
        drawnow;
        
        uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 7.5, 10, 0.5], 'string', [ts.sideviews{n} '_trigger' '_' num2str(i)], 'fontsize', 10)
        pause(1)
        
        % save the file
        thisFolder = fullfile(pwd, 'Fig', 'VideoFrames');
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
        
        tosavename2= fullfile(thisFolder, strrep([ts.sideviews{n} '_trigger' '_' num2str(i)], '.', '_'));
        % print (gcf,'-dpdf', tosavename2)
        print (gcf,'-djpeg', tosavename2)
 
    end;
end;


figure;
for i=1:length(t_trigger_sort)
    subplot(length(t_trigger_sort), 1, i);
    plot(indseq, roi_data{i}, 'ko-')
    title([ts.sideviews{i} 'offset' num2str(voff(i))])
end;
 
tosavename2= fullfile(thisFolder, ['Video_FrameOn alignment']);
print (gcf,'-dpng', tosavename2)

r.Video.ts = ts;
% r.Video.TriggerFrameIndex = trigger_frameindex;

tic
save RTarrayAll r
toc


