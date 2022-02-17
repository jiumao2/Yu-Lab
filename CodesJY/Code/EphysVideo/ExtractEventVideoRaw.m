function r = ExtractEventVideoRaw(r, varargin)

% requires "Video" field in r
% Check if frame signal is correct
% only check the first segment
% 4/20/2021 update: only work with r.Video (to add 'Video' to r, use UpdateFFrameSignal.m)
% this function save only raw signal. 

ts = r.Video.ts;  % require ts in r.Video

voff = zeros(1, length(ts.sideviews));
events = {};

timestep =1;
makemov = 0;

camview = 'side';

nvideo = 10000;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'events'
                events = varargin{i+1};
            case 'timestep'
                timestep = varargin{i+1};
            case 'camview'
                camview = varargin{i+1};
            case 'makemov'
                makemov =  varargin{i+1};
            case 'nvideo'
                nvideo =  varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

if length(timestep)==1;
    timestep = [timestep timestep];
end;

% this produces event times.
te=GetEventTimes(r);
% press_correct: {[54×1 double]  [54×1 double]}
% press_premature: [25×1 double]
% press_late: [8×1 double]
% release_correct: {[54×1 double]  [54×1 double]}
% release_premature: [25×1 double]
% release_late: [8×1 double]
% pokein: [599×1 double]
% rewards: [103×1 double]
% rt: {[54×1 double]  [54×1 double]}

% get essential psths
% press_correct: {[1×225 double]  [1×225 double]}
% t_press_correct: {[1×225 double]  [1×225 double]}
% release_correct: {[1×225 double]  [1×225 double]}
% t_release_correct: {[1×225 double]  [1×225 double]}
% reward: [1×350 double]
% t_reward: [1×350 double]
% trigger_correct: [1×150 double]
% trigger_late: [1×150 double]
% t_trigger: [1×150 double]

t_press = [te.press_correct{1}; te.press_correct{2}];
RTs = [te.rt{1}; te.rt{2}];
FPs = [ones(1, length(te.rt{1}))*750 ones(1, length(te.rt{2}))*1500]
[t_press, indsort] = sort(t_press);
RTs= RTs(indsort);
FPs= FPs(indsort);
t_release = [te.release_correct{1}; te.release_correct{2}];
[t_release, indsort] = sort(t_release);

t_trigger = te.trigger;
t_reward = te.rewards;

% determine which segment

switch camview
    case 'side'
        indframe = find(strcmp(r.Video.Labels, 'SideFrameOn'));
        t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
    case 'top'
        indframe = find(strcmp(r.Video.Labels, 'TopFrameOn'));
        t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
    otherwise
        display('Check camera view')
        return;
end;
% 
% indrelease = find(strcmp(r.Behavior.Labels, 'LeverRelease'));
% t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers == indrelease);

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
t_trigger_sort=[];
t_press_sort=[];
t_release_sort=[];

if isempty(ind_break)
    t_seg{1} = t_frameon;
    t_trigger_sort{1} = t_trigger;
    RTs_sort{1} = RTs;
    FPs_sort{1} = FPs;
    if ~isempty(t_press)
        t_press_sort{1} = t_press;
    end;
    if ~isempty(t_release)
        t_release_sort{1} = t_release;
    end;
    
