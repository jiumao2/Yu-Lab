function PSTHOut = KornblumSpikesPopulation(r, ComputeTimeRange)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port.
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 11/27/2022 JY
% modified for Kornblum spikes

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

%  r.Behavior.Labels
%     {'TBD1'}    {'TBD2'}    {'LeverPress'}    {'Trigger'}
%     {'LeverRelease'}    {'GoodPress'}    {'GoodRelease'}
%     {'ValveOnset'}    {'ValveOffset'}    {'PokeOnset'}
%     {'PokeOffset'}

if nargin<2
    compute_range = [];
else
    compute_range = ComputeTimeRange*1000;
end;

%% Extract basic information

tic
 
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
[rt_correct_cue_sorted, sortindex_cue] = sort(rt_correct_cue);
[rt_correct_uncue_sorted, sortindex_uncue] = sort(rt_correct_uncue);

t_correctpresses_cue = t_correctpresses_cue(sortindex_cue);
t_correctpresses_uncue = t_correctpresses_uncue(sortindex_uncue);

t_correctreleases_cue = t_correctreleases_cue(sortindex_cue);
t_correctreleases_uncue = t_correctreleases_uncue(sortindex_uncue);

% time of all triggers
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

% remove 'trigger' times in uncued trials (these are not really trigger
% signal, they occured after a successful uncued release)

t_triggers = removeFromUncue(t_triggers, t_correctreleases_uncue);

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

[~, indmovesort_cue]            =    sort(movetime_cue);
[~, indmovesort_uncue]        =    sort(movetime_uncue);
                            
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

[~, ind_premature_cue] = sort(pressdur_premature_cue);
t_prematurepresses_cue = t_prematurepresses_cue(ind_premature_cue);
t_prematurereleases_cue = t_prematurereleases_cue(ind_premature_cue);

[~, ind_premature_uncue] = sort(pressdur_premature_uncue);
t_prematurepresses_uncue = t_prematurepresses_uncue(ind_premature_uncue);
t_prematurereleases_uncue = t_prematurereleases_uncue(ind_premature_uncue);

% time of late presses
t_latepresses_cue               =       t_presses(intersect(rb.LateIndex, ind_cue));
t_latepresses_uncue           =      t_presses(intersect(rb.LateIndex, ind_uncue));

t_latereleases_cue              =        t_releases(intersect(rb.LateIndex, ind_cue));
t_latereleases_uncue          =      t_releases(intersect(rb.LateIndex, ind_uncue));

pressdur_late_cue              =    t_latereleases_cue - t_latepresses_cue;
pressdur_late_uncue          =    t_latereleases_uncue - t_latepresses_uncue;

[~, ind_late_cue] = sort(pressdur_late_cue);

t_latepresses_cue = t_latepresses_cue(ind_late_cue);
t_latereleases_cue = t_latereleases_cue(ind_late_cue);

[~, ind_late_uncue] = sort(pressdur_late_uncue);
t_latepresses_uncue = t_latepresses_uncue(ind_late_uncue);
t_latereleases_uncue = t_latereleases_uncue(ind_late_uncue);


%% Compute these activities

% Extract these event-related activity

Units = r.Units.SpikeNotes;
all_inds =  [1:size(r.Units.SpikeNotes, 1)]; % these are all units collected from this session


% Press
PSTH_PressTypes          =           {'Cued', 'Uncued'};
PSTH_Press                    =           cell(1, length(PSTH_PressTypes)); % one for cued trials, one for uncued trials
PSTH_PressZ                  =           cell(1, length(PSTH_PressTypes)); % one for short FP, one for long FP 
PSTH_PressStat              =          cell(1,  length(PSTH_PressTypes)); % this includes the statistics of press
 
PSTH_PressMerged                 =          []; % merge cued and uncued FPs
PSTH_PressMergedZ               =          []; % 
PSTH_PressMergedStat           =          [];

PSTH_Release                =          cell(1,  length(PSTH_PressTypes)); 
PSTH_ReleaseZ              =          cell(1, length(PSTH_PressTypes));
PSTH_ReleaseStat          =          cell(1, length(PSTH_PressTypes)); % this gives the statistics of release

PSTH_ReleaseMerged            =           []; % merge short and long FPs
PSTH_ReleaseMergedZ          =           []; % one for short FP, one for long FP 
PSTH_ReleaseMergedStat      =           [];

