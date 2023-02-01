function PSTHout = KornblumSpikesUnsorted(r, ind, varargin)
% revised 2022.10.7

% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port. 
% V5: add poke events following an unsuccesful release
% SRTSpikesTimeProduction: Kornblum style

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% KornblumSpikes(r, [1, 1])
% KornblumSpikes(r, 1)


if length(ind) ==2
    ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
    ind = ind_unit;
end;
    
tic
 
printname = [];
printsize = [2 2 20 17];
PressTimeDomain = [2000 2500];
electrode_type = 'Ch';
rasterheight = 0.02;
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'FRrange'
                FRrange = varargin{i+1};
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'Name'
                printname = varargin{i+1};
            case 'Size'
                printsize = varargin{i+1};
            case 'Tosave'
                tosave = varargin{i+1};
            case 'Type'
                electrode_type =  varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end 
end

rb = r.Behavior;

% index of Cued and Uncued trials

ind_cue = find(rb.CueIndex(:, 2) == 1);
ind_uncue = find(rb.CueIndex(:, 2) == 0);

ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);

% press for cue and uncue trials
t_presses_cue           =       t_presses(ind_cue);
t_presses_uncue       =       t_presses(ind_uncue);
t_presses_dark         =        t_presses(isnan(rb.CueIndex(:, 2)));

sprintf('There are %2.0f cued trials', length(t_presses_cue))
sprintf('There are %2.0f uncued trials', length(t_presses_uncue))
 
figure(8); clf
ha = axes('nextplot', 'add', 'xlim', [0.5 3.5], 'xtick', [1:3], 'xticklabel', {'Cued', 'Uncued', 'Dark'});
bar(1, length(t_presses_cue), 'FaceColor', 'k')
bar(2, length(t_presses_uncue), 'FaceColor', 'b')
bar(3, length(t_presses_dark), 'FaceColor', [0.7 0.7 0.7])
 ylabel('Number of presses')

% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 % press for cue and uncue trials
t_release_cue           =       t_releases(ind_cue);
t_release_uncue       =       t_releases(ind_uncue);
t_release_dark         =        t_releases(isnan(rb.CueIndex(:, 2)));

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);
t_rewards_cue = [];
t_rewards_uncue = [];

% check which reward is produced by cue vs uncue trials
for i =1:length(t_rewards)
    most_recent_cue = t_release_cue(find(t_release_cue-t_rewards(i)<0, 1, 'last'));
    most_recent_uncue = t_release_uncue(find(t_release_uncue-t_rewards(i)<0, 1, 'last'));
    if ~isempty(most_recent_cue) && ~isempty(most_recent_uncue)
        if most_recent_cue > most_recent_uncue
            t_rewards_cue = [t_rewards_cue t_rewards(i)];
        else
            t_rewards_uncue = [t_rewards_uncue t_rewards(i)];
        end;
    end;
end;

% index and time of correct presses
t_correctpresses = t_presses(rb.CorrectIndex);
FPs_correctpresses = rb.Foreperiods(rb.CorrectIndex);
FP_Kornblum = median(rb.Foreperiods); % This is the foreperiod of this session

[t_correctpresses_cue, ind_correct_cue]             =       intersect(t_correctpresses, t_presses_cue);
[t_correctpresses_uncue, ind_correct_uncue]     =       intersect(t_correctpresses, t_presses_uncue);

% index and time of correct releases
t_correctreleases                   =       t_releases(rb.CorrectIndex); 
t_correctreleases_cue           =       t_correctreleases(ind_correct_cue);
t_correctreleases_uncue       =       t_correctreleases(ind_correct_uncue);

% reaction time of correct responses
rt_correct                  =        t_correctreleases - t_correctpresses - FPs_correctpresses;
rt_correct_cue          =        rt_correct(ind_correct_cue);
rt_correct_uncue      =        rt_correct(ind_correct_uncue);

% sorting index
[rt_correct_cue_sorted, sortindex_cue] = fakeSort(rt_correct_cue);
[rt_correct_uncue_sorted, sortindex_uncue] = fakeSort(rt_correct_uncue);

t_correctpresses_cue = t_correctpresses_cue(sortindex_cue);
t_correctpresses_uncue = t_correctpresses_uncue(sortindex_uncue);

t_correctreleases_cue = t_correctreleases_cue(sortindex_cue);
t_correctreleases_uncue = t_correctreleases_uncue(sortindex_uncue);

% time of all triggers
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

t_triggers_correct = [];
ind_goodtriggers = [];
t_triggers_late = [];
ind_badtriggers = [];

figure(55); clf(55)
hax=axes;
dt=[];
for i = 1:length(t_triggers)    
    it_trigger = t_triggers(i);
    [it_release, ~] = min(abs(t_correctreleases-it_trigger));
    if it_release<2000
        % trigger followed by successful release
        t_triggers_correct = [t_triggers_correct; it_trigger];
        ind_goodtriggers = [ ind_goodtriggers i];
    else
        % trigger followed by late release
        t_triggers_late = [t_triggers_late; it_trigger];
        ind_badtriggers = [ind_badtriggers i];
    end;
end; 
  
% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = rb.EventTimings(rb.EventMarkers == ind_portin);