else
    ind_break = [1 ind_break+1];
    
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1) & t_trigger<=t_seg{i}(end));
            
            if ~isempty(t_press)
                t_press_sort{i} = t_press(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
            end;
            if ~isempty(t_release)
                t_release_sort{i} = t_release(t_release>=t_seg{i}(1) & t_release<=t_seg{i}(end));
            end;
            RTs_sort{i} = RTs(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
            FPs_sort{i} = FPs(t_press>=t_seg{i}(1) & t_press<=t_seg{i}(end));
        else
            t_seg{i}=t_frameon(ind_break(i):end);
            t_trigger_sort{i} = t_trigger(t_trigger>=t_seg{i}(1));
            if ~isempty(t_press)
                t_press_sort{i} = t_press(t_press>=t_seg{i}(1));
            end;
            if ~isempty(t_release)
                t_release_sort{i} = t_release(t_release>=t_seg{i}(1));
            end;
            RTs_sort{i} = RTs(t_press>=t_seg{i}(1));
            FPs_sort{i} = FPs(t_press>=t_seg{i}(1));
        end;
    end;
end;


nstart = 0;

%% press
switch events
    case 'Press'
        event_frameindex = cell(1, length(t_press_sort));
        event_sort = t_press_sort;
    case 'Release'
        event_frameindex = cell(1, length(t_release_sort));
        event_sort = t_release_sort;
end;

nvideo_acc = 0;

for n =1:length(event_sort);
    
    switch camview
        case 'side'
            vidfile = ts.sideviews{n};
        case 'top'
            vidfile = ts.topviews{n};
        otherwise
            return
    end;
    
    if n>1
        nstart = nstart + length(t_seg{n-1});  % frames of previous video segments
    end;
    
    t_event_n = event_sort{n};
    n_eventn = length(t_event_n);
    
    for i =1:n_eventn
        RT_ni = RTs_sort{n}(i);
        FP_ni = FPs_sort{n}(i);
        
        jcaj=[];

        ind_frame_postevent_all         =          find(t_frameon>t_event_n(i), 1, 'first');
        ind_frame_postevent              =          ind_frame_postevent_all-nstart; % this is the frame position in that movie clip
        
        frames_to_extract = [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent; 
        
        indseq = [(-3:0)*timestep(1) (1:3)*timestep(2)];
        event_frameindex{n}(i) = ind_frame_postevent;
        tframes = t_frameon( [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time
        
        if makemov
            
            frames_to_extract = [frames_to_extract(1) : frames_to_extract(end)]; % now let's extract all frames
            tframes_to_extract = t_frameon([-3*timestep(1):3*timestep(2)]+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time
            tic
            [img_seq, headerInfo] = ReadJpegSEQ(vidfile,[frames_to_extract(1) frames_to_extract(end)]); % ica is image cell array
            toc
            img_seq = img_seq(:, 1); % now we have a bunch of cell,each one corresponding to a single frame
            
            F       =   struct('cdata', [], 'colormap', []);
            thisFolder = fullfile(pwd, 'VideoFrames', 'RawVideo');
            
            if ~exist(thisFolder, 'dir')
                mkdir(thisFolder)
            end;

            for im = 1:length(img_seq)
                
                hf15 = figure(15); clf
                
                set(hf15, 'name', 'side view', 'units', 'centimeters', 'position', [ 15 5 15 15])
                ha3= axes;
                set(ha3, 'units', 'centimeters', 'position', [0 0 15 15], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
                axis off
                % plot this frame:
                imagesc(img_seq{im}, [0 250]);
                colormap('gray')
                                       
                time_of_frame = sprintf('%1.0d', round(t_frameon(frames_to_extract(im))));
                text(20, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 8,'fontweight', 'bold')
                text(20, 950,  sprintf('FP: %2.0fms / RT: %2.0fms', FP_ni, RT_ni), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')
                % plot or update data in this plot
                F(im) = getframe(hf15) ;
                drawnow
            end
            % create the video writer with 1 fps
            % decide movie name
            
            if nvideo_acc<nvideo            
            moviename = strrep([vidfile '_' events '_' num2str(i)], '.', '_');
            
            writerObj = VideoWriter([moviename '.avi']);
            writerObj.FrameRate = 10; % this is 10 x slower
            % set the seconds per image
            % open the video writer
            open(writerObj);
            % write the frames to the video
            for ifrm=1:length(F)
                % convert the image to a frame
                frame = F(ifrm) ;
                writeVideo(writerObj, frame);
            end
            % close the writer object
            close(writerObj);
            % move video
            movefile( [moviename '.avi'], thisFolder)
            nvideo_acc = nvideo_acc+1;
            else
                return;
            end;
                        
            %%
        end;
    end;
end;