PSTH_Reward                 =          cell(1,  length(PSTH_PressTypes)); 
PSTH_RewardZ              =          cell(1, length(PSTH_PressTypes));
PSTH_RewardStat          =          cell(1, length(PSTH_PressTypes)); % this gives the statistics of release

PSTH_RewardMerged                 =            []; 
PSTH_RewardMergedZ               =            []; 
PSTH_RewardMergedStat           =            [];  % this gives the statistics of release

PSTH_Trigger             =               [];  % Only cued trials have trigger signal
PSTH_TriggerZ             =             [];
PSTH_TriggerStat       =              []; % this gives the statistics of trigger

% check if we need to exclude some data
if ~isempty(compute_range)

    t_presses                       =    t_presses(t_presses>=compute_range(1) & t_presses<=compute_range(2));
    t_correctpresses_cue    =    t_correctpresses_cue(t_correctpresses_cue>=compute_range(1) & t_correctpresses_cue<=compute_range(2));
    t_correctpresses_uncue    =    t_correctpresses_uncue(t_correctpresses_uncue>=compute_range(1) & t_correctpresses_uncue<=compute_range(2));

    t_correctreleases_cue   =    t_correctreleases_cue(t_correctreleases_cue>=compute_range(1) & t_correctreleases_cue<=compute_range(2));
    t_correctreleases_uncue    =    t_correctreleases_uncue(t_correctreleases_uncue>=compute_range(1) & t_correctreleases_uncue<=compute_range(2));

    t_prematurepresses_cue   =    t_prematurepresses_cue(t_prematurepresses_cue>=compute_range(1) & t_prematurepresses_cue<=compute_range(2));
    t_prematurepresses_uncue    =    t_prematurepresses_uncue(t_prematurepresses_uncue>=compute_range(1) & t_prematurepresses_uncue<=compute_range(2));

    t_prematurereleases_cue   =    t_prematurereleases_cue(t_prematurereleases_cue>=compute_range(1) & t_prematurereleases_cue<=compute_range(2));
    t_prematurereleases_uncue    =    t_prematurereleases_uncue(t_prematurereleases_uncue>=compute_range(1) & t_prematurereleases_uncue<=compute_range(2));

    t_latepresses_cue   =    t_latepresses_cue(t_latepresses_cue>=compute_range(1) & t_latepresses_cue<=compute_range(2));
    t_latepresses_uncue    =    t_latepresses_uncue(t_latepresses_uncue>=compute_range(1) & t_latepresses_uncue<=compute_range(2));

    t_latereleases_cue   =    t_latereleases_cue(t_latereleases_cue>=compute_range(1) & t_latereleases_cue<=compute_range(2));
    t_latereleases_uncue    =    t_latereleases_uncue(t_latereleases_uncue>=compute_range(1) & t_latereleases_uncue<=compute_range(2));

    t_rewards_cue   =    t_rewards_cue(t_rewards_cue>=compute_range(1) & t_rewards_cue<=compute_range(2));
    t_rewards_uncue    =    t_rewards_uncue(t_rewards_uncue>=compute_range(1) & t_rewards_uncue<=compute_range(2));

    t_triggers_correct   =    t_triggers_correct(t_triggers_correct>=compute_range(1) & t_triggers_correct<=compute_range(2));
    t_triggers_late    =    t_triggers_late(t_triggers_late>=compute_range(1) & t_triggers_late<=compute_range(2));

end;

