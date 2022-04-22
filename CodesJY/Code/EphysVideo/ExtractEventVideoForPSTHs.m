function r = ExtractEventVideoForPSTHs(r, ts, varargin)
% TimeStamps =
%   struct with fields:
%
%            Top: [1×3 struct]
%      TopVideos: {1×3 cell}
%           Side: [1×3 struct]
%     SideVideos: {1×3 cell}

% requires "Video" field in r
% Check if frame signal is correct
% only check the first segment
% 4/20/2021 update: only work with r.Video (to add 'Video' to r, use UpdateFFrameSignal.m)
% this function save only raw signal.

% 11/8/2021 Jianing Yu updated
% triggered by a gui: ProcessSeqVideoForEphys

% voff = zeros(1, length(ts.sideviews));
events = {};

timestep =1;
makemov = 1;
videopath = pwd;
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
            case 'pre'
                pretime = varargin{i+1};
            case 'post'
                posttime = varargin{i+1};
            case 'videopath'
                videopath = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

if length(timestep)==1;
    timestep = [timestep timestep];
end;


% this produces event times.
% te=GetEventTimes(r);

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
% psthall = ExtractAllPSTH(r, 'tpre', pretime, 'tpost', posttime);  % 10 ms * 3 * timestep

% press_correct: {[1×225 double]  [1×225 double]}
% t_press_correct: {[1×225 double]  [1×225 double]}
% release_correct: {[1×225 double]  [1×225 double]}
% t_release_correct: {[1×225 double]  [1×225 double]}
% reward: [1×350 double]
% t_reward: [1×350 double]
% trigger_correct: [1×150 double]
% trigger_late: [1×150 double]
% t_trigger: [1×150 double]

%
% t_press = [te.press_correct{1}; te.press_correct{2}];
% RTs = [te.rt{1}; te.rt{2}];
% FPs = [ones(1, length(te.rt{1}))*750 ones(1, length(te.rt{2}))*1500]
% [t_press, indsort] = sort(t_press);
% RTs= RTs(indsort);
% FPs= FPs(indsort);
% t_release = [te.release_correct{1}; te.release_correct{2}];
% [t_release, indsort] = sort(t_release);
%
% t_trigger = te.trigger;
% t_reward = te.rewards;

% determine which segment
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

indpressall = find(strcmp(r.Behavior.Labels, 'LeverPress')); % all lever presses are included
t_press =  r.Behavior.EventTimings(r.Behavior.EventMarkers == indpressall);

indreleaseall = find(strcmp(r.Behavior.Labels, 'LeverRelease')); % all lever presses are included
t_release =  r.Behavior.EventTimings(r.Behavior.EventMarkers == indreleaseall);
fp_press = r.Behavior.Foreperiods; % fp_pressall and t_pressall have the same number

indrewardall = find(strcmp(r.Behavior.Labels, 'ValveOnset')); % all lever presses are included
t_reward =  r.Behavior.EventTimings(r.Behavior.EventMarkers == indrewardall);

indtriggerall= find(strcmp(r.Behavior.Labels, 'Trigger')); % all lever presses are included
t_trigger=  r.Behavior.EventTimings(r.Behavior.EventMarkers == indtriggerall);

% correct 1, premature -1, late 2, dark 0, unidentified nan
% track each press' consequence
outcome_press    =       cell(1, length(t_press));
rt_press                =       t_release - t_press - fp_press;

for i =1:length(t_press)
    if ~isempty(find(r.Behavior.CorrectIndex == i))
        outcome_press{i} = 'Correct';
    elseif ~isempty(find(r.Behavior.PrematureIndex == i))
        outcome_press{i} = 'Premature';
    elseif  ~isempty(find(r.Behavior.LateIndex == i))
        outcome_press{i} = 'Late';
    else
        outcome_press{i} = 'Others';
    end;
end;


switch camview
    case 'Side'
        indframe = arrayfun(@(x)x.IndMatch, ts.Side, 'UniformOutput', false);
    case 'Top'
        indframe = arrayfun(@(x)x.IndMatch, ts.Top, 'UniformOutput', false);
    otherwise
        display('Check camera view')
        return;
end;
%

% sort press, release,  trigger, poke
t_press_sort=cell(1, length(indframe));
fp_sort = cell(1, length(indframe));
rt_sort = cell(1, length(indframe));
t_release_sort=cell(1, length(indframe));
% t_trigger_sort=cell(1, length(indframe));
t_reward_sort = cell(1, length(indframe));
% RTs= RTs(indsort);
% FPs= FPs(indsort);
outcome_sort = cell(1, length(indframe));

