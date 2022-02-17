function tevents = GetEventTimes(r)
% Jianing Yu
% 4/17/2021  get time of some critical events. 

% we now have the following useful information:
%  1.  t_correctsorted{1} ;   correct press time short FP
%  2.  t_correctsorted{2} ;   correct press time long FP
%  2.1. t_prematurepresses: time of premature press
%  2.2. t_latereleases: time of late press
%  3.  trelease_correctsorted{1}  correct release time short FP
%  4.  trelease_correctsorted{2}  correct release time long FP
%  5.  rt_correctsorted{1} ; reaction time short FP
%  6.  rt_correctsorted{2} ; reaction time long FP
%  7.  t_portin; poke time
%  8.  t_rewards; time of reward delivery


rb = r.Behavior;
% find out if trigger signals are associated with light on
indtrigger = find(strcmp(r.Behavior.Labels, 'Trigger'));
t_trigger = r.Behavior.EventTimings(r.Behavior.EventMarkers == indtrigger); 
t_press         =       [];% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 
% index of non-premature releases
ind_np = setdiff([1:length(rb.Foreperiods)],[rb.DarkIndex; rb.PrematureIndex]);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

%% extract basic information
% time of all presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));  % index
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);
 

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
    
    plot(t_correctpresses, t_correctreleases, 'ko')
    xlabel('press time')
    ylabel('release time')
    line([0 max(t_correctreleases)], [0 max(t_correctreleases)], 'color', 'k')
    
    if it_release<2000
        % trigger followed by successful release
        t_triggers_correct = [t_triggers_correct; it_trigger];
        ind_goodtriggers = [ ind_goodtriggers i];
        % check if it is short or long FP
        ilapse = it_trigger-t_correctpresses(indminrelease);
        if abs(ilapse-750)<abs(ilapse-1500)
            if abs(ilapse-750)<50
                t_trigger_short_correct = [t_trigger_short_correct; it_trigger];
                dt=[dt min(ilapse)-750];
            end
        else
            if abs(ilapse-1500)<50
                t_trigger_long_correct = [t_trigger_long_correct; it_trigger];
                dt=[dt min(ilapse)-1500];
            end;
        end;
    else
        % trigger followed by late release
        t_triggers_late = [t_triggers_late; it_trigger];
        ind_badtriggers = [ind_badtriggers i];
    end;
end;


figure(56); clf;
plot(dt, 'bp-'); set(gca, 'ylim', [-10 10])

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
% t_rewards = t_rewards(indsort); 

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
% [rt_correctsorted{1}, indsort] =  sort(rt_correctsorted{1});
% t_correctsorted{1} = t_correctsorted{1}(indsort); 
% trelease_correctsorted{1} = trelease_correctsorted{1}(indsort);

rt_correctsorted{2}     =   rt_correct(FPs_correctpresses == 1500);
% [rt_correctsorted{2}, indsort] =  sort(rt_correctsorted{2});
% t_correctsorted{2} = t_correctsorted{2}(indsort); 
% trelease_correctsorted{2} = trelease_correctsorted{2}(indsort);


figure(25); clf

plot(t_correctsorted{1},  2, 'ko');
hold on
plot(t_trigger_short_correct, 2.2, 'r*');
plot(t_correctsorted{1}+750, 2, 'r^');


plot(t_correctsorted{2},  5, 'ko');
hold on
plot(t_trigger_long_correct, 5.2, 'r*');
plot(t_correctsorted{2}+1500, 5, 'r^');
set(gca, 'ylim', [0 6])

tevents.press_correct                  =     t_correctsorted;
tevents.press_premature             =     t_prematurepresses;
tevents.press_late                        =     t_latepresses;

tevents.release_correct               =     trelease_correctsorted;
tevents.release_premature          =     t_prematurepresses;
tevents.release_late                     =     t_latepresses;

tevents.trigger                              =     t_triggers;
tevents.trigger_correct                 =     {t_trigger_short_correct,  t_trigger_long_correct };
tevents.trigger_late                       =     t_triggers_late;

tevents.pokein                              =     t_portin;
tevents.rewards                            =     t_rewards;
tevents.rt                                       =     rt_correctsorted;