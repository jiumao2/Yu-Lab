function PSTHOut = KornblumSpikes(r, ind, varargin)
% revised 2022.10.7

% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port. 
% V5: add poke events following an unsuccesful release
% SRTSpikesTimeProduction: Kornblum style

% 8.9.2020
% sort out spikes trains according to reaction time

% 5/9/2023 
% Major revision. 

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% KornblumSpikes(r, [1, 1])
% KornblumSpikes(r, 1)
set_matlab_default;
takeall = 0;
if isempty(ind)
    ind =  (1:length(r.Units.SpikeTimes));
    takeall =1;
else
    if length(ind) ==2
        ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
        ind = ind_unit;
    end
end
ku_all = ind;
tic

ComputeRange = [];  % this is the range where time is extracted. Event times outside of this range will be discarded. Empty means taking everything
PressTimeDomain = [2500 2500]; % default
ReleaseTimeDomain = [1500 1000];
RewardTimeDomain = [2000 2000];
TriggerTimeDomain = [1000 2000];
reward_col = [237, 43, 42]/255;
electrode_type = 'Ch';
rasterheight = 0.02;
combine_cue_uncue = 0;
ToSave = true;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ComputeRange'
                ComputeRange = varargin{i+1};
            case 'CombineCueUncue'
                combine_cue_uncue = varargin{i+1};
            case 'ToSave'
                ToSave = varargin{i+1}; 
            otherwise
                errordlg('unknown argument')
        end
    end
end

if ~isempty(ComputeRange)
    if max(ComputeRange)<10000
        ComputeRange = ComputeRange*1000;
    end
end

rb = r.Behavior;
% index of Cued and Uncued trials
ind_cue              =          find(rb.CueIndex(:, 2) == 1);
ind_uncue          =          find(rb.CueIndex(:, 2) == 0);
FP_Kornblum     =           mode(r.Behavior.Foreperiods); % this is the FP

% Presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);

% press for cue and uncue trials
t_presses_cue           =       t_presses(ind_cue);
t_presses_uncue       =       t_presses(ind_uncue);
t_presses_dark         =        t_presses(isnan(rb.CueIndex(:, 2)));
sprintf('There are %2.0f cued trials', length(t_presses_cue))
sprintf('There are %2.0f uncued trials', length(t_presses_uncue))
 
% figure();
% ha=subplot(1, 2, 1);
% set(ha, 'nextplot', 'add', 'xlim', [0.5 3.5], 'xtick', [1:3], 'xticklabel', {'Cued', 'Uncued', 'Dark'});
% bar(1, length(t_presses_cue), 'FaceColor', 'k')
% bar(2, length(t_presses_uncue), 'FaceColor', 'b')
% bar(3, length(t_presses_dark), 'FaceColor', [0.7 0.7 0.7])
% ylabel('Number of presses')
% ymax =max(get(ha, 'ylim'));

% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 % press for cue and uncue trials
t_releases_cue           =       t_releases(ind_cue);
t_releases_uncue       =       t_releases(ind_uncue);
t_releases_dark         =        t_releases(isnan(rb.CueIndex(:, 2)));

% time of all reward delievery
ind_rewards              = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards                  = rb.EventTimings(rb.EventMarkers == ind_rewards);
t_rewards_cue          = [];
t_rewards_uncue      = [];
move_time_cue         = [];
move_time_uncue     = [];

% check which reward is produced by cue vs uncue trials
for i =1:length(t_rewards)
    most_recent_cue = t_releases_cue(find(t_releases_cue-t_rewards(i)<0, 1, 'last'));
    most_recent_uncue = t_releases_uncue(find(t_releases_uncue-t_rewards(i)<0, 1, 'last'));
    if ~isempty(most_recent_cue) && ~isempty(most_recent_uncue)
        if most_recent_cue > most_recent_uncue
            t_rewards_cue = [t_rewards_cue t_rewards(i)];
            move_time_cue = [move_time_cue t_rewards(i)-most_recent_cue];
        else
            t_rewards_uncue = [t_rewards_uncue t_rewards(i)];
            move_time_uncue = [move_time_uncue t_rewards(i)-most_recent_uncue];
        end;
    end;
