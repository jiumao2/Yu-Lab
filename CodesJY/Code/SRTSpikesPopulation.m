function PSTHOut = SRTSpikesPopulation(r,  varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port.
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

%  r.Behavior.Labels
%     {'TBD1'}    {'TBD2'}    {'LeverPress'}    {'Trigger'}
%     {'LeverRelease'}    {'GoodPress'}    {'GoodRelease'}
%     {'ValveOnset'}    {'ValveOffset'}    {'PokeOnset'}
%     {'PokeOffset'}

if nargin<1
    load('RTarrayAll.mat')
end;


tic

FRrange = [];
printname = [];
printsize = [2 2 20 16];
tosave = 1;
FP_short = 750;
FP_long = 1500;
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'FRrange'
                FRrange = varargin{i+1};
            case 'Name'
                printname = varargin{i+1};
            case 'size'
                printsize = varargin{i+1};
            case 'tosave'
                tosave = varargin{i+1};
            case 'FP_short'
                FP_short = varargin{i+1};
            case 'FP_long'
                FP_long = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
else
end

rb = r.Behavior;
% all FPs
FPs = rb.Foreperiods;

% time of all presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);
length(t_presses)
% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);

% index of non-premature releases
ind_np = setdiff([1:length(rb.Foreperiods)],[rb.DarkIndex; rb.PrematureIndex]);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

% index and time of correct presses
t_correctpresses = t_presses(rb.CorrectIndex);
FPs_correctpresses = rb.Foreperiods(rb.CorrectIndex);
% index and time of correct releases
t_correctreleases = t_releases(rb.CorrectIndex);
% reaction time of correct responses
rt_correct = t_correctreleases - t_correctpresses - FPs_correctpresses;

% time of all triggers
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

t_triggers_correct = [];
ind_goodtriggers = [];
t_triggers_late = [];
t_trigger_short_correct =[];
t_trigger_long_correct =[];
ind_badtriggers = [];

figure(55); clf(55)
hax=axes;
dt=[];

for i = 1:length(t_triggers)
    
    it_trigger = t_triggers(i);
    [it_release, indminrelease] = min(abs(t_correctreleases-it_trigger));
    cla;
    plot(it_trigger,5, 'ro');
    hold on;
    plot(t_correctreleases, 5, 'b*');
    plot(t_correctpresses, 4.8, 'g*');
    
    set(gca, 'ylim', [2 8], 'nextplot', 'add')
    
    if it_release<2000
        % trigger followed by successful release
        t_triggers_correct = [t_triggers_correct; it_trigger];
        ind_goodtriggers = [ ind_goodtriggers i];
        
        % check if it is short or long FP
        ilapse = it_trigger-t_correctpresses(indminrelease);
        
        if abs(ilapse-FP_short)<abs(ilapse-FP_long)
            t_trigger_short_correct = [t_trigger_short_correct; it_trigger];
            dt=[dt min(ilapse)-FP_short];
            plot(it_trigger-FP_short, 4.8, 'r^');
        else
            t_trigger_long_correct = [t_trigger_long_correct; it_trigger];
            dt=[dt min(ilapse)-FP_long];
            plot(it_trigger-FP_long, 4.8, 'r^');
        end;
    else
        % trigger followed by late release
        t_triggers_late = [t_triggers_late; it_trigger];
        ind_badtriggers = [ind_badtriggers i];
    end;
    
end;

figure(56); clf;
plot(dt)

% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = rb.EventTimings(rb.EventMarkers == ind_portin);

ind_portout = find(strcmp(rb.Labels, 'PokeOffset'));
t_portout = rb.EventTimings(rb.EventMarkers == ind_portout);

% bad port access following an unsuccesful release event, t_portin and t_portout
ind_badportin = find(strcmp(rb.Labels, 'BadPokeFirstIn'));
t_badportin = rb.EventTimings(rb.EventMarkers == ind_badportin);

movetime = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correctreleases;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime(i) = dt(end);
    end;
end;

t_rewards = t_rewards(movetime>0);
movetime = movetime(movetime>0);
[movetime, indsort] = sort(movetime);
t_rewards = t_rewards(indsort);

