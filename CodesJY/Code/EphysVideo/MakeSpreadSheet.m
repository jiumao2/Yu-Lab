function MakeSpreadSheet(b, frameinfo, varargin)

% The program creates a spread sheet for manual tracking of critical
% behavioral events in a video clip. 

% Jianing Yu
% 5/3/2021

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

ind_begs   =      [1 find(diff(tframesB)>1000)+1];
ind_ends   =      [find(diff(tframesB)>1000) length(tframesB)];
t_begs       =      tframesB(ind_begs); % beginning of each video segments, in behavior time
t_ends       =      tframesB(ind_ends); % ending of each video sgements, in behavior time

t_begs2     =      t_begs + tpre;
t_ends2     =      t_ends - tpost;

% identify video onset and offset
% beginning of new video segments (sometimes we record more than one video
% and there could be significan gap between these videos. obviously, events
% occuring within these gaps were not filmed.

switch event
    case {'press', 'Press'}
        t_events               =          b.PressTime*1000;  % this is the press time
        % Extract video-tapped events.
        ind_event_incl      =           []; % events that were captured by video, index in b
        time_event_incl    =           []; % events that were captured by video, time in b
        for k=1:length(t_begs2)
            ind_event_incl          =       [ind_event_incl     find(t_events>t_begs2(k) & t_events<t_ends2(k))];                         % this is the press index
            time_event_incl        =       [time_event_incl    t_events(find(t_events>t_begs2(k) & t_events<t_ends2(k)))];         % this is the time of these events, in ms
        end;
        
        % we have enough information at this point. 
        sheetname =   sprintf('%s_%s_Press.xlsx', anm, session);
        [presses_incl, ind_incl]        =       intersect(ind_event_incl, [b.Correct b.Premature b.Late]); % 'dark' events are not included. 
        presses_incl                        =       sort(presses_incl);
        presses_time_incl               =       sort(time_event_incl(ind_incl));
        
        PressIndex      =       presses_incl';
        PressTime       =       presses_time_incl';
        Outcome          =      cell( length(PressIndex), 1);
        FPs                  =      b.FPs(presses_incl); FPs = FPs';
        RTs                  =      NaN*ones(1, length(PressIndex)); 
        RTs = RTs';
        
        darkones = [];
        
        for ix =1:length(presses_incl)
            RTs(ix) = (b.ReleaseTime(presses_incl(ix)) - b.PressTime(presses_incl(ix)))*1000 - FPs(ix);
            if ~isempty(find(b.Correct==presses_incl(ix)))
                Outcome{ix} = 'Correct';
            elseif ~isempty(find(b.Premature==presses_incl(ix)))
                Outcome{ix} = 'Premature';
            elseif ~isempty(find(b.Late==presses_incl(ix)))
                Outcome{ix} = 'Late';
            else
                error('Something not right')
                darkones = [darkones presses_incl(ix)];
            end;
        end;
        
        RatName                          =  repmat({anm},  length(PressIndex), 1);
        SessionName                   = repmat({session},  length(PressIndex), 1);
        %% These are the important parameters to extract
        FlexOnset                   =       cell( length(PressIndex), 1);
        LeverTouch                       =       cell( length(PressIndex), 1);
        ReleaseOnset     =       cell( length(PressIndex), 1);
        % Hand
        PressPaw                            = repmat({'L--R--B'}, length(PressIndex), 1);
        HoldPaw                             = repmat({'L--R--B'}, length(PressIndex), 1);
        ReleasePaw                        = repmat({'L--R--B'}, length(PressIndex), 1);
        
        TableEvents        =        table(RatName, SessionName, PressIndex, PressTime, Outcome, FPs, RTs, FlexOnset, LeverTouch, ReleaseOnset, PressPaw, HoldPaw, ReleasePaw);

        writetable(TableEvents, sheetname);
        fclose('all')
        
    otherwise
        errodlg('No idea what you want')
end;