for i=1:length(indframe)

    t_in_video = t_frameon(indframe{i});  % this is the frame time of the ith video
    t_press_sort{i} = t_press(t_press-pretime>=t_in_video(1) & t_press+posttime<=t_in_video(end));
    fp_sort{i} = fp_press(t_press-pretime>=t_in_video(1) & t_press+posttime<=t_in_video(end));
    rt_sort{i} = rt_press(t_press-pretime>=t_in_video(1) & t_press+posttime<=t_in_video(end));
    t_release_sort{i} = t_release(t_release-pretime>=t_in_video(1) & t_release+posttime<=t_in_video(end));
    t_reward_sort{i} = t_reward(t_reward-pretime>=t_in_video(1) & t_reward+posttime<=t_in_video(end));
    outcome_sort{i} = outcome_press(t_press-pretime>=t_in_video(1) & t_press+posttime<=t_in_video(end));
end;

Ncell = length(r.Units.SpikeTimes);
IndCell = 1:Ncell;
NewRank =[r.PopPSTH.IndSort setdiff(IndCell, r.PopPSTH.IndSort)];
Nsig = length(r.PopPSTH.IndSort);

tPSTH_Press = r.PopPSTH.PressAllZ(1, :);
PSTH_Press = r.PopPSTH.PressAllZ(2:end, :);
PSTH_Press = PSTH_Press(NewRank, :);

% norm_range = [-1 1];
% PSTH_Press = normalize(PSTH_Press, 'range',norm_range);


LiveChs = unique(r.Units.SpikeNotes(:, 1));
ChColors = varycolor(length(LiveChs));

thisFolder = fullfile(pwd, 'VideoFrames', [events 'Video']);
thisFolder2 = fullfile(pwd, 'VideoFrames', [events 'LiteVideo']);

if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

if ~exist(thisFolder2, 'dir')
    mkdir(thisFolder2)
end