% time of premature presses
t_prematurepresses = t_presses(rb.PrematureIndex);
t_prematurereleases = t_releases(rb.PrematureIndex);
FPs_prematurepresses = rb.Foreperiods(rb.PrematureIndex);

% time of late presses
t_latepresses = t_presses(rb.LateIndex);
t_latereleases = t_releases(rb.LateIndex);
FPs_latepresses = rb.Foreperiods(rb.LateIndex);

figure(57); clf

for i =1:length(t_presses)
    press_dur = [t_releases(i) t_presses(i)];
    line(press_dur, [1 1], 'color', 'k', 'linewidth', 2); hold on
    plot(press_dur, 1, 'color', 'k', 'marker','o', 'markersize', 4, 'linewidth',1)
end;
text(-1000, 1.1, 'Press', 'color', 'k')

hold on
plot(t_triggers, 1.2, 'g*')
text(-1000, 1.3, 'Trigger', 'color', 'g')
hold on;
if ~isempty(ind_badtriggers)
    plot(t_triggers(ind_badtriggers), 1.2, 'ro', 'linewidth', 2)
end;

for i =1:length(t_prematurepresses)
    plot(t_prematurepresses(i), 1.5, 'ko', 'markerfacecolor', 'r')
    ifp = FPs_prematurepresses(i); % current foreperiods
    itpress = t_prematurepresses(i);
    line([itpress itpress+ifp], [1.5 1.5], 'color', 'r', 'linewidth', 2)
end;
text(-1000, 1.6, 'Premature', 'color', 'r')

for i =1:length(t_latepresses)
    plot(t_latepresses(i), 1.8, 'ko', 'markerfacecolor', 'm')
    ifp = FPs_latepresses(i); % current foreperiods
    itpress = t_latepresses(i);
    line([itpress itpress+ifp], [1.8 1.8], 'color', 'm', 'linewidth', 2)
end;
text(-1000, 1.9, 'Late', 'color', 'r')

for i =1:length(t_portin)
    port_access = [t_portin(i) t_portout(i)];
    line(port_access, [2.4 2.4], 'color', 'b', 'linewidth', 2)
    plot(port_access, 2.4, 'color', 'b', 'marker','o', 'markersize', 4, 'linewidth',1)
end;
text(-1000, 2.5, 'Poke', 'color', 'b')

plot(t_rewards, 2.0, 'co', 'linewidth', 1)
text(-1000,  2.1, 'Reward', 'color', 'c')

set(gca, 'ylim', [0.5 3.5], 'xlim', [-5000 max(get(gca, 'xlim'))])

% get correct response 0.75 sec, and 1.5 sec
t_correctsorted{1}      =   t_correctpresses(FPs_correctpresses == FP_short);
t_correctsorted{2}      =   t_correctpresses(FPs_correctpresses == FP_long);

trelease_correctsorted{1}      =   t_correctreleases(FPs_correctpresses == FP_short);
trelease_correctsorted{2}      =   t_correctreleases(FPs_correctpresses == FP_long);

rt_correctsorted{1}     =   rt_correct(FPs_correctpresses == FP_short);
[rt_correctsorted{1}, indsort] =  sort(rt_correctsorted{1});
t_correctsorted{1} = t_correctsorted{1}(indsort);
trelease_correctsorted{1} = trelease_correctsorted{1}(indsort);

rt_correctsorted{2}     =   rt_correct(FPs_correctpresses == FP_long);
[rt_correctsorted{2}, indsort] =  sort(rt_correctsorted{2});
t_correctsorted{2} = t_correctsorted{2}(indsort);
trelease_correctsorted{2} = trelease_correctsorted{2}(indsort);

all_inds =  [1:size(r.Units.SpikeNotes, 1)]; % these are all units collected from this session

% Extract these event-related activity

Units = r.Units.SpikeNotes;

PSTH_Press                  =             cell(1, 2); % one for short FP, one for long FP
PSTH_PressZ                  =             cell(1, 2); % one for short FP, one for long FP 

PSTH_PressAll                  =             []; % merge short and long FPs
PSTH_PressAllZ                  =          []; % one for short FP, one for long FP 
PSTH_PressAllStat           =           [];