for i = 1:length(all_inds)
    % derive PSTH from these    
    psth_i = [];
    tpsth_i = [];
    psth_correctpress_cue = [];
    psth_correctpress_uncue = [];
    psth_correctrelease_cue = [];
    psth_correctrelease_uncue = [];

    % these variables hold spike trains    
    SpikeMat = [];
    tSpikeMat = [];

    ku = all_inds(i);
    params.pre = 2000;
    params.post = 3000;
    params.binwidth = 20;
    
    %% Press and Release PSTH
    % extract PSTH from all correct presses (both cue and uncue trials are included)
    [psth_correctpressall, tspressall, trialspxmatpressall, tspkmatpressall] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses, params);
    psth_correctpressall = smoothdata (psth_correctpressall, 'gaussian', 15);

    if isempty(PSTH_PressMerged)
        PSTH_PressMerged = tspressall; % The first row is time
        PSTH_PressMergedZ = tspressall; % The first row is time
    end;

    PSTH_PressMerged                            =           [PSTH_PressMerged; psth_correctpressall];
    StatOut                                                 =           ExamineTaskResponsive(tspkmatpressall, trialspxmatpressall);
    StatOut.CellIndx                                   =           Units(i, :);
    PSTH_PressMergedStat.StatOut(i)     =           StatOut;


    psth_i = [psth_i psth_correctpressall];

    % extract PSTH from all correct releases
    [psth_correctreleaseall, tsreleaseall, trialspxmatreleaseall, tspkmatreleaseall] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctreleases, params);
    psth_correctreleaseall = smoothdata (psth_correctreleaseall, 'gaussian', 15);

    if isempty(PSTH_ReleaseMerged)
        PSTH_ReleaseMerged = tsreleaseall; % The first row is time
        PSTH_ReleaseMergedZ = tsreleaseall; % The first row is time
    end;

    PSTH_ReleaseMerged                         =          [PSTH_ReleaseMerged; psth_correctreleaseall];
    StatOut                                                 =           ExamineTaskResponsive(tspkmatreleaseall, trialspxmatreleaseall);
    StatOut.CellIndx                                   =           Units(i, :);
    PSTH_ReleaseMergedStat.StatOut(i)   =         StatOut;

    % extract PSTH from correct "cue" responses (press)
    [psth_correctpress, ts, trialspxmatpress, tspkmatpress] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses_cue, params);
    psth_correctpress = smoothdata (psth_correctpress, 'gaussian', 15);    
     if isempty(PSTH_Press{1})
        PSTH_Press{1} =  ts; % The first row is time 
        PSTH_PressZ{1} =  ts; % The first row is time         
    end;    
    PSTH_Press{1}                    =            [PSTH_Press{1}; psth_correctpress];
    StatOut                                 =            ExamineTaskResponsive(tspkmatpress,trialspxmatpress);
    StatOut.CellIndx                   =            Units(i, :);
    PSTH_PressStat{1}.StatOut(i) =  StatOut;
    psth_correctpress_cue = psth_correctpress;

    % extract PSTH from correct "uncue" responses (press)
    [psth_correctpress, ts, trialspxmatpress, tspkmatpress] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses_uncue, params);
    psth_correctpress = smoothdata (psth_correctpress, 'gaussian', 15);    
     if isempty(PSTH_Press{2})
        PSTH_Press{2} =  ts; % The first row is time 
        PSTH_PressZ{2} =  ts; % The first row is time
      end;
      PSTH_Press{2}                   =            [PSTH_Press{2}; psth_correctpress];
      StatOut                                =            ExamineTaskResponsive(tspkmatpress,trialspxmatpress);
      StatOut.CellIndx                  =            Units(i, :);
      PSTH_PressStat{2}.StatOut(i) =  StatOut;
      psth_correctpress_uncue = psth_correctpress;

        % extract PSTH from correct "cue" responses (release)
    [psth_correctrelease, ts, trialspxmarelease, tspkmatrelease] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctreleases_cue, params);
    psth_correctrelease = smoothdata (psth_correctrelease, 'gaussian', 15);    
     if isempty(PSTH_Release{1})
        PSTH_Release{1} =  ts; % The first row is time 
        PSTH_ReleaseZ{1} =  ts; % The first row is time         
    end;    
    PSTH_Release{1}                    =            [PSTH_Release{1}; psth_correctrelease];    
    StatOut                                     =            ExamineTaskResponsive(tspkmatrelease,trialspxmarelease);
    StatOut.CellIndx                       =            Units(i, :);
    PSTH_ReleaseStat{1}.StatOut(i) =            StatOut;
    psth_correctrelease_cue = psth_correctrelease;

    % extract PSTH from correct "uncue" responses (release)
    [psth_correctrelease, ts, trialspxmarelease, tspkmatrelease] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctreleases_uncue, params);
    psth_correctrelease = smoothdata (psth_correctrelease, 'gaussian', 15);
    if isempty(PSTH_Release{2})
        PSTH_Release{2} =  ts; % The first row is time
        PSTH_ReleaseZ{2} =  ts; % The first row is time
    end;
    PSTH_Release{2}                    =            [PSTH_Release{2}; psth_correctrelease];
    StatOut                                     =            ExamineTaskResponsive(tspkmatrelease,trialspxmarelease);
    StatOut.CellIndx                       =            Units(i, :);
    PSTH_ReleaseStat{2}.StatOut(i) =            StatOut;
    psth_correctrelease_uncue = psth_correctrelease;

    %% Trigger PSTH
    % extract trigger PSTH: t_triggers_correct
    params.pre = 500;
    params.post = 1500;    
    [psth_goodtrigger, ts_goodtrigger, trialspxmat_goodtrigger, tspkmat_goodtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_correct, params);
    psth_goodtrigger = smoothdata (psth_goodtrigger, 'gaussian', 15);    
    if isempty(PSTH_Trigger)
        PSTH_Trigger(1, :) = ts_goodtrigger;
        PSTH_TriggerZ(1, :) = ts_goodtrigger;
    end;    
    PSTH_Trigger                        =                 [PSTH_Trigger; psth_goodtrigger];    
    StatOut                                   =                 ExamineTaskResponsive(tspkmat_goodtrigger, trialspxmat_goodtrigger);
    StatOut.CellIndx                     =                 Units(i, :);
    PSTH_TriggerStat.StatOut(i)  =                 StatOut;

    figure(10); clf
    subplot(3, 2, 1)
    plot(PSTH_Press{1}(1, :), PSTH_Press{1}(end, :))
    set(gca, 'xlim', [-2000 2000])
    line([1000 1000], get(gca, 'Ylim'))
    legend('Cue Press')

    subplot(3,2, 3)
    plot(PSTH_Press{2}(1, :), PSTH_Press{2}(end, :))
    set(gca, 'xlim', [-2000 2000])
    line([1000 1000], get(gca, 'Ylim'))
    legend('Uncue Press')

    subplot(3, 2, 2)
    plot(PSTH_Release{1}(1, :), PSTH_Release{1}(end, :))
    set(gca, 'xlim', [-2000 2000])    
    legend('Cue Release')

    subplot(3,2, 4)
    plot(PSTH_Release{2}(1, :), PSTH_Release{2}(end, :))
    set(gca, 'xlim', [-2000 2000])
    legend('Uncue Release')

    subplot(3, 1, 3)
    plot(PSTH_Trigger(1, :), PSTH_Trigger(end, :))
    legend('Trigger')

    pause(0.1)

    %% Reward PSTH
    params.pre = 1000;
    params.post = 2000;
    params.binwidth = 20;
    % Cued
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards_cue, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 15);
    if isempty(PSTH_Reward{1})
        PSTH_Reward{1}(1, :) = ts_rew;
        PSTH_RewardZ{1}(1, :) = ts_rew;
    end;
    PSTH_Reward{1} = [PSTH_Reward{1}; psth_rew];
    StatOut = ExamineTaskResponsive(tspkmat_rew, trialspxmat_rew);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_RewardStat{1}.StatOut(i) =  StatOut;
    psth_rew_cue = psth_rew;

    % Uncued
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards_uncue, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 15);
    if isempty(PSTH_Reward{2})
        PSTH_Reward{2}(1, :) = ts_rew;
        PSTH_RewardZ{2}(1, :) = ts_rew;
    end;
    PSTH_Reward{2} = [PSTH_Reward{2}; psth_rew];
    StatOut = ExamineTaskResponsive(tspkmat_rew, trialspxmat_rew);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_RewardStat{2}.StatOut(i) =  StatOut;
    psth_rew_uncue = psth_rew;

    % Both
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 15);

    if isempty(PSTH_RewardMerged)
        PSTH_RewardMerged(1, :) = ts_rew;
        PSTH_RewardMergedZ(1, :) = ts_rew;
    end;

    PSTH_RewardMerged = [PSTH_RewardMerged; psth_rew];
    StatOut = ExamineTaskResponsive(tspkmat_rew, trialspxmat_rew);
    StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
    PSTH_RewardMergedStat.StatOut(i) =  StatOut;

    psth_i = [psth_i psth_rew];

    mean_psth_i         =        mean(psth_i);
    sd_psth_i              =        std(psth_i);

    % Compute z score

    PSTH_PressZ{1}                  =     [PSTH_PressZ{1}; (psth_correctpress_cue-mean_psth_i)/sd_psth_i];
    PSTH_PressZ{2}                  =     [PSTH_PressZ{2}; (psth_correctpress_uncue-mean_psth_i)/sd_psth_i];
    PSTH_PressMergedZ          =      [PSTH_PressMergedZ; (psth_correctpressall-mean_psth_i)/sd_psth_i];    

    PSTH_ReleaseZ{1}              =     [PSTH_ReleaseZ{1}; (psth_correctrelease_cue-mean_psth_i)/sd_psth_i];
    PSTH_ReleaseZ{2}              =     [PSTH_ReleaseZ{2}; (psth_correctrelease_uncue-mean_psth_i)/sd_psth_i];
    PSTH_ReleaseMergedZ      =     [PSTH_ReleaseMergedZ; (psth_correctreleaseall-mean_psth_i)/sd_psth_i];    

    PSTH_RewardZ{1}                   =     [PSTH_RewardZ{1}; (psth_rew_cue-mean_psth_i)/sd_psth_i];
    PSTH_RewardZ{2}                   =     [PSTH_RewardZ{2}; (psth_rew_uncue-mean_psth_i)/sd_psth_i];
    PSTH_RewardMergedZ           =     [PSTH_RewardMergedZ; (psth_rew-mean_psth_i)/sd_psth_i];

    PSTH_TriggerZ                    =      [PSTH_TriggerZ; (psth_goodtrigger-mean_psth_i)/sd_psth_i];

