function allpsth = ExtractAllPSTH(r, varargin)
% 4.17.2021  get PSTHs of all neurons from r
% similar to SRTSpikesV5 but won't make the plots. 
    
tpre = 2000;
tpost = 2000;

if nargin>1
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'tpre'
                tpre = varargin{i+1};
            case 'tpost'
                tpost = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end


tic

FRrange = [];
printname = [];
printsize = [2 2 20 16];

rb = r.Behavior;
% all FPs 
% time of all presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);
length(t_presses);
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
        
        if abs(ilapse-750)<abs(ilapse-1500)
            t_trigger_short_correct = [t_trigger_short_correct; it_trigger];
            dt=[dt min(ilapse)-750];
            plot(it_trigger-750, 4.8, 'r^');
        else
            t_trigger_long_correct = [t_trigger_long_correct; it_trigger];
            dt=[dt min(ilapse)-1500];
            plot(it_trigger-1500, 4.8, 'r^');
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
plot(t_triggers(ind_badtriggers), 1.2, 'ro', 'linewidth', 2)

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
t_correctsorted{1}      =   t_correctpresses(FPs_correctpresses == 750);
t_correctsorted{2}      =   t_correctpresses(FPs_correctpresses == 1500);

trelease_correctsorted{1}      =   t_correctreleases(FPs_correctpresses == 750);
trelease_correctsorted{2}      =   t_correctreleases(FPs_correctpresses == 1500);

rt_correctsorted{1}     =   rt_correct(FPs_correctpresses == 750);
[rt_correctsorted{1}, indsort] =  sort(rt_correctsorted{1});
t_correctsorted{1} = t_correctsorted{1}(indsort); 
trelease_correctsorted{1} = trelease_correctsorted{1}(indsort);

rt_correctsorted{2}     =   rt_correct(FPs_correctpresses == 1500);
[rt_correctsorted{2}, indsort] =  sort(rt_correctsorted{2});
t_correctsorted{2} = t_correctsorted{2}(indsort); 
trelease_correctsorted{2} = trelease_correctsorted{2}(indsort);

% derive PSTH from these
kus = 1:length(r.Units.SpikeTimes); % all units. 

params.pre = tpre;
params.post = tpost;
params.binwidth = 20;

% calculate PSTHs

allpsth = struct('press_correct', [], 't_press_correct', [],...
    'release_correct', [], 't_release_correct', [],...
    'reward', [], 't_reward', [],...
    'trigger_correct', [], 'trigger_late', [], 't_trigger', []);

for k =1:length(kus)
     
    ku = kus(k);
    
    [psth_correctall, tsall] = jpsth(r.Units.SpikeTimes(ku).timings, t_correctpresses, params);
    psth_correctall = smoothdata (psth_correctall, 'gaussian', 5);
    
    [psth_correct{1}, ts{1}, trialspxmat{1}, tspkmat{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{1}, params);
    psth_correct{1} = smoothdata (psth_correct{1}, 'gaussian', 5);
    
    [psth_correct{2}, ts{2}, trialspxmat{2}, tspkmat{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{2}, params);
    psth_correct{2} = smoothdata (psth_correct{2}, 'gaussian', 5);
    
    allpsth(k).press_correct = psth_correct;
    allpsth(k).t_press_correct = ts;
    
    [psth_release_correct{1}, ts_release{1}, trialspxmat_release{1}, tspkmat_release{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{1}, params);
    psth_release_correct{1} = smoothdata (psth_release_correct{1}, 'gaussian', 5);
    
    [psth_release_correct{2}, ts_release{2}, trialspxmat_release{2}, tspkmat_release{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{2}, params);
    psth_release_correct{2} = smoothdata (psth_release_correct{2}, 'gaussian', 5);
    
    allpsth(k).release_correct = psth_release_correct;
    allpsth(k).t_release_correct = ts_release;
    
    % premature press PSTH
    [psth_premature_press, ts_premature_press, trialspxmat_premature_press, tspkmat_premature_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurepresses, params);
    psth_premature_press = smoothdata (psth_premature_press, 'gaussian', 5);
    
    % premature release PSTH
    [psth_premature_release, ts_premature_release, trialspxmat_premature_release, tspkmat_premature_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurereleases, params);
    psth_premature_release = smoothdata (psth_premature_release, 'gaussian', 5);
    
    % late press PSTH
    [psth_late_press, ts_late_press, trialspxmat_late_press, tspkmat_late_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_latepresses, params);
    psth_late_press = smoothdata (psth_late_press, 'gaussian', 5);
    
    % late release PSTH
    [psth_late_release, ts_late_release, trialspxmat_late_release, tspkmat_late_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_latereleases, params);
    psth_late_release = smoothdata (psth_late_release, 'gaussian', 5);
    
    % reward PSTH 
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 5);
    
    allpsth(k).reward = psth_rew;
    allpsth(k).t_reward = ts_rew;
    
    % bad poke PSTH
    [psth_badpoke, ts_badpoke, trialspxmat_badpoke, tspkmat_badpoke] = jpsth(r.Units.SpikeTimes(ku).timings, t_badportin, params);
    psth_badpoke = smoothdata (psth_badpoke, 'gaussian', 5);
    
    % trigger PSTH 
    [psth_goodtrigger, ts_goodtrigger, trialspxmat_goodtrigger, tspkmat_goodtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_correct, params);
    psth_goodtrigger = smoothdata (psth_goodtrigger, 'gaussian', 5);
    [psth_badtrigger, ts_badtrigger, trialspxmat_badtrigger, tspkmat_badtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_late, params);
    psth_badtrigger = smoothdata (psth_badtrigger, 'gaussian', 5);
    
    [psth_shorttrigger, ts_shorttrigger, trialspxmat_shorttrigger, tspkmat_shorttrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_short_correct, params);
    psth_shorttrigger = smoothdata (psth_shorttrigger, 'gaussian', 5);
    
    [psth_longtrigger, ts_longtrigger, trialspxmat_longtrigger, tspkmat_longtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_long_correct, params);
    psth_longtrigger = smoothdata (psth_longtrigger, 'gaussian', 5);
    
    allpsth(k).trigger_correct = psth_goodtrigger;
    allpsth(k).trigger_late = psth_badtrigger;
    allpsth(k).t_trigger = ts_goodtrigger;
    
    close all;
end;