%% press
switch events
    case 'Press'
        event_frameindex = cell(1, length(t_press_sort));
        event_sort = t_press_sort;
        tevent_frames = cell(1, length(t_press_sort));


        hf11 = figure(11); clf
        set(hf11, 'name', 'Population', 'units', 'centimeters',...
            'position', [5 8 10 8])

        % plot PSTH population averages, in colormap
        ha0=axes;
        set(ha0, 'units', 'centimeters', 'position', [1 1 8 6.5], 'nextplot', 'add', 'xlim',[-pretime posttime],...
            'ylim', [0.5 Ncell+0.5],  'xtick', [-5000:500:5000],  'ytick', [1:2:Ncell], 'ydir', 'reverse', 'yticklabel', [1:2:Ncell], 'fontsize', 6);
        himage = imagesc(tPSTH_Press, [1:size(PSTH_Press, 1)], PSTH_Press, [-4 8]);
        colormap(ha0, 'Turbo')

        line([-pretime posttime], [Nsig Nsig]+0.5, 'linewidth', 1, 'color', 'w')
        line([0 0], [0 Ncell+0.5], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
        xlabel(['Time from ' events '(ms)'])
        ylabel('Neurons')
        % plot spikes
        % unit order is determined by their responses (this has been taken cared of in r:  PSTHPop = SRTSpikesPopulation(r);)

        for nc=1:Ncell
            icell = NewRank(nc);  % this is the new rank
            ichcolor =ChColors(find(LiveChs == r.Units.SpikeNotes(icell, 1)), :);
            text(posttime, nc-0.25, sprintf('%2.0d-%2.0d', r.Units.SpikeNotes(icell, 1),  r.Units.SpikeNotes(icell, 2)), 'fontsize', 6, 'color', ichcolor, 'FontWeight','bold')
        end;

        tosavename=  fullfile(thisFolder, 'PopulationResponseSorted')
        print (hf11,'-dpng', tosavename);
        print (hf11,'-depsc2', tosavename);
        print (hf11,'-dpdf', tosavename);

        for n =1:length(event_sort);
            t_event_n = event_sort{n};
            n_eventn = length(t_event_n);
            t_in_br = t_frameon(indframe{n}); % frame time in ephys

            for i =1:n_eventn

                t_event_ni = t_event_n(i); % this press

                RT_ni = rt_sort{n}(i); % reaction time of this press (note here only plots correct presses)
                FP_ni = fp_sort{n}(i);
                outcome_ni = outcome_sort{n}{i};

                ind_event_overall = find(t_press == t_event_ni);

                ind_frame_postevent         =         find(t_in_br>t_event_ni, 1, 'first');
                ind_frames_to_extract       =        find(t_in_br>=t_event_ni-pretime & t_in_br<=t_event_ni+posttime); % frame index (in this video clip)
                t_frames_to_extract           =         t_in_br(ind_frames_to_extract);
                tevent_frames{n}{i}             =        t_frames_to_extract; % time of these frames (in ms, defined in blackrock)

                xticklabel_new = {};

                switch camview
                    case 'Side'
                        vidfile = ts.SideVideos{n};
                    case 'Top'
                        vidfile = ts.TopVideos{n};
                    otherwise
                        return
                end;


                VidMeta.ANM                 = r.Meta(1).Subject;
                VidMeta.Event                =        events;
                VidMeta.EventTime        =   t_event_ni;
                VidMeta.EventIndex       =   ind_event_overall;
                VidMeta.Foreperiod       =      FP_ni;
                VidMeta.RT                       =       RT_ni;
                VidMeta.Performance    =     outcome_ni;
                VidMeta.PreTime            =      pretime;
                VidMeta.PostTime          =       posttime;
                VidMeta.FrameTimeEphys = t_frames_to_extract;
                VidMeta.FrameIndVideo = ind_frames_to_extract;
                VidMeta.VideoName = vidfile;

                moviename = strrep([events '_' num2str(ind_event_overall)], '.', '_');

                xfile = dir(fullfile(thisFolder, [moviename '.avi']));
                tic
                if isempty(xfile) && ~strcmp(outcome_ni, 'Others')

                    writerObj = VideoWriter([moviename '.avi']);
                    writerObj.FrameRate = 10; % this is 10 x slower
                    % set the seconds per image
                    % open the video writer
                    open(writerObj);

                    [imgall, headerInfo] = ReadJpegSEQ(fullfile(videopath, vidfile),[ind_frames_to_extract(1) ind_frames_to_extract(end)]); % ica is image cell array
                    img_seq = imgall(:, 1); % now we have a bunch of cell,each one corresponding to a single frame
 
                    for im = 1:length(img_seq)

                        hf12 = figure(12); clf
                        set(hf12, 'name', 'side view', 'units', 'centimeters',...
                            'position', [5 8 10 8+10*size(img_seq{im}, 1)/size(img_seq{im}, 2)])

                        ha2= axes;
                        set(ha2, 'units', 'centimeters', 'position', [0 8 10 10*size(img_seq{im}, 1)/size(img_seq{im}, 2)],...
                            'nextplot', 'add', 'xlim',[0 size(img_seq{im}, 2)], 'ylim', [0 size(img_seq{im}, 1)], 'ydir','reverse')
                        axis off
                        % plot this frame:
                        imagesc(img_seq{im}, [0 220]);
                        colormap('gray')

                        xmax = size(img_seq{im}, 2);
                        ymax = size(img_seq{im}, 1);

                        time_of_frame = sprintf('%1.0d', round(t_frames_to_extract(im)-t_event_ni));
                        text(xmax-300, 50, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12)
                        text(20, ymax-50,  sprintf('FP: %2.0fms', FP_ni), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')
                        text(20, ymax-100,  sprintf('RT: %2.0fms', RT_ni), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')
                        text(20, ymax-150,  sprintf('%s', outcome_ni), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')
                        text(20, ymax-200,  sprintf('%s #%2.0d', events, ind_event_overall), 'color', [255 255 255]/255, 'fontsize',  8, 'fontweight', 'bold')

                        ha3=axes;
                        set(ha3, 'units', 'centimeters', 'position', [1 1 8.3 6], 'nextplot', 'add', 'xlim',[-pretime posttime],...
                            'ylim', [0 Ncell],  'xtick', [-5000:500:5000], 'ydir', 'reverse', 'ytick', [1:2:Ncell], 'fontsize', 6);
                        xlabel('Time (ms)')
                        ylabel('Neurons')

                        % plot or update data in this plot

                        for nc=1:Ncell
                            icell = NewRank(nc);  % this is the new rank
                            ichcolor =ChColors(find(LiveChs == r.Units.SpikeNotes(icell, 1)), :);
                            ispktime = r.Units.SpikeTimes(icell).timings; % spk times in ms recorded in blackrock
                            ispktime_thisvid = ispktime(ispktime>=t_frames_to_extract(1) & ispktime<=t_frames_to_extract(end) ) ;
                            %                             ispktime_currentframe = ispktime(ispktime>= t_frames_to_extract(1) & ispktime<= t_frames_to_extract(im)); % this is the data so far

                            if ~isempty(ispktime_thisvid)
                                %                                 xx = [ispktime_thisvid; ispktime_thisvid]-t_event_ni;
                                %                                 yy =[nc; nc+0.8]-0.5;
                                xx = [ispktime_thisvid]-t_event_ni;
                                yy =nc-0.5;
                                plot(xx, yy, 'marker', '.', 'color', ichcolor, 'linewidth', 1, 'markersize', 6)
                            end;

                            text(posttime, nc-0.5, sprintf('%2.0d-%2.0d', r.Units.SpikeNotes(icell, 1),  r.Units.SpikeNotes(icell, 2)), 'fontsize', 6, 'color', ichcolor)

                        end;

                        line([t_frames_to_extract(im)  t_frames_to_extract(im)]-t_event_ni, [0 Ncell], 'color', [0.2 0.6 1], 'linewidth', 1)
                        line([-pretime posttime], [Nsig Nsig], 'linewidth', 1, 'color', 'k')
                        % also plot trigger signal and release time

                        if ~isempty(find(t_press>= t_frames_to_extract(1) & t_press<= t_frames_to_extract(end)))
                            t_this_press = t_press(t_press>=  t_frames_to_extract(1) & t_press<= t_frames_to_extract(end));
                            for ip =1:length(t_this_press)
                                line([t_this_press(ip) t_this_press(ip)]-t_event_ni, [0 Ncell], 'color', 'k', 'linewidth', 1, 'linestyle', '-')
                                text(t_this_press(ip)-t_event_ni+20, Ncell-1, 'Press', 'color', 'k', 'fontsize', 6)
                            end;
                        end;


                        if ~isempty(find(t_release>= t_frames_to_extract(1) & t_release<= t_frames_to_extract(end)));
                            t_this_release = t_release(t_release>=  t_frames_to_extract(1) & t_release<= t_frames_to_extract(end));
                            for ir = 1:length(t_this_release)
                                line([t_this_release(ir) t_this_release(ir)]-t_event_ni, [0 Ncell], 'color', [0 .6 0], 'linewidth', 1, 'linestyle', '-')
                                text(t_this_release(ir)-t_event_ni+20, Ncell-1, 'Release', 'color', [0 .6 0], 'fontsize', 6)
                            end;

                        end;

                        if ~isempty(find(t_trigger>=  t_frames_to_extract(1) & t_trigger<= t_frames_to_extract(end)));
                            t_this_trigger = t_trigger(t_trigger>=  t_frames_to_extract(1) & t_trigger<= t_frames_to_extract(end));
                            for it =1:length(t_this_trigger)
                                line([t_this_trigger(it) t_this_trigger(it)]-t_event_ni, [0 Ncell], 'color', 'm', 'linewidth', 1, 'linestyle', '-')
                                text(t_this_trigger(it)-t_event_ni+20, Ncell-1, 'Trigger', 'color', 'm', 'fontsize', 6)
                            end;
                        end;

                        t_this_reward = t_reward(t_reward>=  t_frames_to_extract(1) & t_reward<= t_frames_to_extract(end));
                        if ~isempty(t_this_reward);
                            for iw =1:length(t_this_reward)
                                line([t_this_reward(iw) t_this_reward(iw)]-t_event_ni, [0 Ncell], 'color', 'c', 'linewidth', 1, 'linestyle', '-')
                                text(t_this_reward(iw)-t_event_ni+20, Ncell-1, 'Reward', 'color', 'c', 'fontsize', 6)
                            end;
                        end;

                        uicontrol('style', 'text', 'unit', 'centimeters', 'position', [0 7, 10, 0.8],...
                            'string', [vidfile '_' events  '_' num2str(ind_event_overall), ' / t=' num2str(round(t_event_n(i))) 'ms'], 'fontsize', 10)

                        frame = getframe(hf12) ;
                        writeVideo(writerObj, frame);
                    end
                    % close the writer object
                    close(writerObj);
                    % move video
                    movefile( [moviename '.avi'], thisFolder)
                    %
                    %                     % move video
                    %
                    %                     moviename = strrep([events '_' num2str(i)  'Lite'], '.', '_');
                    %
                    %                     writerObj = VideoWriter([moviename '.avi']);
                    %                     writerObj.FrameRate = 10; % this is 1 x slower
                    %                     % set the seconds per image
                    %                     % open the video writer
                    %                     open(writerObj);
                    %                     % write the frames to the video
                    %                     for i=1:length(F2)
                    %                         % convert the image to a frame
                    %                         frame = F2(i) ;
                    %                         writeVideo(writerObj, frame);
                    %                     end
                    %                     % close the writer object
                    %                     close(writerObj);
                    %                     movefile( [moviename '.avi'], thisFolder2)
                    save(fullfile(thisFolder, [events '_' num2str(ind_event_overall) 'Meta']), 'VidMeta')
                    toc
                    memory
                end;

                %%
            end;
        end;
end;