end;

[move_time_cue, ind_move_cue] = sort(move_time_cue);
t_rewards_cue = t_rewards_cue(ind_move_cue);

[move_time_uncue, ind_move_uncue] = sort(move_time_uncue);
t_rewards_uncue = t_rewards_uncue(ind_move_uncue);

% ha2=subplot(1, 2, 2);
% set(ha2, 'nextplot', 'add', 'xlim', [0.5 2.5], 'xtick', [1:3], 'xticklabel', {'Cued', 'Uncued'}, 'ylim', [0 ymax]);
% bar(1, length(t_rewards_cue), 'FaceColor', 'k')
% bar(2, length(t_rewards_uncue), 'FaceColor', 'b')
% ylabel('Number of rewards')

% index and time of correct presses
if size(rb.Foreperiods, 1)==1
    diff_FP = [0 (diff(rb.Foreperiods)==0)];
else
    diff_FP = [0; (diff(rb.Foreperiods)==0)];
end;

ind_advanced = find(diff_FP & rb.Foreperiods==FP_Kornblum); % advanced stage. We only analyze those
ind_correct_cue                   =           intersect(ind_advanced, intersect(rb.CorrectIndex, ind_cue));
ind_correct_uncue               =           intersect(ind_advanced, intersect(rb.CorrectIndex, ind_uncue));
t_correct_presses_cue        =           t_presses(ind_correct_cue);
t_correct_presses_uncue    =           t_presses(ind_correct_uncue);
t_correct_releases_cue        =          t_releases(ind_correct_cue);
t_correct_releases_uncue    =          t_releases(ind_correct_uncue); 
rt_correct_cue                      =           t_correct_releases_cue - t_correct_presses_cue - FP_Kornblum;
rt_correct_uncue                  =           t_correct_releases_uncue - t_correct_presses_uncue - FP_Kornblum;

% sorting index
[rt_correct_cue, sortindex_cue] = sort(rt_correct_cue);
[rt_correct_uncue, sortindex_uncue] = sort(rt_correct_uncue);

t_correct_presses_cue = t_correct_presses_cue(sortindex_cue);
t_correct_presses_uncue = t_correct_presses_uncue(sortindex_uncue);
t_correct_releases_cue = t_correct_releases_cue(sortindex_cue);
t_correct_releases_uncue = t_correct_releases_uncue(sortindex_uncue);
t_correct_releases = [t_correct_releases_cue; t_correct_releases_uncue];

% Premature
t_premature_presses_cue     = [];
t_premature_presses_uncue = [];
t_premature_releases_cue     = [];
t_premature_releases_uncue = [];
ind_premature_cue             =           intersect(ind_advanced, intersect(rb.PrematureIndex, ind_cue));
ind_premature_uncue         =           intersect(ind_advanced, intersect(rb.PrematureIndex, ind_uncue));
t_premature_presses_cue           =       t_presses(ind_premature_cue);
t_premature_presses_uncue       =       t_presses(ind_premature_uncue);
t_premature_releases_cue          =       t_releases(ind_premature_cue);
t_premature_releases_uncue      =       t_releases(ind_premature_uncue);  
pressdur_premature_cue              =    t_premature_releases_cue - t_premature_presses_cue;
pressdur_premature_uncue          =    t_premature_releases_uncue - t_premature_presses_uncue;
[pressdur_premature_cue, ind_premature_cue]                  =    sort(pressdur_premature_cue);
t_premature_presses_cue              =    t_premature_presses_cue(ind_premature_cue);
t_premature_releases_cue             =    t_premature_releases_cue(ind_premature_cue);
[pressdur_premature_uncue, ind_premature_uncue]             =       sort(pressdur_premature_uncue);
t_premature_releases_uncue        =       t_premature_releases_uncue(ind_premature_uncue);
t_premature_presses_uncue         =       t_premature_presses_uncue(ind_premature_uncue);