tpoke_reward = t_portin;
movetime = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correctreleases;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime(i) = dt(end);
    end;
end;
 
% only take positive move times
ind_movetimepos = find(movetime>0);
t_rewards = t_rewards(ind_movetimepos);
movetime = movetime(ind_movetimepos);

[t_rewards_cue, ind_reward_cue] = intersect(t_rewards, t_rewards_cue);
[t_rewards_uncue, ind_reward_uncue] = intersect(t_rewards, t_rewards_uncue);

movetime_cue = movetime(ind_reward_cue);
movetime_uncue = movetime(ind_reward_uncue);

[~, indmovesort_cue]            =    fakeSort(movetime_cue);
[~, indmovesort_uncue]        =    fakeSort(movetime_uncue);
                            
% sorted. 
t_rewards_cue                     =        t_rewards_cue(indmovesort_cue);
t_rewards_uncue                 =        t_rewards_uncue(indmovesort_uncue);

% time of premature presses
t_prematurepresses_cue = t_presses(intersect(rb.PrematureIndex, ind_cue));
t_prematurepresses_uncue = t_presses(intersect(rb.PrematureIndex, ind_uncue));
t_prematurereleases_cue = t_releases(intersect(rb.PrematureIndex, ind_cue));
t_prematurereleases_uncue = t_releases(intersect(rb.PrematureIndex, ind_uncue));                                             

pressdur_premature_cue              =    t_prematurereleases_cue - t_prematurepresses_cue;
pressdur_premature_uncue          =    t_prematurereleases_uncue - t_prematurepresses_uncue;

[~, ind_premature_cue] = fakeSort(pressdur_premature_cue);
t_prematurepresses_cue = t_prematurepresses_cue(ind_premature_cue);
t_prematurereleases_cue = t_prematurereleases_cue(ind_premature_cue);

[~, ind_premature_uncue] = fakeSort(pressdur_premature_uncue);
t_prematurepresses_uncue = t_prematurepresses_uncue(ind_premature_uncue);
t_prematurereleases_uncue = t_prematurereleases_uncue(ind_premature_uncue);

% time of late presses
t_latepresses_cue = t_presses(intersect(rb.LateIndex, ind_cue));
t_latepresses_uncue = t_presses(intersect(rb.LateIndex, ind_uncue));

t_latereleases_cue = t_releases(intersect(rb.LateIndex, ind_cue));
t_latereleases_uncue = t_releases(intersect(rb.LateIndex, ind_uncue));

pressdur_late_cue              =    t_latereleases_cue - t_latepresses_cue;
pressdur_late_uncue          =    t_latereleases_uncue - t_latepresses_uncue;

[~, ind_late_cue] = fakeSort(pressdur_late_cue);

t_latepresses_cue = t_latepresses_cue(ind_late_cue);
t_latereleases_cue = t_latereleases_cue(ind_late_cue);

[~, ind_late_uncue] = fakeSort(pressdur_late_uncue);
t_latepresses_uncue = t_latepresses_uncue(ind_late_uncue);
t_latereleases_uncue = t_latereleases_uncue(ind_late_uncue);

% derive PSTH from these
ku = ind;
params.pre = 4000;
params.post = 2500;
params.binwidth = 20;

if ku>length(r.Units.SpikeTimes)
    display('##########################################')
    display('########### That is all you have ##############')
    display('##########################################')
    return
end;

params_press.pre            =              PressTimeDomain(1);
params_press.post           =              PressTimeDomain(2);
params_press.binwidth     =              20;       

params_release.pre            =              1000;
params_release.post           =              2000;
params_release.binwidth     =              20;       

params_reward.pre            =              2000;
params_reward.post           =              4000;
params_reward.binwidth     =              20;  

params_trigger.pre            =              1000;
params_trigger.post           =              1000;
params_trigger.binwidth     =              20;  

%% Build PSTH
PSTHOut = [];

% all presses
[psth_pressall,~, trialspxmat_pressall, tspkmat_pressall, t_presses] = jpsth(r.Units.SpikeTimes(ku).timings,  t_presses, params_press);
 
% correct presses, 1. cue, 2, uncue
[psth_correct{1}, ts{1}, trialspxmat{1}, tspkmat{1},  t_correctsorted{1}] = jpsth(r.Units.SpikeTimes(ku).timings, t_correctpresses_cue, params_press);
psth_correct{1} = smoothdata (psth_correct{1}, 'gaussian', 5);
  
[psth_correct{2}, ts{2}, trialspxmat{2}, tspkmat{2}, t_correctsorted{2}] = jpsth(r.Units.SpikeTimes(ku).timings, t_correctpresses_uncue, params_press);
psth_correct{2} = smoothdata (psth_correct{2}, 'gaussian', 5);

[psth_correct{3}, ts{3}, trialspxmat{3}, tspkmat{3}, t_correctsorted{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_correctpresses_cue; t_correctpresses_uncue], params_press);
psth_correct{3} = smoothdata (psth_correct{3}, 'gaussian', 5);

PSTHOut.Labelings      = {'PSTH', 'tPSTH', 'SpkMat', 'tSpkMat', 'tEvents'};
PSTHOut.Types            = {'Cued', 'Uncued', 'Both'};
PSTHOut.CorrectPress = {psth_correct, ts,trialspxmat, tspkmat, t_correctsorted};

 % correct releases, 1, cue, 2, uncue
