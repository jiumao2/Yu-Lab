function r = ExtractEventFrameSignalVideo(r, ts, PSTHOut, varargin)

% requires "Video" field in r
% please first enter the video folder
% Check if frame signal is correct
% only check the first segment
% 4/20/2021 update: only work with r.Video (to add 'Video' to r, use UpdateFFrameSignal.m)
% 9/1/2021 update: only work with r.Video (to add 'Video' to r, use UpdateFFrameSignal.m)


    % get press plot index
    if ~isempty(PSTHOut)
        pval_pop = zeros(1, size(PSTHOut.Units, 1));
        tpeaks_pop = zeros(1, size(PSTHOut.Units, 1));

        for i = 1:length(pval_pop)
            pval_pop(i)        =      PSTHOut.PressStat{1}.StatOut(i).pval;
            tpeaks_pop(i)    =      PSTHOut.PressStat{1}.StatOut(i).tpeak; 
        end

        ind_significant = find(pval_pop<0.05);
        [~, indsort] = sort(tpeaks_pop(ind_significant));
        ind_plot = ind_significant(indsort);
    end

    events = {};

    time_range = 1000;
    makemov = 0;
    make_video_with_spikes = 0;

    camview = 'side';
    sort_by_unit = true;
    frame_rate = 10;
    start_trial = 1;
    min_frame_interval = 1000;
    folder = pwd;

    if nargin>3
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'events'
                    events = varargin{i+1};
                case 'time_range'
                    time_range = varargin{i+1};
                case 'camview'
                    camview = varargin{i+1};
                case 'makemov'
                    makemov =  varargin{i+1};
                case 'make_video_with_spikes'
                    make_video_with_spikes =  varargin{i+1};    
                case 'sort_by_unit'
                    sort_by_unit = varargin{i+1}; 
                case 'frame_rate'
                    frame_rate = varargin{i+1}; 
                case 'start_trial'
                    start_trial = varargin{i+1}; 
                case 'min_frame_interval'
                    min_frame_interval = varargin{i+1};
                case 'folder'
                    folder = varargin{i+1};
                otherwise
                    errordlg('unknown argument')
            end
        end
    end

    if sort_by_unit
        ind_plot = 1:length(r.Units.SpikeTimes);
    end

    if length(time_range)==1
        timestep = [time_range time_range];
    else
        timestep = time_range;
    end
    timestep = round(timestep/3/frame_rate);

    % this produces event times.
    % te=GetEventTimes(r);
    % close all;
    % press_correct: {[54�1 double]  [54�1 double]}
    % press_premature: [25�1 double]
    % press_late: [8�1 double]
    % release_correct: {[54�1 double]  [54�1 double]}
    % release_premature: [25�1 double]
    % release_late: [8�1 double]
    % pokein: [599�1 double]
    % rewards: [103�1 double]
    % rt: {[54�1 double]  [54�1 double]}

    % get essential psths
    % psthall = ExtractAllPSTH(r, 'tpre', frame_rate*timestep(1)*3, 'tpost', frame_rate*timestep(2)*3);  % 10 ms * 3 * timestep

    % press_correct: {[1�225 double]  [1�225 double]}
    % t_press_correct: {[1�225 double]  [1�225 double]}
    % release_correct: {[1�225 double]  [1�225 double]}
    % t_release_correct: {[1�225 double]  [1�225 double]}
    % reward: [1�350 double]
    % t_reward: [1�350 double]
    % trigger_correct: [1�150 double]
    % trigger_late: [1�150 double]
    % t_trigger: [1�150 double]

    t_press = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverPress')));
    t_trigger = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'Trigger')));
    t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'LeverRelease')));
    t_reward = r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'ValveOnset')));

    correct_index = r.Behavior.CorrectIndex;
    premature_index = r.Behavior.PrematureIndex;
    late_index = r.Behavior.LateIndex;
    FPs = r.Behavior.Foreperiods;
    RTs = t_release - t_press - FPs;
    RTs(RTs<0) = NaN;

    movetime = zeros(1, length(t_reward));
    for i =1:length(t_reward)
        dt = t_reward(i)-t_release(correct_index);
        dt = dt(dt>0);
        if ~isempty(dt)
            movetime(i) = dt(end);
        end
    end
    t_reward = t_reward(movetime>0);

    % determine which segment

    switch camview
        case 'side'
            if isfield(r.Video, 't_frameon_side')
                t_frameon = r.Video.t_frameon_side;
            else
                indframe = find(strcmp(r.Video.Labels, 'SideFrameOn'));
                t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
            end
        case 'top'
            if isfield(r.Video, 't_frameon_top')
                t_frameon = r.Video.t_frameon_top;
            else
                indframe = find(strcmp(r.Video.Labels, 'TopFrameOn'));
                t_frameon = r.Video.EventTimings(r.Video.EventMarkers == indframe);
            end
        otherwise
            disp('Check camera view')
            return;
    end
    % 
    % indrelease = find(strcmp(r.Behavior.Labels, 'LeverRelease'));
    % t_release = r.Behavior.EventTimings(r.Behavior.EventMarkers == indrelease);