% Late
t_late_presses_cue     = [];
t_late_presses_uncue = [];
t_late_releases_cue     = [];
t_late_releases_uncue = [];
ind_late_cue                      =       intersect(ind_advanced, intersect(rb.LateIndex, ind_cue));
ind_late_uncue                  =       intersect(ind_advanced, intersect(rb.LateIndex, ind_uncue));
t_late_presses_cue           =       t_presses(ind_late_cue);
t_late_presses_uncue       =       t_presses(ind_late_uncue);
t_late_releases_cue          =       t_releases(ind_late_cue);
t_late_releases_uncue      =       t_releases(ind_late_uncue);  
pressdur_late_cue              =    t_late_releases_cue - t_late_presses_cue;
pressdur_late_uncue          =    t_late_releases_uncue - t_late_presses_uncue;
[pressdur_late_cue, ind_late_cue]                  =    sort(pressdur_late_cue);
t_late_presses_cue              =    t_late_presses_cue(ind_late_cue);
t_late_releases_cue             =    t_late_releases_cue(ind_late_cue);
[pressdur_late_uncue, ind_late_uncue]             =       sort(pressdur_late_uncue);
t_late_releases_uncue        =       t_late_releases_uncue(ind_late_uncue);
t_late_presses_uncue         =       t_late_presses_uncue(ind_late_uncue);

% Trigger
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);
% solve these
triggers_types = cell(1, length(t_triggers));
triggers_RTs   = NaN*ones(1, length(t_triggers)); 
dt=[];

for i = 1:length(t_triggers)    
    it_trigger = t_triggers(i); % time of this trigger    
    % find the most recent press
    ind_recent_press = find(t_presses<it_trigger, 1, 'last'); % this is the most recent press, and we know the outcome
    this_outcome = r.Behavior.Outcome{ind_recent_press};     
    triggers_types{i} = this_outcome;
    triggers_RTs(i) = t_releases(ind_recent_press) - t_presses(ind_recent_press) - FP_Kornblum;
    disp(['trigger # ' num2str(i) ':' this_outcome ' | ' 'rt (ms): ' num2str(triggers_RTs(i))])
end; 

[triggers_RTs, ind_sort] = sort(triggers_RTs);
t_triggers = t_triggers(ind_sort);
triggers_types = triggers_types(ind_sort);
  
% Port access (pokes), t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'ValveOnset'));
t_portin = rb.EventTimings(rb.EventMarkers == ind_portin); % these are all the poke times

% figure();
% subplot(2, 1, 1)
% plot(t_portin, 5, 'ko');
% text(400, 4.9, 'Poke', 'color', 'k')
% hold on
% line([t_correct_releases_cue t_correct_releases_cue], [4 6], 'color', 'b');
% line([t_correct_releases_uncue t_correct_releases_uncue], [4 6], 'color', 'm');
% text(400, 5.9, 'release', 'color', 'k')
% line([t_rewards_cue' t_rewards_cue'], [4.5 5.5], 'color', 'b', 'linewidth', 1);
% line([t_rewards_uncue' t_rewards_uncue'], [4.5 5.5], 'color', 'm', 'linewidth', 1);
% text(400, 5.4, 'reward', 'color', 'k')

% Find out reward poke (which must occur after a succesful release. For most bpod protocols, this is the same as valve time)
t_reward_pokes_uncue = zeros(1, length(t_rewards_uncue));
for i =1:length(t_reward_pokes_uncue)
    t_portin_this = t_portin(t_portin >t_rewards_uncue(i)-1000 & t_portin<t_rewards_uncue(i)+100);
    if ~isempty(t_portin_this)
        t_reward_pokes_uncue(i) = t_portin_this(1);
        dt = [dt t_reward_pokes_uncue(i)-t_rewards_uncue(i)];
    else
        t_reward_pokes_uncue(i) = NaN;
    end   
end

% Find out reward poke (which must occur after a succesful release)
t_reward_pokes_cue = zeros(1, length(t_rewards_cue));
for i =1:length(t_reward_pokes_cue)
    t_portin_this = t_portin(t_portin >t_rewards_cue(i)-1000 & t_portin<t_rewards_cue(i)+100);
    if ~isempty(t_portin_this)
        t_reward_pokes_cue(i) = t_portin_this(1);
        dt = [dt t_reward_pokes_cue(i)-t_rewards_cue(i)];
    else
        t_reward_pokes_cue(i) = NaN;
    end