[psth_release_correct{1}, ts_release{1}, trialspxmat_release{1}, tspkmat_release{1},trelease_correctsorted{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctreleases_cue, params_release);
psth_release_correct{1} = smoothdata (psth_release_correct{1}, 'gaussian', 5);
     
[psth_release_correct{2}, ts_release{2}, trialspxmat_release{2}, tspkmat_release{2},trelease_correctsorted{2}] = jpsth(r.Units.SpikeTimes(ku).timings, t_correctreleases_uncue, params_release);
psth_release_correct{2} = smoothdata (psth_release_correct{2}, 'gaussian', 5);

[psth_release_correct{3}, ts_release{3}, trialspxmat_release{3}, tspkmat_release{3},trelease_correctsorted{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_correctreleases_cue; t_correctreleases_uncue], params_release);
psth_release_correct{3} = smoothdata (psth_release_correct{3}, 'gaussian', 5);

PSTHOut.CorrectRelease = {psth_release_correct, ts_release,trialspxmat_release, tspkmat_release, trelease_correctsorted};

% premature press PSTH
[psth_premature_press{1}, ts_premature_press{1}, trialspxmat_premature_press{1}, tspkmat_premature_press{1}, t_prematurepresses{1}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurepresses_cue], params_press);
psth_premature_press{1} = smoothdata (psth_premature_press{1}, 'gaussian', 5);    

[psth_premature_press{2}, ts_premature_press{2}, trialspxmat_premature_press{2}, tspkmat_premature_press{2}, t_prematurepresses{2}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurepresses_uncue], params_press);
psth_premature_press{2} = smoothdata (psth_premature_press{2}, 'gaussian', 5);    

[psth_premature_press{3}, ts_premature_press{3}, trialspxmat_premature_press{3}, tspkmat_premature_press{3}, t_prematurepresses{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurepresses_cue; t_prematurepresses_uncue], params_press);
psth_premature_press{3} = smoothdata (psth_premature_press{3}, 'gaussian', 5);    

PSTHOut.PrematurePress = {psth_premature_press, ts_premature_press,trialspxmat_premature_press,...
    tspkmat_premature_press, t_prematurepresses};

% premature release PSTH
[psth_premature_release{1}, ts_premature_release{1}, trialspxmat_premature_release{1}, tspkmat_premature_release{1}, t_prematurerelease{1}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurereleases_cue], params_release);
psth_premature_release{1} = smoothdata (psth_premature_release{1}, 'gaussian', 5);    

[psth_premature_release{2}, ts_premature_release{2}, trialspxmat_premature_release{2}, tspkmat_premature_release{2}, t_prematurerelease{2}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurereleases_uncue], params_release);
psth_premature_release{2} = smoothdata (psth_premature_release{2}, 'gaussian', 5);    

[psth_premature_release{3}, ts_premature_release{3}, trialspxmat_premature_release{3}, tspkmat_premature_release{3}, t_prematurerelease{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_prematurereleases_cue; t_prematurereleases_uncue], params_release);
psth_premature_release{3} = smoothdata (psth_premature_release{3}, 'gaussian', 5);    

PSTHOut.PrematureRelease = {psth_premature_release, ts_premature_release, trialspxmat_premature_release,...
    tspkmat_premature_release, t_prematurerelease};

% late press PSTH
[psth_late_press{1}, ts_late_press{1}, trialspxmat_late_press{1}, tspkmat_late_press{1}, t_latepresses{1}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latepresses_cue], params_press);
psth_late_press{1} = smoothdata (psth_late_press{1}, 'gaussian', 5);    

[psth_late_press{2}, ts_late_press{2}, trialspxmat_late_press{2}, tspkmat_late_press{2}, t_latepresses{2}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latepresses_uncue], params_press);
psth_late_press{2} = smoothdata (psth_late_press{2}, 'gaussian', 5);  

[psth_late_press{3}, ts_late_press{3}, trialspxmat_late_press{3}, tspkmat_late_press{3}, t_latepresses{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latepresses_cue; t_latepresses_uncue], params_press);
psth_late_press{3} = smoothdata (psth_late_press{3}, 'gaussian', 5);  

PSTHOut.LatePress = {psth_late_press, ts_late_press, trialspxmat_late_press,...
    tspkmat_late_press, t_latepresses};

% late release PSTH
[psth_late_release{1}, ts_late_release{1}, trialspxmat_late_release{1}, tspkmat_late_release{1}, t_laterelease{1}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latereleases_cue], params_release);
psth_late_release{1} = smoothdata (psth_late_release{1}, 'gaussian', 5);    
[psth_late_release{2}, ts_late_release{2}, trialspxmat_late_release{2}, tspkmat_late_release{2}, t_laterelease{2}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latereleases_uncue], params_release);
psth_late_release{2} = smoothdata (psth_late_release{2}, 'gaussian', 5);    
[psth_late_release{3}, ts_late_release{3}, trialspxmat_late_release{3}, tspkmat_late_release{3}, t_laterelease{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_latereleases_cue; t_latereleases_uncue], params_release);
psth_late_release{3} = smoothdata (psth_late_release{3}, 'gaussian', 5);  
PSTHOut.LateRelease = {psth_late_release, ts_late_release, trialspxmat_late_release,...
    tspkmat_late_release, t_laterelease};