end;

this_folder          =      pwd;
if ispc
    folder_split          =     split(this_folder, '\');
else
    folder_split          =     split(this_folder, '/');
end;
rat_name            =       folder_split{end-1};
session_name    =       folder_split{end};
r_name               =      ['RTarray_' rat_name, '_', session_name, '.mat'];

PSTHOut.Name                            =        rat_name;
PSTHOut.Session                         =     session_name;
PSTHOut.Date                              =        strrep(r.Meta(1).DateTime(1:11), '-','_');
PSTHOut.Units                             =        Units;
PSTHOut.Press                           =        PSTH_Press;
PSTHOut.PressZ                         =        PSTH_PressZ;
PSTHOut.PressStat                     =        PSTH_PressStat;

PSTHOut.PressMerged            =        PSTH_PressMerged;
PSTHOut.PressMergedZ         =        PSTH_PressMergedZ;
PSTHOut.PressMergedStat      =        PSTH_PressMergedStat;

PSTHOut.Release                     =        PSTH_Release;
PSTHOut.ReleaseZ                   =        PSTH_ReleaseZ;
PSTHOut.ReleaseStat               =        PSTH_ReleaseStat;

PSTHOut.ReleaseMerged          =        PSTH_ReleaseMerged;
PSTHOut.ReleaseMergedZ        =        PSTH_ReleaseMergedZ;
PSTHOut.ReleaseMergedStat    =        PSTH_ReleaseMergedStat;

PSTHOut.Reward                     =        PSTH_Reward;
PSTHOut.RewardZ                   =        PSTH_RewardZ;
PSTHOut.RewardStat               =        PSTH_RewardStat;

PSTHOut.RewardMerged                     =        PSTH_RewardMerged;
PSTHOut.RewardMergedZ                   =        PSTH_RewardMergedZ;
PSTHOut.RewardMergedStat               =        PSTH_RewardMergedStat;

PSTHOut.Trigger                       =        PSTH_Trigger;
PSTHOut.TriggerZ                     =        PSTH_TriggerZ;
PSTHOut.TriggerStat                 =        PSTH_TriggerStat;
PSTHOut.FP                              =        FP_Kornblum;
PSTHOut.NumCued                   =        length(t_presses_cue);
PSTHOut.NumUncued               =        length(t_presses_uncue);

[PSTHOut.IndSort, PSTHOut.IndSignificant] =  SortPSTH(PSTHOut);

r.PopPSTH = PSTHOut;

save(r_name, 'r');
psth_new_name             =      ['PopulationPSTH_' rat_name, '_', session_name, '.mat'];

save(psth_new_name, 'PSTHOut');

Spikes.Timing.VisualizePSTHPopulation(PSTHOut);

%

function t_triggers = removeFromUncue(t_triggers, t_correctreleases_uncue);
badOnes = [];
nearestTriggger = [];

for i =1:length(t_correctreleases_uncue)
    [nearestTrigger, indmin] = min(abs(t_triggers - t_correctreleases_uncue(i)));
    if nearestTrigger<12 % note that time difference between uncue release and trigger is usually 10 ms
        badOnes = [badOnes indmin];
    end;
end;

t_triggers(badOnes) = [];