end;
  
% subplot(2, 1, 2)
t_lim = [-500 500];
% set(gca, 'xlim', t_lim, 'ylim', [0 length(t_rewards)], 'nextplot', 'add');
for i =1:length(t_rewards_cue)
    t_relative = t_portin - t_rewards_cue(i);
    t_relative = t_relative(t_relative>t_lim(1) & t_relative<t_lim(2));
    [~, ind] = min(abs(t_rewards_cue(i)-t_reward_pokes_cue));
%     if ~isempty(t_relative)
%         scatter(t_relative, i, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
%     end
%     plot(t_reward_pokes_cue(ind) - t_rewards_cue(i), i, '+', 'markersize', 4, 'linewidth', 1, 'color', 'b')
end

for i =1:length(t_rewards_uncue)
    t_relative = t_portin - t_rewards_uncue(i);
    t_relative = t_relative(t_relative>t_lim(1) & t_relative<t_lim(2));
    [~, ind] = min(abs(t_rewards_uncue(i)-t_reward_pokes_uncue));
    if ~isempty(t_relative)
        scatter(t_relative, i+length(t_rewards_cue), 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
    end
    plot(t_reward_pokes_uncue(ind) - t_rewards_uncue(i), i+length(t_rewards_cue), '+', 'markersize', 4, 'linewidth', 1, 'color', 'm')
end

% Find out unrewarded pokes
% bad (nonrewarded) poke: sometimes, rat will poke even after an unsuccessful response.
% Pick these out and plot them
t_nonreward_pokes = [];
move_time_nonreward = [];
bad_responses = [t_premature_releases_cue;t_premature_releases_uncue;t_late_releases_cue;t_late_releases_uncue]; 
for i =1:length(bad_responses)
    t_ipoke = t_portin(find(t_portin>bad_responses(i), 1, 'first')); % first poke after a bad release    
    t_ipress = t_presses(find(t_presses>bad_responses(i), 1, 'first'));
    if ~isempty(t_ipoke) && ~isempty(t_ipress) && t_ipoke < t_ipress
      t_nonreward_pokes            =    [t_nonreward_pokes t_ipoke];
      move_time_nonreward       =     [move_time_nonreward t_ipoke-bad_responses(i)];
    end
end
[move_time_nonreward, indsort_nonreward_pokes] =  sort(move_time_nonreward);
t_nonreward_pokes = t_nonreward_pokes(indsort_nonreward_pokes);

%% Now check ComputeRange and exclude events that are outside of ComputeRange
% this comes handy when you have a chunk of data following chemo
% inactivation which you probably won't want to include for PSTH
% computation. 

if ~isempty(ComputeRange)
    % check t_presses
    t_presses(t_presses<ComputeRange(1) | t_presses>ComputeRange(2))=[];
    % check t_releases
    t_releases(t_releases<ComputeRange(1) | t_releases>ComputeRange(2))=[];
    % check t_presses cue and t_releases cue
    to_remove = find(t_presses_cue<ComputeRange(1) | t_presses_cue>ComputeRange(2) | t_releases_cue<ComputeRange(1) | t_releases_cue>ComputeRange(2));
    t_presses_cue(to_remove)=[];
    t_releases_cue(to_remove)=[];

    % check t_presses uncue and t_releases uncue
    to_remove = find(t_presses_uncue<ComputeRange(1) | t_presses_uncue>ComputeRange(2) | t_releases_uncue<ComputeRange(1) | t_releases_uncue>ComputeRange(2));
    t_presses_uncue(to_remove)=[];
    t_releases_uncue(to_remove)=[];

    % check correct presses/releases
    % uncue
    to_remove = find(t_correct_presses_uncue<ComputeRange(1) | t_correct_presses_uncue>ComputeRange(2) | t_correct_releases_uncue<ComputeRange(1) | t_correct_releases_uncue>ComputeRange(2));
    t_correct_presses_uncue(to_remove)       =     [];
    t_correct_releases_uncue(to_remove)      =     [];
    rt_correct_uncue(to_remove)                    =     [];
    % cue
    to_remove = find(t_correct_presses_cue<ComputeRange(1) | t_correct_presses_cue>ComputeRange(2) | t_correct_releases_cue<ComputeRange(1) | t_correct_releases_cue>ComputeRange(2));
    t_correct_presses_cue(to_remove)          =      [];
    t_correct_releases_cue(to_remove)         =      [];
    rt_correct_cue(to_remove)                        =      [];

    % check premature presses/releases
    % cue
    to_remove = find(t_premature_presses_cue<ComputeRange(1) | t_premature_presses_cue>ComputeRange(2) | t_premature_releases_cue<ComputeRange(1) | t_premature_releases_cue>ComputeRange(2));
    t_premature_presses_cue(to_remove)          =      [];
    t_premature_releases_cue(to_remove)         =      [];
    pressdur_premature_cue(to_remove)            =      [];

    % uncue
    to_remove = find(t_premature_presses_uncue<ComputeRange(1) | t_premature_presses_uncue>ComputeRange(2) | t_premature_releases_uncue<ComputeRange(1) | t_premature_releases_uncue>ComputeRange(2));
    t_premature_presses_uncue(to_remove)          =      [];
    t_premature_releases_uncue(to_remove)         =      [];
    pressdur_premature_uncue(to_remove)            =      [];

    % check late presses/releases
    % cue
    to_remove = find(t_late_presses_cue<ComputeRange(1) | t_late_presses_cue>ComputeRange(2) | t_late_releases_cue<ComputeRange(1) | t_late_releases_cue>ComputeRange(2));
    t_late_presses_cue(to_remove)          =      [];
    t_late_releases_cue(to_remove)         =      [];
    pressdur_late_cue(to_remove)            =      [];

    % uncue
    to_remove = find(t_late_presses_uncue<ComputeRange(1) | t_late_presses_uncue>ComputeRange(2) | t_late_releases_uncue<ComputeRange(1) | t_late_releases_uncue>ComputeRange(2));
    t_late_presses_uncue(to_remove)          =      [];
    t_late_releases_uncue(to_remove)         =      [];
    pressdur_late_uncue(to_remove)            =      [];

    % trigger
    to_remove =  find(t_triggers<ComputeRange(1) | t_triggers>ComputeRange(2) | t_triggers<ComputeRange(1) | t_triggers>ComputeRange(2));
    t_triggers(to_remove) = [];
    triggers_RTs(to_remove) =[];
    triggers_types(to_remove) = [];

    % pokes/ t_reward_pokes_uncue
    to_remove =  find(t_reward_pokes_uncue<ComputeRange(1) | t_reward_pokes_uncue>ComputeRange(2));
    t_reward_pokes_uncue(to_remove) = [];
    move_time_uncue(to_remove) = [];

    to_remove =  find(t_reward_pokes_cue<ComputeRange(1) | t_reward_pokes_cue>ComputeRange(2));
    t_reward_pokes_cue(to_remove) = [];
    move_time_cue(to_remove) = [];


    to_remove =  find(t_nonreward_pokes<ComputeRange(1) | t_nonreward_pokes>ComputeRange(2));
    t_nonreward_pokes(to_remove) = [];
    move_time_nonreward(to_remove) = [];

    to_remove =  find(t_portin<ComputeRange(1) | t_portin>ComputeRange(2) | t_portin<ComputeRange(1) | t_portin>ComputeRange(2));
    t_portin(to_remove) = [];
end
%% Summarize
PSTHOut.ANM_Session                               =     {r.BehaviorClass.Subject, r.BehaviorClass.Date};
PSTHOut.Presses.TimeLabels                      =     {'All', 'CorrectCue', 'PrematureCue', 'LateCue', 'CorrectUncue', 'PrematureUncue', 'LateUncue'};
PSTHOut.Presses.Time                                =     {t_presses, t_correct_presses_cue, t_premature_presses_cue, t_late_presses_cue, t_correct_presses_uncue, t_premature_presses_uncue, t_late_presses_uncue};
PSTHOut.Presses.FP                                    =     FP_Kornblum;
PSTHOut.Presses.RTLabels                         =     {'RTCorrectCue', 'RTCorrectUncue'};
PSTHOut.Presses.RT_Correct                      =     {rt_correct_cue, rt_correct_uncue};
PSTHOut.Presses.PressDurLabels               =     {'Cue', 'Uncue'};
PSTHOut.Presses.PressDur.Premature        =     {pressdur_premature_cue, pressdur_premature_uncue};
PSTHOut.Presses.PressDur.Late                  =     {pressdur_late_cue, pressdur_late_uncue};

PSTHOut.Releases.TimeLabels                     =     {'All', 'CorrectCue', 'PrematureCue', 'LateCue', 'CorrectUncue', 'PrematureUncue', 'LateUncue'};
PSTHOut.Releases.Time                                =     {t_releases, t_correct_releases_cue, t_premature_releases_cue, t_late_releases_cue,  t_correct_releases_uncue, t_premature_releases_uncue, t_late_releases_uncue};
PSTHOut.Releases.FP                                    =    FP_Kornblum;
PSTHOut.Releases.RTLabels                         =     {'RTCorrectCue', 'RTCorrectUncue'};
PSTHOut.Releases.RT_Correct                      =     {rt_correct_cue, rt_correct_uncue};
PSTHOut.Releases.PressDur.Premature        =     {pressdur_premature_cue, pressdur_premature_uncue};
PSTHOut.Releases.PressDur.Late                  =     {pressdur_late_cue, pressdur_late_uncue};

PSTHOut.Pokes.Time                                       =       t_portin;
PSTHOut.Pokes.RewardPoke.Type                  =      {'Cue', 'Uncue'};
PSTHOut.Pokes.RewardPoke.Time                  =      {t_reward_pokes_cue, t_reward_pokes_uncue};
PSTHOut.Pokes.RewardPoke.Move_Time       =      {move_time_cue, move_time_uncue};
PSTHOut.Pokes.NonrewardPoke.Time             =      t_nonreward_pokes;
PSTHOut.Pokes.NonrewardPoke.Move_Time   =      move_time_nonreward;

PSTHOut.Triggers.Labels                                  =       {'Just trigger time'}; 
PSTHOut.Triggers.Time                                     =       t_triggers;
PSTHOut.Triggers.RT                                        =       triggers_RTs;
PSTHOut.Triggers.FP                                         =      FP_Kornblum;
PSTHOut.Triggers.Outcome                              =       triggers_types;
PSTHOut.SpikeNotes                                       =      r.Units.SpikeNotes;

%% Let's build PSTHs
%% Check how many units we need to compute
% derive PSTH from these
% go through each units if necessary
for iku =1:length(ku_all)
    ku = ku_all(iku);
    if ku>length(r.Units.SpikeTimes)
        disp('##########################################')
        display('########### That is all you have ##############')
        display('##########################################')
        return
    end;

    display('##########################################')
    display(['Computing this unit: ' num2str(ku)])
    display('##########################################')

    PSTHOut.PSTH(iku)       = Spikes.Timing.ComputePlotPSTH(r, PSTHOut, ku,...
        'CombineCueUncue', combine_cue_uncue,...
        'PressTimeDomain', PressTimeDomain, ...
        'ReleaseTimeDomain', ReleaseTimeDomain, ...
        'RewardTimeDomain', RewardTimeDomain,...
        'TriggerTimeDomain', TriggerTimeDomain,...
        'ToSave', ToSave);

end;

if takeall
    r.PSTHs  = PSTHOut;
    r_name = Spikes.r_name;
    save(r_name, 'r');
    psth_new_name             =      ['PSTHs_' r.Meta(1).Subject, '_', datestr(r.Meta(1).DateTime,'yyyymmdd'), '.mat'];
    save(psth_new_name, 'PSTHOut');

    % C:\Users\jiani\OneDrive\00_Work\03_Projects\05_Physiology\PSTHs
    try
        thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'PETHs', anm_name);
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder);
        end;
        copyfile(psth_new_name, thisFolder);
    end
end;