[psth_rew{1}, ts_rew{1}, trialspxmat_rew{1}, tspkmat_rew{1}, time_rewards{1}] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards_cue, params_reward);
psth_rew{1} = smoothdata (psth_rew{1}, 'gaussian', 5);
[psth_rew{2}, ts_rew{2}, trialspxmat_rew{2}, tspkmat_rew{2}, time_rewards{2}] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards_uncue, params_reward);
psth_rew{2} = smoothdata (psth_rew{2}, 'gaussian', 5);
[psth_rew{3}, ts_rew{3}, trialspxmat_rew{3}, tspkmat_rew{3}, time_rewards{3}] = jpsth(r.Units.SpikeTimes(ku).timings, [t_rewards_cue; t_rewards_uncue], params_reward);
psth_rew{3} = smoothdata (psth_rew{3}, 'gaussian', 5);

PSTHOut.Reward = {psth_rew, ts_rew, trialspxmat_rew,...
    tspkmat_rew, time_rewards};

% trigger PSTH 
 
[psth_goodtrigger, ts_goodtrigger, trialspxmat_goodtrigger, tspkmat_goodtrigger, t_triggers_correct] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_correct, params_trigger);
psth_goodtrigger = smoothdata (psth_goodtrigger, 'gaussian', 5);
[psth_badtrigger, ts_badtrigger, trialspxmat_badtrigger, tspkmat_badtrigger, t_triggers_late] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_late, params_trigger);
psth_badtrigger = smoothdata (psth_badtrigger, 'gaussian', 5);

PSTHOut.Trigger = {psth_goodtrigger, ts_goodtrigger, trialspxmat_goodtrigger,...
    tspkmat_goodtrigger, t_triggers_correct};
PSTHOut.TriggerLate = {psth_badtrigger, ts_badtrigger, trialspxmat_badtrigger,...
    tspkmat_badtrigger, t_triggers_late};
  
close all;

%% plot raster and spks
cue_linewidth           =    1.5;
uncue_linewidth       =    1.5;

if sum(ind_cue)<0.5*sum(ind_uncue)
    cue_linewidth = 0.75;
end;

hf=27;
figure(27); clf(27)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')

ha1 =  axes('unit', 'centimeters', 'position', [1 1 5 2], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
% ind_cue = find(rb.CueIndex(:, 2) == 1);
% ind_uncue = find(rb.CueIndex(:, 2) == 0);
plot(PSTHOut.CorrectPress{2}{1}, PSTHOut.CorrectPress{1}{1}, 'b', 'linewidth', cue_linewidth); hold on
plot(PSTHOut.CorrectPress{2}{2}, PSTHOut.CorrectPress{1}{2}, 'k', 'linewidth', uncue_linewidth);
FRMax1 = max(cell2mat(PSTHOut.CorrectPress{1}));
set(ha1, 'ylim', [0 FRMax1*1.25])

FPline = line([FP_Kornblum FP_Kornblum], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1);
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1);

xlabel('Time from press (ms)')
ylabel ('Spks per s')
latecol =  [162 20 47]/255;
% error trials
ha1b =  axes('unit', 'centimeters', 'position', [1 3.5 5 2], 'nextplot', 'add', 'xlim',  [-PressTimeDomain(1) PressTimeDomain(2)]);
% plot premature and late as well

if  size(PSTHOut.PrematurePress{3}{3}, 2)>5
    plot(PSTHOut.PrematurePress{2}{3}, PSTHOut.PrematurePress{1}{3}, 'color', [0.6 0.6 0.6], 'linewidth',1);
end;

if  size(PSTHOut.LatePress{3}{3}, 2)>5
    plot(PSTHOut.LatePress{2}{3}, PSTHOut.LatePress{1}{3}, 'color', latecol, 'linewidth',1);
end;

set(ha1b, 'ylim', [0 FRMax1*1.25]) 
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

%% make raster plot  Cued trials

SpkMat = PSTHOut.CorrectPress{3}{1};
tSpkMat = PSTHOut.CorrectPress{4}{1};
EvenTimes = PSTHOut.CorrectPress{5}{1};
ntrial1 = size(SpkMat, 2);