%     t_spikeson_all = [];
%     for k = 1:length(r.Units.SpikeTimes)
%         t_spikeson_all = [t_spikeson_all,r.Units.SpikeTimes(k).timings];
%     end
%     t_spikeson_all = sort(t_spikeson_all);

    ind_break = find(diff(t_frameon)>=min_frame_interval);
    t_seg =[];
    % t_trigger_sort=[];
    % t_press_sort=[];
    % t_release_sort=[];
    % 
    if isempty(ind_break)
        t_seg{1} = t_frameon;
    else
        ind_break = [1 ind_break+1];
        for i =1:length(ind_break)
            if i<length(ind_break)
                t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
            else
                t_seg{i}=t_frameon(ind_break(i):end);
            end
        end
    end

    %% press
    switch events
        case 'Press'
            event_frameindex = cell(1, length(t_press));
            event_sort = t_press;
        case 'Release'
            event_frameindex = cell(1, length(t_release));
            event_sort = t_release;
    end

    for i = start_trial:length(event_sort)
        idx_vid_file = 1;
        nstart = 0;
        for temp = 1:length(t_seg)
            if t_press(i)>t_seg{temp}(end)
                nstart = nstart + length(t_seg{temp});
                idx_vid_file = idx_vid_file+1;
            else
                break
            end
        end

        t_event_n = event_sort;

        ind_frame_postevent_all         =          find(t_frameon>t_event_n(i), 1, 'first');
        ind_frame_postevent              =          ind_frame_postevent_all - nstart; % this is the frame position in that movie clip

        if isempty(ind_frame_postevent) ||... % no trial found
            (ind_frame_postevent <= 3*timestep(1)) ||... % the trial starts before the video 
            (ind_frame_postevent + 3*timestep(2) >= length(t_seg{temp})) % the trial ends after the video
            continue;
        end

        % compute dt between assumed start time and real start time
        t_start_assumed = -3*timestep(1);
        d_frame = -3*timestep(1)/10;
        t_start_real = t_frameon(round(ind_frame_postevent_all + d_frame)) - t_frameon(ind_frame_postevent_all);
        dt_start = t_start_real - t_start_assumed;

        t_end_assumed = 3*timestep(2);
        d_frame = 3*timestep(2)/10;
        t_end_real = t_frameon(round(ind_frame_postevent_all + d_frame)) - t_frameon(ind_frame_postevent_all);
        dt_end = t_end_real - t_end_assumed;
        
        if abs(dt_start) > 10
            fprintf('The trial is skipped because the difference of start time > 10 ms\n dt = %f\n', dt_start);
            continue
        end

        if abs(dt_end) > 10
            fprintf('The trial is skipped because the difference of end time > 10 ms\n dt = %f\n', dt_end);
            continue
        end
        

    %     for i =1:n_eventn
    %         RT_ni = RTs_sort{idx_vid_file}(i);
    %         FP_ni = FPs_sort{idx_vid_file}(i);
            RT_ni = RTs(i);
            FP_ni = FPs(i);
            if find(i==correct_index)
                performance = 'Correct';
            elseif find(i==premature_index)
                performance = 'Premature';
            elseif find(i==late_index)
                performance = 'Late';
            else
                performance = 'Others';
            end

            % sort t_trigger
    %         hfig = figure(28); clf;
    %         set(gcf, 'name', 'side view', 'units', 'centimeters', 'position', [5 5 31 18]);

    %         for ii=1:7
    %             ha(ii)= axes;
    %             set(ha(ii), 'units', 'centimeters', 'position', [1+4*(ii-1) 6+6 4 4], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
    %             axis off
    %         end

            % last frame before the light
            %         ind_frame_pretrigger = find(t_frameoff<t_trigger_n(i), 1, 'last'); % frame index before the trigger time
            ind_frame_postevent_all         =          find(t_frameon>t_event_n(i), 1, 'first');
            ind_frame_postevent              =          ind_frame_postevent_all - nstart; % this is the frame position in that movie clip

            frames_to_extract = [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent;  % voff is the offset between frame and frame signal.

            indseq = [(-3:0)*timestep(1) (1:3)*timestep(2)];
            event_frameindex{idx_vid_file} = ind_frame_postevent;
            tframes = t_frameon( [(-3:0)*timestep(1) (1:3)*timestep(2)]+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time

%             xticklabel_new = {};
%             for j=1:length(frames_to_extract)
% 
%                 switch camview
%                     case 'side'
%                         vidfile = ts.sideviews{idx_vid_file};
%                     case 'top'
%                         vidfile = ts.topviews{idx_vid_file};
%                     otherwise
%                         return
%                 end
% 
%                 img = ReadJpegSEQ2(vidfile,frames_to_extract(j)); % ica is image cell array
% 
%     %             axes(ha(j)); cla
%     %             imagesc(img, [0 200]);
%     %             title(num2str(indseq(j)))
%     %             colormap('gray')
%     %             
%     %             if j ~= 4
%     %                 relative_frametime = tframes(j) - tframes(4);
%     %                 time_of_frame = sprintf('%1.0d', round(relative_frametime));
%     %                 text(700, 50, [time_of_frame], 'color', [246 233 35]/255, 'fontsize', 12)
%     %                 xticklabel_new{j} = sprintf('%1.0d', round(relative_frametime));
%     %             else
%     %                 time_of_frame = sprintf('%1.0d', round(tframes(4)));
%     %                 text(400, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12)
%     %                 xticklabel_new{j} =  sprintf('%1.0d', round(tframes(4)));
%     %             end
% 
%             end
    %         drawnow;
    %         
    %         uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 10.5+6, 10, 0.5],...
    %             'string', [events  '_' num2str(i), ' / t=' num2str(round(t_event_n(i))) 'ms'], 'fontsize', 10)
    %         
    %         uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 11+6, 10, 0.5],...
    %             'string', sprintf('FP: %2.0fms / RT: %2.0fms', FP_ni, RT_ni), 'fontsize', 10)

            % add spikes
    %         haspk= axes; cla;
    %         set(haspk, 'units', 'centimeters', 'position', [1 1+6 28 4.5], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000])