PSTH_PressStat          =               cell(1, 2); % this gives the statistics of press
PSTH_Release              =             cell(1, 2); 
PSTH_ReleaseZ              =             cell(1, 2);
PSTH_ReleaseStat       =             cell(1, 2); % this gives the statistics of release

PSTH_ReleaseAll                  =             []; % merge short and long FPs
PSTH_ReleaseAllZ                =             []; % one for short FP, one for long FP 
PSTH_ReleaseAllStat           =           [];

PSTH_Reward             =               [];
PSTH_RewardZ             =               [];
PSTH_RewardStat       =              []; % this gives the statistics of release

PSTH_Trigger             =               [];
PSTH_TriggerZ             =               [];
PSTH_TriggerStat       =              []; % this gives the statistics of trigger


for i = 1:length(all_inds)
    
    psth_i = [];
    tpsth_i = [];
    % derive PSTH from these
    ku = all_inds(i);
    params.pre = 4000;
    params.post = 5000;
    params.binwidth = 20;
    
    % extract PSTH from all correct presses
    [psth_correctpressall, tspressall, trialspxmatpressall, tspkmatpressall] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses, params);
    psth_correctpressall = smoothdata (psth_correctpressall, 'gaussian', 15);
    
    if i==1
        PSTH_PressAll(1, :) = tspressall;
        PSTH_PressAllZ(1, :) = tspressall;
    end;
     
    PSTH_PressAll = [PSTH_PressAll; psth_correctpressall];
    
    StatOut = ExamineTaskResponsive(tspkmatpressall, trialspxmatpressall);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_PressAllStat.StatOut(i)  = StatOut;
            
    [psth_correct{1}, ts{1}, trialspxmat{1}, tspkmat{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{1}, params);
    psth_correct{1} = smoothdata (psth_correct{1}, 'gaussian', 15);
    
    psth_i      =       [psth_correct{1}];  % use this to determine activity peaks    
    tpsth_i     =       ts{1};
    
    if i==1
        PSTH_Press{1}(1, :) = ts{1};
        PSTH_PressZ{1}(1, :) = ts{1};
    end;
    
    PSTH_Press{1} = [PSTH_Press{1}; psth_correct{1}];
%     psth_i = [psth_i psth_correct{1}];
    
    StatOut = ExamineTaskResponsive(tspkmat{1}, trialspxmat{1});
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_PressStat{1}.StatOut(i) =  StatOut;
    
    [psth_correct{2}, ts{2}, trialspxmat{2}, tspkmat{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{2}, params);
    psth_correct{2} = smoothdata (psth_correct{2}, 'gaussian', 15);
    
    if i==1
        PSTH_Press{2}(1, :) = ts{2};
        PSTH_PressZ{2}(1, :) = ts{2};
    end;
    
    PSTH_Press{2} = [PSTH_Press{2}; psth_correct{2}];
%     psth_i = [psth_i psth_correct{2}];
    
    StatOut = ExamineTaskResponsive(tspkmat{2}, trialspxmat{2});
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_PressStat{2}.StatOut(i) =  StatOut;
    
    
    %% Trigger PSTH
    params.pre = 500;
    params.post = 1000;
    
    [psth_goodtrigger, ts_goodtrigger, trialspxmat_goodtrigger, tspkmat_goodtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_correct, params);
    psth_goodtrigger = smoothdata (psth_goodtrigger, 'gaussian', 15);
    
    if i==1
        PSTH_Trigger(1, :) = ts_goodtrigger;
        PSTH_TriggerZ(1, :) = ts_goodtrigger;
    end;
    
    PSTH_Trigger = [PSTH_Trigger; psth_goodtrigger];
    
    StatOut = ExamineTaskResponsive(tspkmat_goodtrigger, trialspxmat_goodtrigger);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_TriggerStat.StatOut(i) =  StatOut;
            
    [psth_badtrigger, ts_badtrigger, trialspxmat_badtrigger, tspkmat_badtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_late, params);
    psth_badtrigger = smoothdata (psth_badtrigger, 'gaussian', 15);
    
    [psth_shorttrigger, ts_shorttrigger, trialspxmat_shorttrigger, tspkmat_shorttrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_short_correct, params);
    psth_shorttrigger = smoothdata (psth_shorttrigger, 'gaussian', 15);
    
    [psth_longtrigger, ts_longtrigger, trialspxmat_longtrigger, tspkmat_longtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_long_correct, params);
    psth_longtrigger = smoothdata (psth_longtrigger, 'gaussian', 15);
    
    %% Release
    params.pre = 500;
    params.post = 1000;
    params.binwidth = 20;
    
    % extract PSTH from all correct releases
    [psth_correctreleaseall, tsreleaseall, trialspxmatreleaseall, tspkmatreleaseall] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctreleases, params);
    psth_correctreleaseall = smoothdata (psth_correctreleaseall, 'gaussian', 15);
         
    if i==1
        PSTH_ReleaseAll(1, :) = tsreleaseall;
        PSTH_ReleaseAllZ(1, :) = tsreleaseall;
    end;
    
    PSTH_ReleaseAll = [PSTH_ReleaseAll; psth_correctreleaseall];
    
    StatOut = ExamineTaskResponsive(tspkmatreleaseall, trialspxmatreleaseall);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_ReleaseAllStat.StatOut(i)  = StatOut;
        
    [psth_release_correct{1}, ts_release{1}, trialspxmat_release{1}, tspkmat_release{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{1}, params);
    psth_release_correct{1} = smoothdata (psth_release_correct{1}, 'gaussian', 15);
    
    [psth_release_correct{2}, ts_release{2}, trialspxmat_release{2}, tspkmat_release{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{2}, params);
    psth_release_correct{2} = smoothdata (psth_release_correct{2}, 'gaussian', 15);
    
    if i==1
        PSTH_Release{1}(1, :) = ts_release{1};
        PSTH_ReleaseZ{1}(1, :) = ts_release{1};
    end;
    
    PSTH_Release{1} = [PSTH_Release{1}; psth_release_correct{1}];
%     psth_i = [psth_i psth_release_correct{1}];
    StatOut = ExamineTaskResponsive(tspkmat_release{1}, trialspxmat_release{1});
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_ReleaseStat{1}.StatOut(i) =  StatOut;
    
    if i==1
        PSTH_Release{2}(1, :) = ts_release{2};
        PSTH_ReleaseZ{2}(1, :) = ts_release{2};
    end;
    
    PSTH_Release{2} = [PSTH_Release{2}; psth_release_correct{2}];
%     psth_i = [psth_i psth_release_correct{2}];
     StatOut = ExamineTaskResponsive(tspkmat_release{2}, trialspxmat_release{2});
     StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_ReleaseStat{2}.StatOut(i) =  StatOut;
    
    %     % premature press PSTH
    %     [psth_premature_press, ts_premature_press, trialspxmat_premature_press, tspkmat_premature_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurepresses, params);
    %     psth_premature_press = smoothdata (psth_premature_press, 'gaussian', 5);
    %
    %     % premature release PSTH
    %     [psth_premature_release, ts_premature_release, trialspxmat_premature_release, tspkmat_premature_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurereleases, params);
    %     psth_premature_release = smoothdata (psth_premature_release, 'gaussian', 5);
    %
    %     % late press PSTH
    %     [psth_late_press, ts_late_press, trialspxmat_late_press, tspkmat_late_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_latepresses, params);
    %     psth_late_press = smoothdata (psth_late_press, 'gaussian', 5);
    %
    %     % late release PSTH
    %     [psth_late_release, ts_late_release, trialspxmat_late_release, tspkmat_late_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_latereleases, params);
    %     psth_late_release = smoothdata (psth_late_release, 'gaussian', 5);
    
    %% Reward PSTH
    params.pre = 1000;
    params.post = 2000;
    params.binwidth = 20;
    
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 15);
    
    if i==1
        PSTH_Reward(1, :) = ts_rew;
        PSTH_RewardZ(1, :) = ts_rew;
    end;
    
    PSTH_Reward = [PSTH_Reward;psth_rew];
    StatOut = ExamineTaskResponsive(tspkmat_rew, trialspxmat_rew);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_RewardStat.StatOut(i) =  StatOut;
    %
    %     % bad poke PSTH
    %     params.pre = 2000;
    %     params.post = 5000;
    %     [psth_badpoke, ts_badpoke, trialspxmat_badpoke, tspkmat_badpoke] = jpsth(r.Units.SpikeTimes(ku).timings, t_badportin, params);
    %     psth_badpoke = smoothdata (psth_badpoke, 'gaussian', 5);
    
    mean_psth_i         =        mean(psth_i);
    sd_psth_i              =        std(psth_i);
    
    PSTH_PressZ{1}      =     [PSTH_PressZ{1}; (psth_correct{1}-mean_psth_i)/sd_psth_i];
    PSTH_PressZ{2}      =     [PSTH_PressZ{2}; (psth_correct{2}-mean_psth_i)/sd_psth_i];
    PSTH_PressAllZ      =      [PSTH_PressAllZ; (psth_correctpressall-mean_psth_i)/sd_psth_i];
    
    PSTH_ReleaseZ{1}  =     [PSTH_ReleaseZ{1}; (psth_release_correct{1}-mean_psth_i)/sd_psth_i];
    PSTH_ReleaseZ{2}  =     [PSTH_ReleaseZ{2}; (psth_release_correct{2}-mean_psth_i)/sd_psth_i];
    PSTH_ReleaseAllZ  =      [PSTH_ReleaseAllZ; (psth_correctreleaseall-mean_psth_i)/sd_psth_i];
    
    PSTH_RewardZ      =     [PSTH_RewardZ; (psth_rew-mean_psth_i)/sd_psth_i];
    PSTH_TriggerZ       =      [PSTH_TriggerZ; (psth_goodtrigger-mean_psth_i)/sd_psth_i];

    
    close all;
end;

PSTHOut.Name                 =        r.Meta(1).Subject;
datestr = datevec(r.Meta(1).DateTime);
PSTHOut.Session          =    sprintf('%2.0d_%2.0d_%2.0d', datestr(1), datestr(2), datestr(3));
PSTHOut.Date              =        strrep(r.Meta(1).DateTime(1:11), '-','_')
PSTHOut.Units                  =        Units;
PSTHOut.Press                  =        PSTH_Press;
PSTHOut.PressZ                  =        PSTH_PressZ;
PSTHOut.PressStat           =        PSTH_PressStat;

PSTHOut.PressAll                  =        PSTH_PressAll;
PSTHOut.PressAllZ                  =        PSTH_PressAllZ;
PSTHOut.PressAllStat           =        PSTH_PressAllStat;

PSTHOut.Release             =        PSTH_Release;
PSTHOut.ReleaseZ             =        PSTH_ReleaseZ;
PSTHOut.ReleaseStat      =        PSTH_ReleaseStat;

PSTHOut.ReleaseAll             =        PSTH_ReleaseAll;
PSTHOut.ReleaseAllZ             =        PSTH_ReleaseAllZ;
PSTHOut.ReleaseAllStat      =        PSTH_ReleaseAllStat;

PSTHOut.Reward                =        PSTH_Reward;
PSTHOut.RewardZ                =        PSTH_RewardZ;
PSTHOut.RewardStat           =        PSTH_RewardStat;
PSTHOut.Trigger                  =        PSTH_Trigger;
PSTHOut.TriggerZ                =        PSTH_TriggerZ;
PSTHOut.TriggerStat           =        PSTH_TriggerStat;


PSTHOut.IndSort = VisualizePSTHPopulation(PSTHOut);
r.PopPSTH = PSTHOut;

% save RTarrayAll r

save('PopulationPSTH.mat', 'PSTHOut');

% Save a copy of PSTHOut to a collector folder
% thisFolder = fullfile(findonedrive, '\Work\Physiology\PSTHs');
% tosavename= fullfile(thisFolder, ['PopulationPSTH' '_' PSTHOut.Name '_' strrep(PSTHOut.Session, '-', '_')]);

% save(tosavename, 'PSTHOut')
VisualizePSTHPopulation(PSTHOut)
