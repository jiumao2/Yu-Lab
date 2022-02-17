function r = ExtractEventFrameSignalVideoRaw(r, ts, varargin)

% requires "Video" field in r
% Check if frame signal is correct
% only check the first segment
% 4/20/2021 update: only work with r.Video (to add 'Video' to r, use UpdateFFrameSignal.m)
% this function save only raw signal. 

voff = zeros(1, length(ts.sideviews));
events = {};

timestep =1;
makemov = 0;

camview = 'side';

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
psthall = ExtractAllPSTH(r, 'tpre', 10*timestep(1)*3, 'tpost', 10*timestep(2)*3);  % 10 ms * 3 * timestep

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

for n =1:length(event_sort);
    
    if n>1
        nstart = nstart + length(t_seg{n-1});  % frames of previous video segments
    end;
    
    t_event_n = event_sort{n};
    n_eventn = length(t_event_n);
    
    for i =1:n_eventn
        RT_ni = RTs_sort{n}(i);
        FP_ni = FPs_sort{n}(i);
        
        % sort t_trigger
        hfig = figure(28); clf,
        set(gcf, 'name', 'side view', 'units', 'centimeters', 'position', [5 5 31 18]);
        
        for ii=1:7
            ha(ii)= axes;
            set(ha(ii), 'units', 'centimeters', 'position', [1+4*(ii-1) 6+6 4 4], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
            axis off
        end;
        
        jcaj=[];
        % last frame before the light
        %         ind_frame_pretrigger = find(t_frameoff<t_trigger_n(i), 1, 'last'); % frame index before the trigger time
        ind_frame_postevent_all         =          find(t_frameon>t_event_n(i), 1, 'first');
        ind_frame_postevent              =          ind_frame_postevent_all-nstart; % this is the frame position in that movie clip
        
        frames_to_extract = [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent;  % voff is the offset between frame and frame signal.
        
        indseq = [(-3:0)*timestep(1) (1:3)*timestep(2)];
        event_frameindex{n}(i) = ind_frame_postevent;
        tframes = t_frameon( [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time
        
        xticklabel_new = {};
        for j=1:length(frames_to_extract)
            
            switch camview
                case 'side'
                    vidfile = ts.sideviews{n};
                case 'top'
                    vidfile = ts.topviews{n};
                otherwise
                    return
            end;
            
            [jcaj, headerInfo] = ReadJpegSEQ(vidfile,[frames_to_extract(j) frames_to_extract(j)]); % ica is image cell array
            
            axes(ha(j)); cla
            img = jcaj{1, 1};
            imagesc(img, [0 200]);
            title(num2str(indseq(j)))
            colormap('gray')
            
            if j ~= 4
                relative_frametime = tframes(j) - tframes(4);
                time_of_frame = sprintf('%1.0d', round(relative_frametime));
                text(700, 50, [time_of_frame], 'color', [246 233 35]/255, 'fontsize', 12)
                xticklabel_new{j} = sprintf('%1.0d', round(relative_frametime));
            else
                time_of_frame = sprintf('%1.0d', round(tframes(4)));
                text(400, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12)
                xticklabel_new{j} =  sprintf('%1.0d', round(tframes(4)));
            end;
            
        end;
        drawnow;
        
        uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 10.5+6, 10, 0.5],...
            'string', [ts.sideviews{n} '_' events  '_' num2str(i), ' / t=' num2str(round(t_event_n(i))) 'ms'], 'fontsize', 10)
        
        uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 11+6, 10, 0.5],...
            'string', sprintf('FP: %2.0fms / RT: %2.0fms', FP_ni, RT_ni), 'fontsize', 10)
        
        % add spikes
        haspk= axes; cla;
        set(haspk, 'units', 'centimeters', 'position', [1 1+6 28 4.5], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000])
        
        tcenter = tframes(4);
        tpre = tframes(4) - tframes(1)+(tframes(2)-tframes(1));
        tpost = tframes(7) - tframes(4)+(tframes(2)-tframes(1));
        
        spkout = ExtractPhasicPopulationEvents(r, 't', tcenter, 'tpre', tpre , 'tpost', tpost);
        
        figure(hfig);
        axes(haspk);
        
        ch_included = unique(spkout.spk_chs);
        colorcodes = varycolor(length(ch_included)); % color denotes channel address
        tspk = spkout.time+tcenter;
        spkmat = spkout.raster;
        Ncell = spkout.Ncell;
        
        for nc=1:Ncell
            ispktime = tspk(find(spkmat(nc, :)));
            if ~isempty(ispktime)
                xx = [ispktime; ispktime];
                yy =[nc; nc+0.8]-0.5;
                plot(xx, yy, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
            end;
        end;
        
        set(gca, 'xlim', [tcenter-tpre tcenter+tpost], 'ylim', [0 Ncell], 'xtick', round(tframes), 'xticklabel', xticklabel_new);
        
        for iframe=1:length(tframes)
            line([tframes(iframe) tframes(iframe)], [Ncell-5 Ncell], 'color',  [246 233 35]/255, 'linewidth', 2, 'linestyle', '-')
        end;
        
        % also plot trigger signal and release time
        t_this_press = t_press(t_press>=tframes(1) & t_press<=tframes(end));
        if ~isempty(t_this_press);
            for ip =1:length(t_this_press)
                line([t_this_press(ip) t_this_press(ip)], [0 Ncell], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
                text(t_this_press(ip)+10, 1, 'Press', 'color', 'k', 'fontsize', 8)
            end;
        end;
        
        t_this_release = t_release(t_release>=tframes(1) & t_release<=tframes(end));
        
        if ~isempty(t_this_release);
            % sometimes there are multiple releases
            for ir = 1:length(t_this_release)
                line([t_this_release(ir) t_this_release(ir)], [0 Ncell], 'color', 'g', 'linewidth', 1, 'linestyle', '-')
                text(t_this_release(ir)+10, 1, 'Release', 'color', 'g', 'fontsize', 8)
            end;
            
        end;
        
        t_this_trigger = t_trigger(t_trigger>=tframes(1) & t_trigger<=tframes(end));
        if ~isempty(t_this_trigger);
            for it =1:length(t_this_trigger)
                line([t_this_trigger(it) t_this_trigger(it)], [0 Ncell], 'color', 'm', 'linewidth', 1, 'linestyle', '-')
                text(t_this_trigger(it)+10, 1, 'Trigger', 'color', 'm', 'fontsize', 8)
            end;
        end;
        
        t_this_reward = t_reward(t_reward>=tframes(1) & t_reward<=tframes(end));
        if ~isempty(t_this_reward);
            for iw =1:length(t_this_reward)
                line([t_this_reward(iw) t_this_reward(iw)], [0 Ncell], 'color', 'c', 'linewidth', 1, 'linestyle', '-')
                text(t_this_reward(iw)+10, 1, 'Reward', 'color', 'c', 'fontsize', 8)
            end;
        end;
        
        % line([0 0], [0 Ncell], 'color', 'k', 'linestyle', ':')
        xlabel('Time (ms)')
        ylabel('Neuron #')
        
        switch events
            case 'Press'
                % plot psth
                hapress1= axes; cla;
                set(hapress1, 'units', 'centimeters', 'position', [1 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_press_correct{1}(1)  psthall(1).t_press_correct{1}(end)], 'ylim', [0 1000])
                psthall1 = [];
                for nc=1:Ncell
                    psthall1(nc, :) =  psthall(nc).press_correct{1};
                    plot(psthall(nc).t_press_correct{1}, psthall(nc).press_correct{1}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                end;
                set(hapress1, 'ylim', [0 max(psthall1(:))*1.1]);
                ylim1 = get(gca, 'ylim');
                line([0 0], ylim1, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
                line([750 750], ylim1, 'color', 'm', 'linestyle', '--', 'linewidth', 1)
                xlabel('Time from press (ms)')
                ylabel('(Hz)')
                
                % plot psth
                hapress2= axes; cla;
                set(hapress2, 'units', 'centimeters', 'position', [15 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_press_correct{2}(1)  psthall(1).t_press_correct{2}(end) ], 'ylim', [0 1000])
                psthall2 = [];
                for nc=1:Ncell
                    psthall2(nc, :) =  psthall(nc).press_correct{2};
                    plot(psthall(nc).t_press_correct{2}, psthall(nc).press_correct{2}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                end;
                set(hapress2, 'ylim', [0 max(psthall2(:))*1.1]);
                ylim2 = get(gca, 'ylim');
                line([0 0], ylim2, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
                line([1500 1500], ylim2, 'color', 'm', 'linestyle', '--', 'linewidth', 1)
                xlabel('Time from press (ms)')
                ylabel('(Hz)')
                
                
            case 'Release'
                % plot psth
                harelease1= axes; cla;
                set(harelease1, 'units', 'centimeters', 'position', [1 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_release_correct{1}(1)  psthall(1).t_release_correct{1}(end)], 'ylim', [0 1000])
                psthall1 = [];
                for nc=1:Ncell
                    psthall1(nc, :) =  psthall(nc).release_correct{1};
                    plot(psthall(nc).t_release_correct{1}, psthall(nc).release_correct{1}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                end;
                set(harelease1, 'ylim', [0 max(psthall1(:))*1.1]);
                ylim1 = get(gca, 'ylim');
                line([0 0], ylim1, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
                xlabel('Time from release (ms)')
                ylabel('(Hz)')
                
                % plot psth
                harelease2= axes; cla;
                set(harelease2, 'units', 'centimeters', 'position', [15 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_release_correct{2}(1)  psthall(1).t_release_correct{2}(end) ], 'ylim', [0 1000])
                psthall2 = [];
                for nc=1:Ncell
                    psthall2(nc, :) =  psthall(nc).release_correct{2};
                    plot(psthall(nc).t_release_correct{2}, psthall(nc).release_correct{2}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                end;
                set(harelease2, 'ylim', [0 max(psthall2(:))*1.1]);
                ylim2 = get(gca, 'ylim');
                line([0 0], ylim2, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
                xlabel('Time from release (ms)')
                ylabel('(Hz)')
        end;
        
        
        % save the file
        thisFolder = fullfile(pwd, 'VideoFrames', 'Frames');
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
        
        tosavename2= fullfile(thisFolder, strrep([vidfile '_' events '_' num2str(i)], '.', '_'));
        % print (gcf,'-dpdf', tosavename2)
        print (gcf,'-djpeg', tosavename2)
        % now let's make videos
        
        if makemov
            
            frames_to_extract = [frames_to_extract(1) : frames_to_extract(end)]; % now let's extract all frames

            tframes_to_extract = t_frameon([-3*timestep(1):3*timestep(2)]+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time
            tic
            [img_seq, headerInfo] = ReadJpegSEQ(vidfile,[frames_to_extract(1) frames_to_extract(end)]); % ica is image cell array
            toc
            
            img_seq = img_seq(:, 1); % now we have a bunch of cell,each one corresponding to a single frame
            
            F       =   struct('cdata', [], 'colormap', []);
            F2      =   struct('cdata', [], 'colormap', []);
            
            thisFolder = fullfile(pwd, 'VideoFrames', 'Video');
            thisFolder2 = fullfile(pwd, 'VideoFrames', 'RawVideo');
            
            if ~exist(thisFolder, 'dir')
                mkdir(thisFolder)
            end
            
            if ~exist(thisFolder2, 'dir')
                mkdir(thisFolder2)
            end
            
            for im = 1:length(img_seq)
                
                hf15 = figure(15); clf
                set(hf15, 'name', 'side view', 'units', 'centimeters', 'position', [ 15 5 10 10])
                ha3= axes;
                set(ha3, 'units', 'centimeters', 'position', [1 1 8 8], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
                axis off
                % plot this frame:
                imagesc(img_seq{im}, [0 250]);
                colormap('gray')
                F2(im) = getframe(hf15) ;
                
                drawnow
                
                hf12 = figure(12); clf
                set(hf12, 'name', 'side view', 'units', 'centimeters', 'position', [ 15 5 10 15])
                ha2= axes;
                set(ha2, 'units', 'centimeters', 'position', [1 6 8 8], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
                axis off
                % plot this frame:
                imagesc(img_seq{im}, [0 200]);
                colormap('gray')
                
                time_of_frame = sprintf('%1.0d', round(t_frameon(frames_to_extract(im))));
                text(400, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12)
                
                text(20, 950,  sprintf('FP: %2.0fms / RT: %2.0fms', FP_ni, RT_ni), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')
                
                ha3=axes; cla
                set(ha3, 'units', 'centimeters', 'position', [1 1 8 4], 'nextplot', 'add', 'xlim',[min(tframes_to_extract) max(tframes_to_extract)], 'ylim', [0 Ncell],  'xtick', round(tframes), 'xticklabel', xticklabel_new);
                
                ylabel('Neuron #')
                xlabel('Time (ms)')
                % plot or update data in this plot
                
                for nc=1:Ncell
                    ispktime = tspk(find(spkmat(nc, :)));
                    ispktime_currentframe = ispktime(ispktime>= tframes_to_extract(1) & ispktime<= tframes_to_extract(im)); % this is the data so far
                    
                    if ~isempty(ispktime_currentframe)
                        xx = [ispktime_currentframe; ispktime_currentframe];
                        yy =[nc; nc+0.8]-0.5;
                        plot(xx, yy, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                    end;
                end;
                line([tframes_to_extract(im)  tframes_to_extract(im)], [0 Ncell], 'color', [246 233 35]/255, 'linewidth', .5)
                
                % also plot trigger signal and release time
                if ~isempty(find(t_press>= tframes_to_extract(1) & t_press<= tframes_to_extract(im)));
                    t_this_press = t_press(t_press>=  tframes_to_extract(1) & t_press<= tframes_to_extract(im));
                    for ip =1:length(t_this_press)
                        line([t_this_press(ip) t_this_press(ip)], [0 Ncell], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
                        text(t_this_press(ip)+10, 1, 'Press', 'color', 'k', 'fontsize', 8)
                    end;
                end;
                
                
                if ~isempty(find(t_release>= tframes_to_extract(1) & t_release<= tframes_to_extract(im)));
                    t_this_release = t_release(t_release>=  tframes_to_extract(1) & t_release<= tframes_to_extract(im));
                    for ir = 1:length(t_this_release)
                        line([t_this_release(ir) t_this_release(ir)], [0 Ncell], 'color', 'g', 'linewidth', 1, 'linestyle', '-')
                        text(t_this_release(ir)+10, 1, 'Release', 'color', 'g', 'fontsize', 8)
                    end;
                    
                end;
                
                if ~isempty(find(t_trigger>=  tframes_to_extract(1) & t_trigger<= tframes_to_extract(im)));
                    t_this_trigger = t_trigger(t_trigger>=  tframes_to_extract(1) & t_trigger<= tframes_to_extract(im));
                    for it =1:length(t_this_trigger)
                        line([t_this_trigger(it) t_this_trigger(it)], [0 Ncell], 'color', 'm', 'linewidth', 1, 'linestyle', '-')
                        text(t_this_trigger(it)+10, 1, 'Trigger', 'color', 'm', 'fontsize', 8)
                    end;
                end;
                
                
                t_this_reward = t_reward(t_reward>=  tframes_to_extract(1) & t_reward<= tframes_to_extract(im));
                if ~isempty(t_this_reward);
                    for iw =1:length(t_this_reward)
                        line([t_this_reward(iw) t_this_reward(iw)], [0 Ncell], 'color', 'c', 'linewidth', 1, 'linestyle', '-')
                        text(t_this_reward(iw)+10, 1, 'Reward', 'color', 'c', 'fontsize', 8)
                    end;
                end;
                
                uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 14, 10, 0.5],...
                    'string', [vidfile '_' events  '_' num2str(i), ' / t=' num2str(round(t_event_n(i))) 'ms'], 'fontsize', 10)
                
                F(im) = getframe(hf12) ;
                drawnow
                
                
            end
            % create the video writer with 1 fps
            % decide movie name
            
            moviename = strrep([vidfile '_' events '_' num2str(i)], '.', '_');
            
            writerObj = VideoWriter([moviename '.avi']);
            writerObj.FrameRate = 10; % this is 10 x slower
            % set the seconds per image
            % open the video writer
            open(writerObj);
            % write the frames to the video
            for i=1:length(F)
                % convert the image to a frame
                frame = F(i) ;
                writeVideo(writerObj, frame);
            end
            % close the writer object
            close(writerObj);
            % move video
            movefile( [moviename '.avi'], thisFolder)
            
            % move video
            
            moviename = strrep(['simple_' vidfile '_' events '_' num2str(i)], '.', '_');
            
            writerObj = VideoWriter([moviename '.avi']);
            writerObj.FrameRate = 100; % this is 1 x slower
            % set the seconds per image
            % open the video writer
            open(writerObj);
            % write the frames to the video
            for i=1:length(F2)
                % convert the image to a frame
                frame = F2(i) ;
                writeVideo(writerObj, frame);
            end
            % close the writer object
            close(writerObj);
            movefile( [moviename '.avi'], thisFolder2)
            
            %%
        end;
    end;
end;