ha =  axes('unit', 'centimeters', 'position', [1 5.5+0.5 5 ntrial1*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial1 1], 'box', 'on');
k =0;
for i =1:size(SpkMat, 2)    
    irt =rt_correct_cue_sorted(i);
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    xxrt = [irt+FP_Kornblum; irt+FP_Kornblum];
    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    
    % port time
    itpress = EvenTimes(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end 
end;

line([FP_Kornblum FP_Kornblum], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1);
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Cued')

%% make raster plot uncued trials
SpkMat = PSTHOut.CorrectPress{3}{2};
tSpkMat = PSTHOut.CorrectPress{4}{2};
EvenTimes = PSTHOut.CorrectPress{5}{2};
ntrial2 = size(SpkMat, 2);
yshift = 5.5+0.5+ntrial1*rasterheight+0.5;

ha2 =  axes('unit', 'centimeters', 'position', [1 yshift 5 ntrial2*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
   'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial2 1], 'box', 'on');

k =0;
for i =1:size(SpkMat, 2)
    
    irt =rt_correct_uncue_sorted(i);
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    xxrt = [irt+FP_Kornblum; irt+FP_Kornblum];

    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;

    % port time
    itpress = EvenTimes(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Uncued')

%% Premature press raster

SpkMat1                                =    PSTHOut.PrematurePress{3}{1};
tSpkMat                                 =    PSTHOut.PrematurePress{4}{1};
PrematurePressTimes1         =    PSTHOut.PrematurePress{5}{1};
PrematureReleaseTimes1     =    PSTHOut.PrematureRelease{5}{1};
ntrial3 = size(SpkMat1, 2);

SpkMat2          =    PSTHOut.PrematurePress{3}{2}; 
PrematurePressTimes2         =    PSTHOut.PrematurePress{5}{2};
PrematureReleaseTimes2     =    PSTHOut.PrematureRelease{5}{2};
ntrial4 = size(SpkMat2, 2);

ntrial_premature = ntrial3 + ntrial4; 
SpkMatPremature = [SpkMat1 SpkMat2];
PressPremature =[PrematurePressTimes1; PrematurePressTimes2];
PressDurPremature = [PrematureReleaseTimes1-PrematurePressTimes1; PrematureReleaseTimes2-PrematurePressTimes2];

yshift = yshift + ntrial2*rasterheight +0.5;
ha =  axes('unit', 'centimeters', 'position', [1 yshift 5 ntrial_premature*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
    'xlim',[-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial_premature 1], 'box', 'on');

line([FP_Kornblum FP_Kornblum], [-ntrial3, 1], 'color', 'm', 'linestyle', '-.', 'linewidth', 1)

k =0;
for i =1:size(SpkMatPremature, 2)    
    iPressDur=PressDurPremature(i);
    xx = tSpkMat(find(SpkMatPremature(:, i)));
    yy = [0 1]-k;
    xxrt = [iPressDur;iPressDur];
    if  isempty(find(isnan(SpkMatPremature(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', [0.6 0.6 0.6], 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    % port time
    itpress = PressPremature(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Premature presses')

%%  late press raster
SpkMat5                       =     PSTHOut.LatePress{3}{1};
tSpkMat                        =        PSTHOut.LatePress{4}{1};
LatePressTimes1         =       PSTHOut.LatePress{5}{1};
LateReleaseTimes1     =    PSTHOut.LateRelease{5}{1};
ntrial5 = size(SpkMat5, 2);

SpkMat6          =    PSTHOut.LatePress{3}{2}; 
LatePressTimes2         =    PSTHOut.LatePress{5}{2};
LateReleaseTimes2     =    PSTHOut.LateRelease{5}{2};
ntrial6 = size(SpkMat6, 2);

ntrial_late = ntrial5 + ntrial6; 
SpkMatLate = [SpkMat5 SpkMat6];
PressLate =[LatePressTimes1;LatePressTimes2];
PressDurLate = [LateReleaseTimes1-LatePressTimes1; LateReleaseTimes2-LatePressTimes2];

yshift = yshift + ntrial_premature*rasterheight+0.5;

ha =  axes('unit', 'centimeters', 'position', [1 yshift 5  ntrial_late*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
     'xlim',[-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial_late 1], 'box', 'on');

line([FP_Kornblum FP_Kornblum], [-ntrial5, 1], 'color', 'm', 'linestyle', '-.', 'linewidth', 1)

yshift = yshift + ntrial_late*rasterheight +0.5;

k =0;
for i =1:size(SpkMatLate, 2)
    
    iPressDur=PressDurLate(i);
    xx = tSpkMat(find(SpkMatLate(:, i)));
    yy = [0 1]-k;
    xxrt = [iPressDur;iPressDur];

    if  isempty(find(isnan(SpkMatLate(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;

    % port time
    itpress = PressLate(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Late presses')

%% Release PSTH
% this is the position of last panel
yfirstcolumn = [1 yshift+ntrial_late*rasterheight+0.5];
ycolumn2 = [8 yshift+ntrial_late*rasterheight+0.5];

ha4 =  axes('unit', 'centimeters', 'position', [7 1 5 2], 'nextplot', 'add', 'xlim', [-params_release.pre params_release.post ]);

plot(PSTHOut.CorrectRelease{2}{1}, PSTHOut.CorrectRelease{1}{1}, 'b', 'linewidth', cue_linewidth); hold on
plot(PSTHOut.CorrectRelease{2}{2}, PSTHOut.CorrectRelease{1}{2}, 'k', 'linewidth', uncue_linewidth);

xlabel('Time from release (ms)')
ylabel ('Spks per s')

FRMax2 = max(cell2mat(PSTHOut.CorrectRelease{1}));
set(ha4, 'ylim', [0 FRMax2*1.25])
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

% error trials
ha4b =  axes('unit', 'centimeters', 'position', [7 3.5 5 2], 'nextplot', 'add', 'xlim',  [-params_release.pre params_release.post]);
% plot premature and late as well

if  size(PSTHOut.PrematureRelease{3}{3}, 2)>5
    plot(PSTHOut.PrematureRelease{2}{3}, PSTHOut.PrematureRelease{1}{3}, 'color', [0.6 0.6 0.6], 'linewidth',1);
end;

if  size(PSTHOut.LateRelease{3}{3}, 2)>5
    plot(PSTHOut.LateRelease{2}{3}, PSTHOut.LateRelease{1}{3}, 'color', latecol, 'linewidth',1);
end;

set(ha4b, 'ylim', [0 FRMax2*1.25]) 
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

%% Make release raster plot cue

SpkMat = PSTHOut.CorrectRelease{3}{1};
tSpkMat = PSTHOut.CorrectRelease{4}{1};
EvenTimes = PSTHOut.CorrectRelease{5}{1};
ntrial1 = size(SpkMat, 2);
yshift = 5.5+0.5;

ha5 =  axes('unit', 'centimeters', 'position', [7 yshift 5 ntrial1*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-params_release.pre params_release.post], 'ylim', [-ntrial1 1], 'box', 'on');
 k =0;
rt_correct_cue_sorted;

for i =1:size(SpkMat, 2)
    
    irt =rt_correct_cue_sorted(i);
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    xxrt = [-irt;-irt];

    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'm', 'linewidth', 1.5)
        k = k+1;
    end;
    
    % port time
    itpress = EvenTimes(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-params_release.pre & i_portin<=params_release.post);
    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
 
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Cued')


%% Make release raster plot uncue
SpkMat = PSTHOut.CorrectRelease{3}{2};
tSpkMat = PSTHOut.CorrectRelease{4}{2};
EvenTimes = PSTHOut.CorrectRelease{5}{2};
ntrial2= size(SpkMat, 2);

yshift = yshift + ntrial1*rasterheight + 0.5;
ha3 =  axes('unit', 'centimeters', 'position', [7 yshift 5 ntrial2*rasterheight],...
    'nextplot', 'add', 'xticklabel', [],...
    'xlim',[-params_release.pre params_release.post], 'ylim', [-ntrial2 1], 'box', 'on');

k =0;

for i =1:size(SpkMat, 2)
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        k = k+1;
    end;
    % port time
    itpress = EvenTimes(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-params_release.pre & i_portin<=params_release.post);
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Uncued')

%% Make premature raster
yshift = yshift + ntrial2*rasterheight + 0.5;

SpkMat1                                =    PSTHOut.PrematureRelease{3}{1};
tSpkMat                                 =    PSTHOut.PrematureRelease{4}{1};

PrematurePressTimes1         =    PSTHOut.PrematurePress{5}{1};
PrematureReleaseTimes1     =    PSTHOut.PrematureRelease{5}{1};
ntrial3 = size(SpkMat1, 2);

SpkMat2          =    PSTHOut.PrematureRelease{3}{2}; 

PrematurePressTimes2         =    PSTHOut.PrematurePress{5}{2};
PrematureReleaseTimes2     =    PSTHOut.PrematureRelease{5}{2};

ntrial4 = size(SpkMat2, 2);
ntrial_premature = ntrial3 + ntrial4; 
SpkMatPremature = [SpkMat1 SpkMat2];
PressPremature =[PrematurePressTimes1; PrematurePressTimes2];

ha =  axes('unit', 'centimeters', 'position', [7 yshift 5 ntrial_premature*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
    'xlim',[-params_release.pre params_release.post], 'ylim', [-ntrial_premature 1], 'box', 'on');

% line([FP_Kornblum FP_Kornblum], [-ntrial3, 1], 'color', 'm', 'linestyle', '-.', 'linewidth', 1)

k =0;
for i =1:size(SpkMatPremature, 2)
     
    xx = tSpkMat(find(SpkMatPremature(:, i)));
    yy = [0 1]-k;
 
    if  isempty(find(isnan(SpkMatPremature(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', [0.6 0.6 0.6], 'linewidth', 1)
        end;
 
        k = k+1;
    end;

    % port time
    itpress = PressPremature(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=--params_release.pre & i_portin<=params_release.post);
    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Premature release')


%%  late press raster

SpkMat5                      =    PSTHOut.LatePress{3}{1};
tSpkMat                       =    PSTHOut.LatePress{4}{1};
LatePressTimes1         =    PSTHOut.LatePress{5}{1};
LateReleaseTimes1     =    PSTHOut.LateRelease{5}{1};
ntrial5 = size(SpkMat5, 2);

SpkMat6          =    PSTHOut.LatePress{3}{2}; 
LatePressTimes2         =    PSTHOut.LatePress{5}{2};
LateReleaseTimes2     =    PSTHOut.LateRelease{5}{2};
ntrial6 = size(SpkMat6, 2);

ntrial_late = ntrial5 + ntrial6; 
SpkMatLate = [SpkMat5 SpkMat6];
PressLate =[LatePressTimes1;LatePressTimes2];
PressDurLate = [LateReleaseTimes1-LatePressTimes1; LateReleaseTimes2-LatePressTimes2];

yshift = yshift + ntrial_premature*rasterheight+0.5;

ha =  axes('unit', 'centimeters', 'position', [7 yshift 5  ntrial_late*rasterheight],...
    'nextplot', 'add',  'xticklabel', [],...
      'xlim',[-params_release.pre params_release.post], 'ylim', [-ntrial_late 1], 'box', 'on');

k =0;
for i =1:size(SpkMatLate, 2)    
    iPressDur=PressDurLate(i);
    xx = tSpkMat(find(SpkMatLate(:, i)));
    yy = [0 1]-k;
    xxrt = [iPressDur;iPressDur];
    if  isempty(find(isnan(SpkMatLate(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        line([xxrt xxrt], yy, 'color', 'g', 'linewidth', 1.5)
        k = k+1;
    end;
    % port time
    itpress = PressLate(i);
    i_portin = tpoke_reward-itpress;
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Late presses')

%% Reward
ha7 =  axes('unit', 'centimeters', 'position', [13.5 1 6 2], 'nextplot', 'add', 'xlim', [-params_reward.pre params_reward.post ]);

plot(PSTHOut.Reward{2}{1}, PSTHOut.Reward{1}{1}, 'b', 'linewidth', cue_linewidth); hold on
plot(PSTHOut.Reward{2}{2}, PSTHOut.Reward{1}{2}, 'k', 'linewidth', uncue_linewidth);

xlabel('Time from reward delivery (ms)')
ylabel ('Spks per s')

FRMax3 = max(cell2mat(PSTHOut.Reward{1}));

set(ha7, 'ylim', [0 FRMax3*1.25+0.01])

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)


%% Make raster plot for reward
SpkMat = PSTHOut.Reward{3}{1};
tSpkMat = PSTHOut.Reward{4}{1};
EvenTimes = PSTHOut.Reward{5}{1};
ntrial1 = size(SpkMat, 2);
% EvenTimes = PSTHOut.CorrectRelease{5}{1};

ha =  axes('unit', 'centimeters', 'position', [13.5 3.5 6 ntrial1*rasterheight],...
    'nextplot', 'add',...
    'xlim',[-params_reward.pre params_reward.post], 'ylim', [-ntrial1 1], 'box', 'on');
k =0;
for i =1:size(SpkMat, 2)    
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'b', 'linewidth', 1)
        end;
        k = k+1;
    end;    
    % port time
    itreward = EvenTimes(i);
    i_portin = tpoke_reward-itreward;
    i_portin = i_portin(i_portin>=-params_reward.pre & i_portin<= params_reward.post);    
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end 
end;
 
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Cued')

%% Reward from uncued reward
yshift = 3.5+  ntrial1*rasterheight +0.5;
SpkMat = PSTHOut.Reward{3}{2};
tSpkMat = PSTHOut.Reward{4}{2};
EvenTimes = PSTHOut.Reward{5}{2};
ntrial2 = size(SpkMat, 2);

ha =  axes('unit', 'centimeters', 'position', [13.5 yshift 6 ntrial2*rasterheight],...
    'nextplot', 'add',...
    'xlim',[-params_reward.pre params_reward.post], 'xtick', [], 'ylim', [-ntrial2 1], 'box', 'on');
k =0;
for i =1:size(SpkMat, 2)    
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color',[0.6 0.6 0.6], 'linewidth', 1.5)
        end;
        k = k+1;
    end;    
    % port time
    itreward = EvenTimes(i);
    i_portin = tpoke_reward-itreward;
    i_portin = i_portin(i_portin>=-params_reward.pre & i_portin<= params_reward.post);   
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end 
end; 
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Uncued')
%% plot trigger-related activity 
yshift = yshift + ntrial2*rasterheight + 1.2;
ha9 =  axes('unit', 'centimeters', 'position', [13.5 yshift 6 2], 'nextplot', 'add',...
    'xlim', [-params_trigger.pre params_trigger.post]);
plot(PSTHOut.Trigger{2}, PSTHOut.Trigger{1}, 'k', 'linewidth', 1.5); hold on
if length(PSTHOut.TriggerLate{5})>5
    plot(PSTHOut.TriggerLate{2}, PSTHOut.TriggerLate{1}, 'color', latecol, 'linewidth', 0.5);
end;
xlabel('Time from trigger (ms)')
ylabel ('Spks per s')

FRMax4 = max((PSTHOut.Trigger{1}));
set(ha9, 'ylim', [0 FRMax4*1.25])
line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
%% plot trigger raster

SpkMat = PSTHOut.Trigger{3};
tSpkMat = PSTHOut.Trigger{4};
EvenTimes = PSTHOut.Trigger{5};
ntrial1 = size(SpkMat, 2);

% EvenTimes = PSTHOut.CorrectRelease{5}{1};
yshift = yshift + 2.2;
ha =  axes('unit', 'centimeters', 'position', [13.5 yshift 6 ntrial1*rasterheight],...
    'nextplot', 'add','xtick', [],...
    'xlim',[-params_trigger.pre params_trigger.post], 'ylim', [-ntrial1 1], 'box', 'on');
k =0;
for i =1:size(SpkMat, 2)
    xx = tSpkMat(find(SpkMat(:, i)));
    yy = [0 1]-k;
    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        k = k+1;
    end;
    % port time
    itreward = EvenTimes(i);
    i_portin = t_portin-itreward;
    i_portin = i_portin(i_portin>=-params_reward.pre & i_portin<= params_reward.post);
    if ~isempty(i_portin)
        plot(i_portin, 0.4-k, 'o', 'color', 'r', 'markersize', 2,'markerfacecolor', 'r', 'linewidth', 0.5)
    end
end;

line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
title('Trigger')

FRMax = max([FRMax1 FRMax2 FRMax3 FRMax4]);
xlim = max(get(gca, 'xlim'));

FRrange = [0 FRMax*1.25];
set(ha1, 'ylim', FRrange);
line(ha1, [0 0], FRrange, 'color', 'c', 'linewidth', 1)
set(ha1b, 'ylim', FRrange);
line(ha1b, [0 0], FRrange, 'color', 'c', 'linewidth', 1)
set(ha4, 'ylim', FRrange);
line(ha4, [0 0], FRrange, 'color', 'c', 'linewidth', 1)
set(ha4b, 'ylim', FRrange);
line(ha4b, [0 0], FRrange, 'color', 'c', 'linewidth', 1)
set(ha7, 'ylim', FRrange);
line(ha7, [0 0], FRrange, 'color', 'c', 'linewidth', 1)
 set(ha9, 'ylim', FRrange);
line(ha9, [0 0], FRrange, 'color', 'c', 'linewidth', 1)

FPline.YData = FRrange;

%% plot pre-press activity vs trial num or time
yshift = yshift + ntrial1*rasterheight + 1.5;
ha10=axes('unit', 'centimeters', 'position', [13.5 yshift 6 1.5], 'nextplot', 'add',  'xlim', [min(t_presses/1000) max(t_presses/1000)])

% [psth_pressall,~, trialspxmat_pressall, tspkmat_pressall, t_presses] = jpsth(r.Units.SpikeTimes(ku).timings,  t_presses, params_press);
 
ind_prepress = find(tspkmat_pressall<0);
spkmat_prepress = trialspxmat_pressall(ind_prepress, :);
dur_prepress = abs(tspkmat_pressall(ind_prepress(1)))/1000;

rate_prepress = sum(spkmat_prepress, 1)/dur_prepress; % spk rate across time
plot(ha10, t_presses/1000, rate_prepress, 'k', 'marker', 'o', 'markersize', 3, 'linestyle', 'none');

% linear regression

Pfit = polyfit(t_presses/1000,rate_prepress,1);
yfit = Pfit(1)*t_presses/1000+Pfit(2);
plot(t_presses/1000,yfit,'r:', 'linewidth', 1.5);

xlabel('Time in session (s)')
ylabel('Spk rate (Hz)')

%% plot spike waveform
thiscolor = [0 0 0];
Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
ha0=axes('unit', 'centimeters', 'position', [yfirstcolumn 3 1.5], 'nextplot', 'add', 'xlim', [0 Lspk]);

set(ha0, 'nextplot', 'add')
allwaves = r.Units.SpikeTimes(ku).wave;

if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=[1:size(allwaves, 1)];
end;

wave2plot = allwaves(nplot, :);

plot([1:Lspk], wave2plot, 'color', [0.8 .8 0.8]);
plot([1:Lspk], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)

axis tight
axis([0 Lspk min(mean(allwaves, 1))*2 max(mean(allwaves, 1))*2])
set (gca, 'ylim', [min(mean(allwaves, 1))*2 max(mean(allwaves, 1))*2])


line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
axis off

switch r.Units.SpikeNotes(ku, 3)
    case 1
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1)) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU']);
    case 2
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1))  ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU']);
    otherwise
end

% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);

kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;

[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;

ha00= axes('unit', 'centimeters', 'position', [yfirstcolumn(1)+3.8 yfirstcolumn(2)+0.5 2.5 2], 'nextplot', 'add', 'xlim', [-100 100]);
if median(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', [-100:50:100], 'ytick', [0 median(c)]);
else
    set(ha00, 'nextplot', 'add', 'xtick', [-100:50:100], 'ytick', [0 1], 'ylim', [0 1]);
end;

hbar = bar(lags, c, 1);
set(hbar, 'facecolor', 'k')

xlabel('Lag(ms)')

ch = r.Units.SpikeNotes(ind, 1);
unit_no = r.Units.SpikeNotes(ind, 2);

uicontrol('style', 'text', 'units', 'centimeters', 'position', [ycolumn2(1) ycolumn2(2)+1.4 4 0.5],...
    'string', ([r.Meta(1).Subject]), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

uicontrol('style', 'text', 'units', 'centimeters', 'position', [ycolumn2(1) ycolumn2(2)+0.7 4 0.5],...
    'string', ([r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

uicontrol('style', 'text', 'units', 'centimeters', 'position', [ycolumn2(1) ycolumn2(2) 4 0.5],...
    'string', (['Unit#' num2str(ind) '(' electrode_type num2str(ch) ')']), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')
%  

% change the height of the figure

FinalHeight = ycolumn2(2)+4; 
set(27, 'position', [2 2 20 FinalHeight] )
toc;

% save to a folder

tic
thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end
tosavename2= fullfile(thisFolder, [electrode_type num2str(ch) '_Unit' num2str(unit_no)  printname]);
% print (gcf,'-dpdf', tosavename2)
print (gcf,'-dpng', tosavename2)
% save(tosavename2, 'PSTHOut')
%  
toc