%             tcenter = tframes(4);
%             tpre = tframes(4) - tframes(1)+(tframes(2)-tframes(1));
%             tpost = tframes(7) - tframes(4)+(tframes(2)-tframes(1));
% 
%             spkout = ExtractPhasicPopulationEvents(r, 't', tcenter, 'tpre', tpre , 'tpost', tpost);
% 
%     %         figure(hfig);
%     %         axes(haspk);
% 
%             ch_included = unique(spkout.spk_chs);
%             colorcodes = varycolor(length(ch_included)); % color denotes channel address
%             tspk = spkout.time+tcenter;
%             spkmat = spkout.raster;
%             Ncell = spkout.Ncell;

    %         for nc=1:Ncell
    %             ispktime = tspk(find(spkmat(nc, :)));
    %             if ~isempty(ispktime)
    %                 xx = [ispktime; ispktime];
    %                 yy =[nc; nc+0.8]-0.5;
    %                 plot(xx, yy, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
    %             end
    %         end
    %         
    %         set(gca, 'xlim', [tcenter-tpre tcenter+tpost], 'ylim', [0 Ncell], 'xtick', round(tframes), 'xticklabel', xticklabel_new);
    %         
    %         for iframe=1:length(tframes)
    %             line([tframes(iframe) tframes(iframe)], [Ncell-5 Ncell], 'color',  [246 233 35]/255, 'linewidth', 2, 'linestyle', '-')
    %         end

            % also plot trigger signal and release time
            t_this_press = t_press(t_press>=tframes(1) & t_press<=tframes(end));
    %         if ~isempty(t_this_press)
    %             for ip =1:length(t_this_press)
    %                 line([t_this_press(ip) t_this_press(ip)], [0 Ncell], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
    %                 text(t_this_press(ip)+10, 1, 'Press', 'color', 'k', 'fontsize', 8)
    %             end
    %         end

            t_this_release = t_release(t_release>=tframes(1) & t_release<=tframes(end));

    %         if ~isempty(t_this_release)
    %             % sometimes there are multiple releases
    %             for ir = 1:length(t_this_release)
    %                 line([t_this_release(ir) t_this_release(ir)], [0 Ncell], 'color', 'g', 'linewidth', 1, 'linestyle', '-')
    %                 text(t_this_release(ir)+10, 1, 'Release', 'color', 'g', 'fontsize', 8)
    %             end
    %             
    %         end

            t_this_trigger = t_trigger(t_trigger>=tframes(1) & t_trigger<=tframes(end));
    %         if ~isempty(t_this_trigger)
    %             for it =1:length(t_this_trigger)
    %                 line([t_this_trigger(it) t_this_trigger(it)], [0 Ncell], 'color', 'm', 'linewidth', 1, 'linestyle', '-')
    %                 text(t_this_trigger(it)+10, 1, 'Trigger', 'color', 'm', 'fontsize', 8)
    %             end
    %         end

            t_this_reward = t_reward(t_reward>=tframes(1) & t_reward<=tframes(end));
    %         if ~isempty(t_this_reward)
    %             for iw =1:length(t_this_reward)
    %                 line([t_this_reward(iw) t_this_reward(iw)], [0 Ncell], 'color', 'c', 'linewidth', 1, 'linestyle', '-')
    %                 text(t_this_reward(iw)+10, 1, 'Reward', 'color', 'c', 'fontsize', 8)
    %             end
    %         end

            % line([0 0], [0 Ncell], 'color', 'k', 'linestyle', ':')
    %         xlabel('Time (ms)')
    %         ylabel('Neuron #')

    %         switch events
    %             case 'Press'
    %                 % plot psth
    %                 hapress1= axes; cla;
    %                 set(hapress1, 'units', 'centimeters', 'position', [1 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_press_correct{1}(1)  psthall(1).t_press_correct{1}(end)], 'ylim', [0 1000])
    %                 psthall1 = [];
    %                 for nc_index=1:length(ind_plot)
    %                     nc = ind_plot(nc_index);
    %                     psthall1(nc, :) =  psthall(nc).press_correct{1};
    %                     plot(psthall(nc).t_press_correct{1}, psthall(nc).press_correct{1}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
    %                 end
    %                 set(hapress1, 'ylim', [0 max(psthall1(:))*1.1]);
    %                 ylim1 = get(gca, 'ylim');
    %                 line([0 0], ylim1, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
    %                 line([750 750], ylim1, 'color', 'm', 'linestyle', '--', 'linewidth', 1)
    %                 xlabel('Time from press (ms)')
    %                 ylabel('(Hz)')
    %                 
    %                 % plot psth
    %                 hapress2= axes; cla;
    %                 set(hapress2, 'units', 'centimeters', 'position', [15 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_press_correct{2}(1)  psthall(1).t_press_correct{2}(end) ], 'ylim', [0 1000])
    %                 psthall2 = [];
    %                 for nc_index=1:length(ind_plot)
    %                     nc = ind_plot(nc_index);
    %                     psthall2(nc, :) =  psthall(nc).press_correct{2};
    %                     plot(psthall(nc).t_press_correct{2}, psthall(nc).press_correct{2}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
    %                 end
    %                 set(hapress2, 'ylim', [0 max(psthall2(:))*1.1]);
    %                 ylim2 = get(gca, 'ylim');
    %                 line([0 0], ylim2, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
    %                 line([1500 1500], ylim2, 'color', 'm', 'linestyle', '--', 'linewidth', 1)
    %                 xlabel('Time from press (ms)')
    %                 ylabel('(Hz)')
    %                 
    %                  
    %             case 'Release'
    %                 % plot psth
    %                 harelease1= axes; cla;
    %                 set(harelease1, 'units', 'centimeters', 'position', [1 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_release_correct{1}(1)  psthall(1).t_release_correct{1}(end)], 'ylim', [0 1000])
    %                 psthall1 = [];
    %                 for nc_index=1:length(ind_plot)
    %                     nc = ind_plot(nc_index);
    %                     psthall1(nc, :) =  psthall(nc).release_correct{1};
    %                     plot(psthall(nc).t_release_correct{1}, psthall(nc).release_correct{1}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
    %                 end
    %                 set(harelease1, 'ylim', [0 max(psthall1(:))*1.1]);
    %                 ylim1 = get(gca, 'ylim');
    %                 line([0 0], ylim1, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
    %                 xlabel('Time from release (ms)')
    %                 ylabel('(Hz)')
    %                 
    %                 % plot psth
    %                 harelease2= axes; cla;
    %                 set(harelease2, 'units', 'centimeters', 'position', [15 1 12 5], 'nextplot', 'add', 'xlim',[psthall(1).t_release_correct{2}(1)  psthall(1).t_release_correct{2}(end) ], 'ylim', [0 1000])
    %                 psthall2 = [];
    %                 for nc_index=1:length(ind_plot)
    %                     nc = ind_plot(nc_index);
    %                     psthall2(nc, :) =  psthall(nc).release_correct{2};
    %                     plot(psthall(nc).t_release_correct{2}, psthall(nc).release_correct{2}, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
    %                 end
    %                 set(harelease2, 'ylim', [0 max(psthall2(:))*1.1]);
    %                 ylim2 = get(gca, 'ylim');
    %                 line([0 0], ylim2, 'color', 'k', 'linestyle', '--', 'linewidth', 1)
    %                 xlabel('Time from release (ms)')
    %                 ylabel('(Hz)')
    %         end
    %         
    %         
    %         % save the file
    %         thisFolder = fullfile(pwd, 'VideoFrames', 'Frames');
    %         if ~exist(thisFolder, 'dir')
    %             mkdir(thisFolder)
    %         end
    %         
    %         tosavename2= fullfile(thisFolder, strrep([events '_' num2str(i)], '.', '_'));
    %         % print (gcf,'-dpdf', tosavename2)
    %         print (gcf,'-djpeg', tosavename2)
            % now let's make videos

            if makemov

                frames_to_extract = frames_to_extract(1):frames_to_extract(end); % now let's extract all frames

                tframes_to_extract = t_frameon((-3*timestep(1):3*timestep(2))+ind_frame_postevent_all); % this is the time of plotted frames, session time, not segment time

                img_seq = cell(length(frames_to_extract),1);
                for frame_index = 1:length(frames_to_extract)
                    try
                        img_seq{frame_index} = ReadJpegSEQ2(vidfile, frames_to_extract(frame_index)); % ica is image cell array
                    catch
                        img_seq{frame_index} = img_seq{frame_index-1};
                        disp(['[', events, ' ', num2str(i),'] error on read No. ',num2str(frame_index),' frame']);
                    end
                end

    %             img_seq = img_seq(:, 1); % now we have a bunch of cell,each one corresponding to a single frame

    %             F       =   struct('cdata', [], 'colormap', []);
    %             F2      =   struct('cdata', [], 'colormap', []);

                thisFolder = fullfile(folder, ['VideoFrames_',camview], 'Video');
                thisFolder2 = fullfile(folder, ['VideoFrames_',camview], 'RawVideo');
                mat_dir = fullfile(folder, ['VideoFrames_',camview], 'MatFile');

                if ~exist(thisFolder, 'dir')
                    mkdir(thisFolder)
                end

                if ~exist(thisFolder2, 'dir')
                    mkdir(thisFolder2)
                end
                if ~exist(mat_dir,'dir')
                    mkdir(mat_dir);
                end

                F2 = img_seq;
                if make_video_with_spikes
                    % create the video writer with 1 fps
                    % decide movie name

                    moviename = [thisFolder,'/',events,num2str(i,'%03d'),'.avi'];

                    writerObj = VideoWriter(moviename);
                    writerObj.FrameRate = 10; % this is 10 x slower
                    % set the seconds per image
                    % open the video writer
                    open(writerObj);

                    hf12 = figure(12);
                    clf
                    set(hf12, 'name', [camview, ' view'], 'units', 'centimeters', 'position', [ 15 5 10 15])
                    ha2= axes;
                    set(ha2, 'units', 'centimeters', 'position', [1 6 8 8], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
                    ha3 = axes;
                    set(ha3, 'units', 'centimeters', 'position', [1 1 8 4], 'nextplot', 'add', 'xlim',[min(tframes_to_extract) max(tframes_to_extract)], 'ylim', [0 Ncell],  'xtick', round(tframes), 'xticklabel', xticklabel_new);
                    for im = 1:length(img_seq)

        %                 hf15 = figure(15); clf
        %                 set(hf15, 'name', 'side view', 'units', 'centimeters', 'position', [ 15 5 10 10])
        %                 ha3= axes;
        %                 set(ha3, 'units', 'centimeters', 'position', [1 1 8 8], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
        %                 axis off
        %                 % plot this frame:
        %                 imagesc(img_seq{im}, [0 250]);
        %                 colormap('gray')
        %                 F2(im) = getframe(hf15) ;
        %                 
        %                 drawnow

                        set(hf12, 'name', [camview, ' view'], 'units', 'centimeters', 'position', [ 15 5 10 15])
    %                     ha2= axes; 
                        cla(ha2)
                        set(ha2, 'units', 'centimeters', 'position', [1 6 8 8], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
                        axis(ha2,'off')
                        % plot this frame:
                        imagesc(ha2,img_seq{im}, [0 200]);
                        colormap('gray')

                        time_of_frame = sprintf('%1.0d', round(t_frameon(frames_to_extract(im))));
                        text(ha2,400, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12)
                        if isfield(r.Behavior,'CueIndex')
                            text(ha2,20, 950,  sprintf('FP: %2.0fms / RT: %2.0fms / Performance: %s / Cue:%d', FP_ni, RT_ni, performance, r.Behavior.CueIndex(i)), 'color', [255 0 0]/255, 'fontsize',  8, 'fontweight', 'bold')
                        else    
                            text(ha2,20, 950,  sprintf('FP: %2.0fms / RT: %2.0fms / Performance: %s', FP_ni, RT_ni, performance), 'color', [255 0 0]/255, 'fontsize',  8, 'fontweight', 'bold')
                        end
    %                     ha3=axes; cla
                        set(ha3, 'units', 'centimeters', 'position', [1 1 8 4], 'nextplot', 'add', 'xlim',[min(tframes_to_extract) max(tframes_to_extract)], 'ylim', [0 Ncell],  'xtick', round(tframes), 'xticklabel', xticklabel_new);

        %                 ylabel('Neuron #')
                        xlabel(ha3,'Time (ms)')
                        % plot or update data in this plot

                        for nc_index=1:length(ind_plot)
                            nc = ind_plot(nc_index);
                            ispktime = tspk(find(spkmat(nc, :)));
                            ispktime_currentframe = ispktime(ispktime>= tframes_to_extract(max(1,im-1)) & ispktime<= tframes_to_extract(im)); % this is the data so f

                            if ~isempty(ispktime_currentframe)
    %                             xx = [ispktime_currentframe; ispktime_currentframe];
    %                             yy =[nc_index; nc_index+0.8]-0.5;
                                xx = [ispktime_currentframe; ispktime_currentframe];
                                yy = [nc_index; nc_index+0.8]-0.5;
                                plot(ha3,xx, yy, 'color', colorcodes(spkout.spk_chs(nc) == ch_included, :), 'linewidth', 1)
                            end
                        end
    %                     line(ha3,[tframes_to_extract(im)  tframes_to_extract(im)], [0 Ncell], 'color', [246 233 35]/255, 'linewidth', .5)

                        % also plot trigger signal and release time
                        if ~isempty(find(t_press>= tframes_to_extract(1) & t_press<= tframes_to_extract(im)))
                            t_this_press = t_press(t_press>=  tframes_to_extract(1) & t_press<= tframes_to_extract(im));
                            for ip =1:length(t_this_press)
                                line(ha3,[t_this_press(ip) t_this_press(ip)], [0 Ncell], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
                                text(ha3,t_this_press(ip)+10, 1, 'Press', 'color', 'k', 'fontsize', 8)
                            end
                        end


                        if ~isempty(find(t_release>= tframes_to_extract(1) & t_release<= tframes_to_extract(im)))
                            t_this_release = t_release(t_release>=  tframes_to_extract(1) & t_release<= tframes_to_extract(im));
                            for ir = 1:length(t_this_release)
                                line(ha3,[t_this_release(ir) t_this_release(ir)], [0 Ncell], 'color', 'g', 'linewidth', 1, 'linestyle', '-')
                                text(ha3,t_this_release(ir)+10, 1, 'Release', 'color', 'g', 'fontsize', 8)
                            end

                        end

                        if ~isempty(find(t_trigger>=  tframes_to_extract(1) & t_trigger<= tframes_to_extract(im)))
                            t_this_trigger = t_trigger(t_trigger>=  tframes_to_extract(1) & t_trigger<= tframes_to_extract(im));
                            for it =1:length(t_this_trigger)
                                line(ha3,[t_this_trigger(it) t_this_trigger(it)], [0 Ncell], 'color', 'm', 'linewidth', 1, 'linestyle', '-')
                                text(ha3,t_this_trigger(it)+10, 1, 'Trigger', 'color', 'm', 'fontsize', 8)
                            end
                        end


                        t_this_reward = t_reward(t_reward>=  tframes_to_extract(1) & t_reward<= tframes_to_extract(im));
                        if ~isempty(t_this_reward)
                            for iw =1:length(t_this_reward)
                                line([t_this_reward(iw) t_this_reward(iw)], [0 Ncell], 'color', 'c', 'linewidth', 1, 'linestyle', '-')
                                text(t_this_reward(iw)+10, 1, 'Reward', 'color', 'c', 'fontsize', 8)
                            end
                        end

                        uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0.1 14, 10, 0.5],...
                            'string', [events,num2str(i), ' / t=',num2str(round(t_event_n(i))),'ms'], 'fontsize', 10)


                        writeVideo(writerObj, getframe(hf12)) ;
                        drawnow


                    end

                    % close the writer object
                    close(writerObj);
                    % move video
                end

                % move video

                moviename = [thisFolder2,'/',events,num2str(i,'%03d'),'.avi'];

                writerObj = VideoWriter(moviename);
                writerObj.FrameRate = 100; % this is 1 x slower
                % set the seconds per image
                % open the video writer
                open(writerObj);
                % write the frames to the video
                for i_Frame=1:length(F2)
                    % convert the image to a frame
                    frame = F2{i_Frame} ;
                    writeVideo(writerObj, frame);
                end
                % close the writer object
                close(writerObj);

            end
            VideoInfo.AnimalName = r.Meta(1).Subject;
            temp_time = datetime(r.Meta(1).DateTime, 'Locale', 'en_US');
            VideoInfo.SessionName = [num2str(temp_time.Year,'%04d'),num2str(temp_time.Month,'%02d'),num2str(temp_time.Day,'%02d')];
            VideoInfo.Event = events;
            VideoInfo.Index = i;
            if isfield(r.Behavior,'CueIndex') && ~isempty(r.Behavior.CueIndex)
                VideoInfo.Cue = r.Behavior.CueIndex(i,2);
            end
            VideoInfo.Time = t_frameon(ind_frame_postevent_all);
            VideoInfo.Foreperiod = FP_ni;
            VideoInfo.ReactTime = RT_ni;
            VideoInfo.t_pre = -time_range(1);
            VideoInfo.t_post = time_range(2);
            VideoInfo.total_frames = length(frames_to_extract);

            VideoInfo.Performance = performance;
            VideoInfo.VideoFilename = vidfile;
            VideoInfo.VideoFrameIndex = frames_to_extract + nstart;
            VideoInfo.VideoFrameTime = tframes_to_extract;
%             if isfield(r.Units,'Channels')
%                 VideoInfo.Units.Channels = r.Units.Channels;
%             end
%             VideoInfo.Units.Profile = r.Units.Profile;
%             VideoInfo.Units.Definition = r.Units.Definition;
%             VideoInfo.Units.SpikeNotes = r.Units.SpikeNotes;
% 
%             t1 = tframes_to_extract(1);
%             t2 = tframes_to_extract(end);
%             for temp = 1:length(r.Units.SpikeTimes)
%                 VideoInfo.Units.SpikeTimes(temp).timings = r.Units.SpikeTimes(temp).timings(r.Units.SpikeTimes(temp).timings>=t1 & r.Units.SpikeTimes(temp).timings<=t2);
%                 VideoInfo.Units.SpikeTimes(temp).wave = r.Units.SpikeTimes(temp).timings(r.Units.SpikeTimes(temp).timings>=t1 & r.Units.SpikeTimes(temp).timings<=t2);
%             end

            save([mat_dir,'/',events,num2str(i,'%03d'),'.mat'],'VideoInfo');
            close all;

            fprintf('[%d / %d] %s done!\n', i, length(event_sort), moviename);
    end
    
    
end
