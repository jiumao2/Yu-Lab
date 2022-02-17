function ExportSeqVideoFiles(b, frameinfo, sout, varargin)

% b: behavior data from MED
% frameinfo: frame related
% sout: from wavesurfer, can be empty if no ws data are available. 
% this program export video clips from behavior-relevant time points.
% File name is : ANM_YearMonDay_Event###.avi
% Video files should be stored in current directory
% varargin:
% 'Event', 'Press'
% 'TimeRange': [2000 3000]
% 'RatName': 'Charlie'
% 'SessionName': '20200810'

% Jianing Yu
% 5/1/2021
remake =0;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case {'Event'}
                event = varargin{i+1};
            case {'TimeRange'}
                trange = varargin{i+1}; % pre- and post-event periods.
            case {'RatName'}
                anm = varargin{i+1}; % animal name
            case {'SessionName'}
                session = varargin{i+1}; % animal name
            case {'Remake'}
                remake =  varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

tframesB            =    frameinfo.tFramesInB;
tpre                    =    trange(1); % pre event time included
tpost                   =     trange(2); % post event time included
trigger_dur         =     250; % trigger sitmulus is usually 250 ms

% identify video onset and offset
% beginning of new video segments (sometimes we record more than one video
% and there could be significan gap between these videos. obviously, events
% occuring within these gaps were not filmed.
ind_begs   =      [1 find(diff(tframesB)>1000)+1];
ind_ends   =      [find(diff(tframesB)>1000) length(tframesB)];
t_begs       =      tframesB(ind_begs); % beginning of each video segments, in behavior time
t_ends       =      tframesB(ind_ends); % ending of each video sgements, in behavior time

t_begs2     =      t_begs + tpre;
t_ends2     =      t_ends - tpost;

thisFolder = fullfile(pwd, 'VideoData', 'Clips');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end;

VidsMeta = struct('Session', [], 'Event', [], 'EventIndex', [], 'Performance', [], 'EventTime', [], 'FrameTimesB', [], 'VideoOrg', [], 'FrameIndx', [], 'Code', [], 'CreatedOn', []);

video_acc = 0;
switch event
    case {'approach', 'Approach'}
        event = 'Approach';
        t_events               =          b.Approach*1000;;  % this is the press time 
        % pull out a few critical events
        t_Press                 =          b.PressTime*1000;
        t_Release             =           b.ReleaseTime*1000;
        t_Trigger               =           b.TimeTone*1000;
        t_Approach          =           b.Approach*1000;
        t_FPs                    =           b.FPs; % in ms
        
        if ~isempty(sout)
            t_WS                    =           sout.TimeInB;
            f_Press                 =           detrend(medfilt1(sout.Signals(:, find(contains(sout.Labels, 'Press'))), 20));
            f_Trigger               =           sout.Signals(:, find(contains(sout.Labels, 'Trigger')));
            f_Approach          =           sout.Signals(:, find(contains(sout.Labels, 'Approach')));
        else
            t_WS                    =           [];
            f_Press                 =           [];
            f_Trigger               =           [];
            f_Approach           =           [];
        end;
        
        % Extract video-tapped events.
        ind_event_incl      =           []; % events that were captured by video, index in b
        time_event_incl    =           []; % events that were captured by video, time in b
        
        for k=1:length(t_begs2)
            ind_event_incl          =       [ind_event_incl     find(t_events>t_begs2(k) & t_events<t_ends2(k))];                         % this is the press index
            time_event_incl        =       [time_event_incl    t_events(find(t_events>t_begs2(k) & t_events<t_ends2(k)))];         % this is the time of these events, in ms
        end;
        % now, start to extract video clip, one by one
        tic
        fbar = waitbar(0,'Making video clips ......');
        clc
        for i =1:length(ind_event_incl)
            tic
            waitbar(i/length(ind_event_incl), fbar, 'Making video clips ......')
            
            Stim            =       b.ApproachStimIndex(ind_event_incl(i));  % stim: 1 or 0       
            
            if Stim
                ind_stim_this = find(abs(b.StimTime -  b.Approach(ind_event_incl(i)))<0.01);
                StimPattern = b.StimProfile(ind_stim_this, :);
                dur                         =       StimPattern(1);
                freq                        =       StimPattern(2);
                pulsedur                =       StimPattern(3);
                delay                     =       StimPattern(4);
                nstim                     =       dur*freq/1000;
                isi                           =       1000/freq;
            else
                StimPattern = [];
            end;
            
            Pressed      =       b.App2PressCompleted(ind_event_incl(i)); %  1 or 0 (didn't press)
            
            perf = [];
            iFP = NaN;
            RT = NaN;
            
            if Pressed
                IndPress = find(b.PressTime > b.Approach(ind_event_incl(i)), 1, 'first'); % index of press
                iFP = b.FPs(IndPress);
                TimeOfPress = b.PressTime(IndPress); % time of the press
                if ~isempty(find(b.Correct==IndPress));
                    perf = 'Correct';
                    RT = (b.ReleaseTime(IndPress)-b.PressTime(IndPress))*1000 - b.FPs(IndPress);
                elseif  ~isempty(find(b.Premature==IndPress));
                    perf = 'Premature';
                    RT = nan;
                elseif ~isempty(find(b.Late==IndPress));
                    perf = 'Late';
                    RT = (b.ReleaseTime(IndPress)-b.PressTime(IndPress))*1000 - b.FPs(IndPress);
                end;
            else
                perf = 'Aborted';
            end
     
            if ~isempty(perf)
                
                video_name = sprintf('%s_%s_Approach%03d', anm, session, ind_event_incl(i));
                
                % check if a video has been created and check if we want to
                % re-create the same video
                filename = fullfile(thisFolder, [video_name '.avi']);
                check_this_file = dir(filename);
                
                if isempty(check_this_file)  || remake % only make new video, unless told to remake all files.
                    % time and frames
                    IdxFrames                         =       find(tframesB >= time_event_incl(i) - tpre & tframesB <= time_event_incl(i) + tpost); % these are the frame index (whole session)
                    FileIdx                                =      frameinfo.SeqFileIndx(IdxFrames); % these are the file idx, one can track which video contains this event
                    VidFrameIdx                      =       frameinfo.SeqFrameIndx(IdxFrames);  % these are the frame index in video identified in FileIdx
                    itframes                              =       frameinfo.tFramesInB(IdxFrames);
                    itframes_norm                    =       itframes -  time_event_incl(i);
                    tframes_highres                 =       itframes(1):itframes(end);  % high resolution behavioral signals (1ms)
                    tframes_highres_norm      =       round(tframes_highres -  time_event_incl(i));
                    
                    uniFileIdx = unique(FileIdx);  %
                    FileNum = length(unique(FileIdx)); % usually only one, only rarely, one event is distributed in two video files, eg., xxx +, xxx ++, etc.
                    img_extracted = [];
                    
                    for ifile = 1:FileNum
                        this_video = frameinfo.SeqVidFile{uniFileIdx(ifile)};
                        IdxFrames_thisfile = find(FileIdx == uniFileIdx(ifile)); % this video file
                        VidFrameIdx_thisfile = VidFrameIdx(IdxFrames_thisfile);  % these are the frame index in this video
                        tic
                        frames_ifile         =   ReadJpegSEQ(this_video, [VidFrameIdx_thisfile(1) VidFrameIdx_thisfile(end)]);
                        toc
                        for ii =1:size(frames_ifile, 1)
                            img_extracted = cat(3, img_extracted, double(frames_ifile{ii, 1}));
                        end;
                    end;
                    
                    % make press signal
                    if ~isempty(find(t_Press-itframes(1)>0 & t_Press-itframes(end)<0))
                        presses_thisvid   =       t_Press(t_Press-itframes(1)>0 & t_Press-itframes(end)<0);
                        releases_thisvid   =       t_Release(t_Press-itframes(1)>0 & t_Press-itframes(end)<0);  % release may be out of the frame range
                    else
                        presses_thisvid   =       [];
                        releases_thisvid   =       [];
                    end;
                    
                    press_signal = NaN*ones(size(tframes_highres));
                    if ~isempty(presses_thisvid)
                        for ipress = 1:length(presses_thisvid)
                            press_signal(tframes_highres>=presses_thisvid(ipress) & tframes_highres<=releases_thisvid(ipress)) = 0;
                        end;
                    end
                                        
                    % make trigger signal
                    if ~isempty(find(t_Trigger-itframes(1)>0 & t_Trigger-itframes(end)<0))
                        trigger_incls   =  t_Trigger((t_Trigger-itframes(1)>0 & t_Trigger-itframes(end)<0));
                    else
                        trigger_incls   =       [];
                    end;
                    
                    trigger_signal = NaN*ones(size(tframes_highres));
                    
                    if ~isempty(trigger_incls)
                        for itrigger = 1:length(trigger_incls)
                            trigger_signal(tframes_highres>=trigger_incls(itrigger) & tframes_highres<=trigger_incls(itrigger)+trigger_dur) =3.5;
                        end;
                    end;
                    
                    % build video clips, frame by frame
                    F= struct('cdata', [], 'colormap', []);
                    
                    VidMeta.Session               =          b.SessionName;
                    VidMeta.Event                   =          event;
                    VidMeta.EventIndex          =           ind_event_incl(i);
                    VidMeta.Performance       =           perf;
                    VidMeta.EventTime           =           time_event_incl(i);       % Event time in ms in behavior time
                    VidMeta.FrameTimesB     =           itframes;                        % frame time in ms in behavior time
                    VidMeta.VideoOrg            =           this_video;
                    VidMeta.FrameIndx          =            VidFrameIdx;                   % frame index in original video
                    VidMeta.Code                   =             mfilename('fullpath');
                    VidMeta.CreatedOn          =            date;                                % today's date
                    
                    video_acc = video_acc+1;
                    VidsMeta(video_acc) = VidMeta;
                    
                    for k =1:size(img_extracted, 3)
                        
                        hf25 = figure(25); clf
                        set(hf25, 'name', 'side view', 'units', 'centimeters', 'position', [ 3 5 15*1280/1024 20], 'PaperPositionMode', 'auto', 'color', 'w')
                        
                        ha= axes;
                        set(ha, 'units', 'centimeters', 'position', [0 5 15*1280/1024 15], 'nextplot', 'add', 'xlim',[0 1280], 'ylim', [0 1024], 'ydir','reverse')
                        axis off
                        % plot this frame:
                        imagesc(img_extracted(:, :, k), [0 250]);
                        colormap('gray')
                        
                        % plot some behavior data
                        time_of_frame = sprintf('%3.0f', round(itframes_norm(k)));
                        text(10, 30, [time_of_frame ' ms'], 'color', [246 233 35]/255, 'fontsize', 12,'fontweight', 'bold')
                        text(10, 700,  sprintf('%s',b.SessionName(1:10)), 'color', [255 255 255]/255, 'fontsize',  10, 'fontweight', 'bold')
                        text(10, 750,  sprintf('%s %03d', event, ind_event_incl(i)), 'color', [255 255 255]/255, 'fontsize',  10, 'fontweight', 'bold')
                        text(10, 800,  sprintf('FP %2.0f ms', iFP), 'color', [255 255 255]/255, 'fontsize',  10, 'fontweight', 'bold')
                        text(10, 850,  sprintf('RT %2.0f ms', RT), 'color', [255 255 255]/255, 'fontsize',  10, 'fontweight', 'bold')
                        text(10, 900,  perf, 'fontsize',  10, 'fontweight', 'bold','color', [255 255 255]/255, 'fontsize',  10, 'fontweight', 'bold')
                        
                        % plot some important behavioral events
                        ha2= axes;
                        set(ha2, 'units', 'centimeters', 'position', [0.5 1.25 17.5 3], 'nextplot', 'add', 'xlim',[-tpre-100 tpost],...
                            'xtick', [-5000:1000:10000], 'ytick', [0.5 2.5],'yticklabel', {'Press', 'Trigger'},'ylim', [-4 6.5], 'tickdir', 'out', 'ycolor', 'none')
                        xlabel('Time from approach (ms)')
                        indplot = find(tframes_highres < itframes(k), 1, 'last');
      
                        % plot press signals in shaded areas
                        press_epochs = tframes_highres_norm(find(~isnan(press_signal)));
                        
                        if ~isempty(press_epochs)
                        
                            press_begs = press_epochs([1 1+find(diff(press_epochs)>10)]);
                            press_ends = press_epochs([find(diff(press_epochs)>10) length(press_epochs)]);
                            
                            for ip =1:length(press_begs)
                                plotshaded([press_begs(ip) press_ends(ip)], [-3 -3; 3 3], [0.8 0.8 0.8]);
                            end;
                        end;
                        
%                         plot(tframes_highres_norm, press_signal, 'color', [0.8 0.8 0.8], 'linewidth', 2);
                        text(tframes_highres_norm(1)-100, -1, 'Press','fontsize', 10, 'color', 'k', 'fontweight', 'bold')
                        
                        plot(tframes_highres_norm, trigger_signal, 'color', [255 140 0]/255, 'linewidth', 2);
                        text(tframes_highres_norm(1)-100, 2, 'Trigger','fontsize', 10, 'color', 'k', 'fontweight', 'bold', 'color', [255 140 0]/255)
                        
                        % plot press data
                        if ~isempty(f_Press)
                            % itframes
                            indplot_WS = find(t_WS>= itframes(1) & t_WS<=itframes(end));
                            indplot_Press = f_Press(indplot_WS)*5;
                            plot(t_WS(indplot_WS) - time_event_incl(i), indplot_Press , 'k', 'linewidth', 2);
                        end;
                        
                        if Stim
                            plotshaded([delay delay+dur], [4.5 4.5; 5.5 5.5], 'b')
                            text(tframes_highres_norm(1)-100, 5, 'OptoStim','fontsize', 10, 'color', 'k', 'fontweight', 'bold', 'color', 'b')
                        else
                            text(tframes_highres_norm(1)-100, 5, 'No Stim','fontsize', 10, 'color', 'k', 'fontweight', 'bold', 'color', 'b')
                        end;
    
                        if ~isempty(indplot)
                            line([tframes_highres_norm(indplot) tframes_highres_norm(indplot)], [-4 6], 'color', 'k', 'linewidth', 1, 'linestyle', '--')
                        end;
                        
                        % plot or update data in this plot
                        F(k) = getframe(hf25) ;
%                         drawnow
  
                    end
                    % make a video clip and save it to the correct location
                    
                    writerObj = VideoWriter([video_name '.avi']);
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
                    movefile( [video_name '.avi'], thisFolder)
                    
                    MetaFileName = fullfile(thisFolder, [video_name, '.mat']);
                    save(MetaFileName, 'VidMeta');
                    
                end;
            end;
            toc
        end;
        video_meta = sprintf('%s_%s_ApproachVideosMeta', anm, session);
        save(video_meta, 'VidsMeta');
    otherwise
        errodlg('No idea what you want') 
end;

