function PSTH = ComputePlotPSTHLearning(r, PSTHOut, ku, varargin)

% Jianing Yu 5/8/2023
% For plotting PSTHs under DoubleTone condition.
% Extracted from SRTSpikes and adapted to trigger-type grouping.

% Modified by Yue Huang on 6/26/2023
% Change the way of making raster plots to run faster

% close all;
PSTH.UnitID       = ku;
ToSave = 'on';
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            %             case 'FRrange'
            %                 FRrange = varargin{i+1};
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'RewardTimeDomain'
                RewardTimeDomain = varargin{i+1};
            case 'TriggerTimeDomain'
                TriggerTimeDomain = varargin{i+1};
            case 'ToSave'
                ToSave = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

% For PSTH and raster plots
press_col = [5 191 219]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
full_volume_spike_col = [0.55, 0.20, 0.45];
reward_col = [164, 208, 164]/255;
taskCodes = PSTHOut.TaskTypes.Codes;
taskLabels = PSTHOut.TaskTypes.Labels;
toneTimes = PSTHOut.TaskTypes.ToneTimes;
fixedFP = PSTHOut.TaskTypes.FixedFP;
if isfield(PSTHOut.TaskTypes, 'ConditionFPs')
    conditionFPs = PSTHOut.TaskTypes.ConditionFPs;
else
    conditionFPs = taskCodes;
end
if isfield(PSTHOut.TaskTypes, 'ConditionVolumes')
    conditionVolumes = PSTHOut.TaskTypes.ConditionVolumes;
else
    conditionVolumes = ones(size(taskCodes));
end
nFPs = length(taskCodes);
FP_cols = [0.25 0.25 0.25; 0.16 0.52 0.78; 0.95 0.58 0.22; 0.45 0.33 0.75];
premature_col = [0.9 0.4 0.1];
late_col = [0.6 0.6 0.6];
extra_tone_shade_col = [0.66 0.78 0.92];
extra_tone_alpha = 0.30;
reward_ref_lw = 0.8;
reward_move_lw = 0.8;
printsize = [2 2 35.5 25];

%% PSTHs for press and release
params_press.pre            =             5000; % take a longer pre-press activity so we can compute z score easily later.
params_press.post          =              PressTimeDomain(2);
params_press.binwidth    =              20;

t_presses = PSTHOut.Presses.Time{end};
[psth_presses_all, ts_press_all, trialspxmat_press_all, tspkmat_press_all,  t_correct_presses_all,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_presses_all = smoothdata (psth_presses_all, 'gaussian', 5);
PSTH.PressesAll =  {psth_presses_all, ts_press_all, trialspxmat_press_all, tspkmat_press_all,  t_correct_presses_all};

params_press.pre            =              PressTimeDomain(1);
params_press.post          =              PressTimeDomain(2);
params_press.binwidth    =              20;

psth_presses_correct= [];
ts_press=[];
trialspxmat_press=[];
tspkmat_press=[];


% Press PSTH (corrected, sorted)
for i =1:nFPs
    t_presses_correct{i} = PSTHOut.Presses.Time{i};
    [psth_presses_correct{i}, ts_press{i}, trialspxmat_press{i}, tspkmat_press{i},   t_presses_correct{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_presses_correct{i}, params_press);
    psth_presses_correct{i} = smoothdata (psth_presses_correct{i}, 'gaussian', 5);
    rt_presses_sorted{i}  = PSTHOut.Presses.RT_Correct{i};
    rt_presses_sorted{i}  =  rt_presses_sorted{i}(ind);
    PSTH.Presses{i} =  {psth_presses_correct{i}, ts_press{i}, trialspxmat_press{i},...
        tspkmat_press{i}, t_presses_correct{i}, rt_presses_sorted{i}};
end
PSTH.PressesLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT'};

% Release PSTH
params.pre =  ReleaseTimeDomain(1);
params.post = ReleaseTimeDomain(2);
params.binwidth = 20;

psth_release_correct=[];
ts_release=[];
trialspxmat_release=[];
tspkmat_release=[];

for i =1:nFPs
    t_releases_correct{i} = PSTHOut.Releases.Time{i};
    [psth_release_correct{i}, ts_release{i}, trialspxmat_release{i}, tspkmat_release{i},    t_releases_correct{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_releases_correct{i}, params);
    psth_release_correct{i} = smoothdata (psth_release_correct{i}, 'gaussian', 5);
    rt_releases_sorted{i}  = PSTHOut.Presses.RT_Correct{i};
    rt_releases_sorted{i}  =  rt_releases_sorted{i}(ind);
    PSTH.Releases{i} =  {psth_release_correct{i}, ts_release{i}, trialspxmat_release{i},...
        tspkmat_release{i},  t_releases_correct{i}, rt_releases_sorted{i}};
end
PSTH.ReleassLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT'};


% premature press PSTH
t_premature_presses                 =         PSTHOut.Presses.Time{nFPs+1};
[psth_premature_press, ts_premature_press, trialspxmat_premature_press, tspkmat_premature_press,...
    t_premature_presses, ind]      =           Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_premature_presses, params_press);
psth_premature_press                =             smoothdata (psth_premature_press, 'gaussian', 5);
FPs_premature_presses            =              PSTHOut.Presses.FP{2};
FPs_premature_presses             =             FPs_premature_presses(ind);
premature_duration_presses      =             PSTHOut.Presses.PressDur.Premature;
premature_duration_presses      =             premature_duration_presses(ind);
PSTH.PrematurePresses =  {psth_premature_press, ts_premature_press,...
    trialspxmat_premature_press, tspkmat_premature_press,...
    t_premature_presses, premature_duration_presses, FPs_premature_presses};
PSTH.PrematureLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDuration', 'TaskType'};


% premature release PSTH
t_premature_releases                =         PSTHOut.Releases.Time{nFPs+1};
[psth_premature_release, ts_premature_release, trialspxmat_premature_release, tspkmat_premature_release,...
    t_premature_releases, ind]      =           Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_premature_releases, params);
psth_premature_release              =           smoothdata (psth_premature_release, 'gaussian', 5);
FPs_premature_releases            =              PSTHOut.Releases.FP{2};
FPs_premature_releases             =             FPs_premature_releases(ind);
premature_duration_releases      =             PSTHOut.Releases.PressDur.Premature;
premature_duration_releases      =             premature_duration_releases(ind);
PSTH.PrematureReleases =  {psth_premature_release, ts_premature_release,...
    trialspxmat_premature_release, tspkmat_premature_release,t_premature_releases,...
    premature_duration_releases, FPs_premature_releases};

% late press PSTH
if ~isempty(PSTHOut.Presses.FP{3})
    t_late_presses                 =         PSTHOut.Presses.Time{nFPs+2};
else
    t_late_presses = [];
end
[psth_late_press, ts_late_press, trialspxmat_late_press, tspkmat_late_press,...
    t_late_presses, ind]        =           Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
    t_late_presses, params_press);
psth_late_press                =             smoothdata (psth_late_press, 'gaussian', 5);
FPs_late_presses            =              PSTHOut.Presses.FP{3};
late_duration_presses      =             PSTHOut.Presses.PressDur.Late;

if ~isempty(FPs_late_presses)    
    FPs_late_presses             =             FPs_late_presses(ind);
    late_duration_presses      =             late_duration_presses(ind);
end

PSTH.LatePresses = {psth_late_press, ts_late_press, trialspxmat_late_press,...
    tspkmat_late_press, t_late_presses,late_duration_presses,FPs_late_presses};
PSTH.LateLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDuration', 'TaskType'};

% late release PSTH
if length(PSTHOut.Releases.Time) >= nFPs+2
    t_late_releases                 =         PSTHOut.Releases.Time{nFPs+2};
else
    t_late_releases = [];
end

[psth_late_release, ts_late_release, trialspxmat_late_release, tspkmat_late_release,...
    t_late_releases, ind]       =           Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_late_releases, params);
psth_late_release                =             smoothdata (psth_late_release, 'gaussian', 5);
FPs_late_releases            =              PSTHOut.Releases.FP{3};
FPs_late_releases             =             FPs_late_releases(ind);
late_duration_releases      =             PSTHOut.Releases.PressDur.Late;
late_duration_releases      =             late_duration_releases(ind);
PSTH.LateReleases =  {psth_late_release, ts_late_release, trialspxmat_late_release,...
    tspkmat_late_release, t_late_releases,...
    late_duration_releases, FPs_late_releases};

% use t_reward_poke and move_time to construct reward_poke PSTH
% reward PSTH
params.pre = RewardTimeDomain(1);
params.post = RewardTimeDomain(2);

t_reward_pokes = PSTHOut.Pokes.RewardPoke.Time;
move_time =  PSTHOut.Pokes.RewardPoke.Move_Time;
for i =1:length(t_reward_pokes)
    [psth_reward_pokes{i}, ts_reward_pokes{i}, trialspxmat_reward_pokes{i}, tspkmat_reward_pokes{i},...
        t_reward_pokes{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, t_reward_pokes{i}, params);
    psth_reward_pokes{i} = smoothdata (psth_reward_pokes{i}, 'gaussian', 5);
    move_time{i} = move_time{i}(ind);
    PSTH.RewardPokes{i} =  {psth_reward_pokes{i}, ts_reward_pokes{i}, trialspxmat_reward_pokes{i},...
        tspkmat_reward_pokes{i}, t_reward_pokes{i},move_time{i}};
end
PSTH.PokeLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'MoveTime'};

% bad poke PSTH
t_nonreward_pokes       =           PSTHOut.Pokes.NonrewardPoke.Time;
move_time_nonreward  =           PSTHOut.Pokes.NonrewardPoke.Move_Time;
[psth_nonreward_pokes, ts_nonreward_pokes, trialspxmat_nonreward_pokes, tspkmat_nonreward_pokes,...
    t_nonreward_pokes, ind]              =    Spikes.jpsth(r.Units.SpikeTimes(ku).timings, t_nonreward_pokes, params);
psth_nonreward_pokes                     =     smoothdata (psth_nonreward_pokes, 'gaussian', 5);
move_time_nonreward                      =     move_time_nonreward(ind);
PSTH.NonrewardPokes =  {psth_nonreward_pokes, ts_nonreward_pokes,...
    trialspxmat_nonreward_pokes, tspkmat_nonreward_pokes, t_nonreward_pokes, move_time_nonreward};

% trigger PSTH
params.pre = TriggerTimeDomain(1);
params.post = TriggerTimeDomain(2);

if length(PSTHOut.Triggers.Time) >= nFPs+1
    t_triggers_late = PSTHOut.Triggers.Time{nFPs+1};
    RT_triggers_late = PSTHOut.Triggers.RT{nFPs+1};
    FP_triggers_late = PSTHOut.Triggers.FP{end};
else
    t_triggers_late = [];
    RT_triggers_late = [];
    FP_triggers_late = [];
end

[psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger, tspkmat_late_trigger, t_triggers_late,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_triggers_late, params);
RT_triggers_late = RT_triggers_late(ind);
FP_triggers_late=FP_triggers_late(ind);
psth_late_trigger = smoothdata (psth_late_trigger, 'gaussian', 5);
PSTH.TriggersLate =  {psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger,...
    tspkmat_late_trigger, t_triggers_late, RT_triggers_late, FP_triggers_late};
PSTH.TriggerLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT', 'TaskType'};
for i =1:nFPs
    t_triggers_correct{i} = PSTHOut.Triggers.Time{i};
    RT_triggers_correct{i} = PSTHOut.Triggers.RT{i};
    [psth_trigger_correct{i}, ts_trigger_correct{i}, trialspxmat_trigger_correct{i}, tspkmat_trigger_correct{i}, t_triggers_correct{i},...
        ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_triggers_correct{i}, params);
    RT_triggers_correct{i} = RT_triggers_correct{i}(ind);
    psth_trigger_correct{i} = smoothdata (psth_trigger_correct{i}, 'gaussian', 5);
    PSTH.Triggers{i} =  {psth_trigger_correct{i}, ts_trigger_correct{i}, trialspxmat_trigger_correct{i},...
        tspkmat_trigger_correct{i}, t_triggers_correct{i}, RT_triggers_correct{i}, taskCodes(i)};
end

% extra tone PSTH for learning trials
for i =1:length(PSTHOut.ExtraTone.Time)
    t_extra_tone{i} = PSTHOut.ExtraTone.Time{i};
    RT_extra_tone{i} = PSTHOut.ExtraTone.RT{i};
    FP_extra_tone{i} = PSTHOut.ExtraTone.FP{i};
    volume_extra_tone{i} = PSTHOut.ExtraTone.Volume{i};
    is_test_extra_tone{i} = PSTHOut.ExtraTone.IsTest{i};
    post_learning_extra_tone{i} = PSTHOut.ExtraTone.PostLearning{i};
    outcome_extra_tone{i} = PSTHOut.ExtraTone.Outcome{i};
    press_extra_tone{i} = PSTHOut.ExtraTone.PressTime{i};
    release_extra_tone{i} = PSTHOut.ExtraTone.ReleaseTime{i};
    [psth_extra_tone{i}, ts_extra_tone{i}, trialspxmat_extra_tone{i}, tspkmat_extra_tone{i}, ...
        t_extra_tone{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
        t_extra_tone{i}, params);
    psth_extra_tone{i} = smoothdata(psth_extra_tone{i}, 'gaussian', 5);
    RT_extra_tone{i} = RT_extra_tone{i}(ind);
    FP_extra_tone{i} = FP_extra_tone{i}(ind);
    volume_extra_tone{i} = volume_extra_tone{i}(ind);
    is_test_extra_tone{i} = is_test_extra_tone{i}(ind);
    post_learning_extra_tone{i} = post_learning_extra_tone{i}(ind);
    outcome_extra_tone{i} = outcome_extra_tone{i}(ind);
    press_extra_tone{i} = press_extra_tone{i}(ind);
    release_extra_tone{i} = release_extra_tone{i}(ind);
    PSTH.ExtraTone{i} = {psth_extra_tone{i}, ts_extra_tone{i}, trialspxmat_extra_tone{i}, ...
        tspkmat_extra_tone{i}, t_extra_tone{i}, RT_extra_tone{i}, FP_extra_tone{i}, ...
        volume_extra_tone{i}, is_test_extra_tone{i}, post_learning_extra_tone{i}, outcome_extra_tone{i}};
end
PSTH.ExtraToneLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', ...
    'RT', 'FP', 'Volume', 'IsTest', 'PostLearning', 'Outcome'};

trialInfo = PSTHOut.Learning.TrialInfo;
ind_learning_press = find(~strcmp(trialInfo.Outcome, 'Dark') & ~trialInfo.IsTestTrials);
[~, ind_learning_press_sort] = sort(trialInfo.PressTime(ind_learning_press));
ind_learning_press = ind_learning_press(ind_learning_press_sort);
t_learning_press = trialInfo.PressTime(ind_learning_press);
learning_press_outcome = trialInfo.Outcome(ind_learning_press);
learning_press_volume = trialInfo.ExtraToneVolumes(ind_learning_press);
learning_press_test = trialInfo.IsTestTrials(ind_learning_press);
learning_press_post = trialInfo.PostLearningPhaseTrials(ind_learning_press);
learning_press_fp = trialInfo.Foreperiod(ind_learning_press);
learning_press_hold_duration = trialInfo.HoldDuration(ind_learning_press);
[psth_learning_press, ts_learning_press, trialspxmat_learning_press, tspkmat_learning_press, ...
    t_learning_press, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
    t_learning_press, params_press);
psth_learning_press = smoothdata(psth_learning_press, 'gaussian', 5);
learning_press_outcome = learning_press_outcome(ind);
learning_press_volume = learning_press_volume(ind);
learning_press_test = learning_press_test(ind);
learning_press_post = learning_press_post(ind);
learning_press_fp = learning_press_fp(ind);
learning_press_hold_duration = learning_press_hold_duration(ind);
PSTH.LearningPress = {psth_learning_press, ts_learning_press, trialspxmat_learning_press, ...
    tspkmat_learning_press, t_learning_press, learning_press_outcome, ...
    learning_press_volume, learning_press_test, learning_press_post, learning_press_fp, ...
    learning_press_hold_duration};

ind_learning_press_vol_lt1 = learning_press_volume < 1;
ind_learning_press_vol_eq1 = learning_press_volume == 1;
psth_learning_press_vol_lt1 = nan(size(ts_learning_press));
psth_learning_press_vol_eq1 = nan(size(ts_learning_press));
if any(ind_learning_press_vol_lt1)
    [psth_learning_press_vol_lt1, ~] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
        t_learning_press(ind_learning_press_vol_lt1), params_press);
    psth_learning_press_vol_lt1 = smoothdata(psth_learning_press_vol_lt1, 'gaussian', 5);
end
if any(ind_learning_press_vol_eq1)
    [psth_learning_press_vol_eq1, ~] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
        t_learning_press(ind_learning_press_vol_eq1), params_press);
    psth_learning_press_vol_eq1 = smoothdata(psth_learning_press_vol_eq1, 'gaussian', 5);
end
PSTH.LearningPressByVolume = {psth_learning_press_vol_lt1, psth_learning_press_vol_eq1, ...
    ts_learning_press, sum(ind_learning_press_vol_lt1), sum(ind_learning_press_vol_eq1)};

%% Plot raster and spks
figure();
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')
x_trial_col = 0.85;
trial_width = 5.2;
perf_width = trial_width;
x_perf_col = x_trial_col + trial_width + 0.6;
% PSTH of correct trials
yshift_row1 = 1;
ha_press_psth =  axes('unit', 'centimeters', 'position', [x_perf_col yshift_row1 perf_width 2], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;
hplot_press= zeros(1, nFPs);
FRMax = 3;
for i =1:nFPs
    hplot_press(i) = plot(ts_press{i}, psth_presses_correct{i}, 'color', FP_cols(i, :),  'linewidth', 1.5);
    FRMax = max([FRMax max(psth_presses_correct{i})]);
%     disp(FRMax)
end
axis 'auto y'
xlabel('Time from press (ms)')
ylabel ('Spks per s')

% PSTH of error trials (premature and late)
ha_press_psth_error =  axes('unit', 'centimeters', 'position', [x_perf_col yshift_row2 perf_width 2], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1) PressTimeDomain(2)], 'xticklabel', []);
yshift_row3 = yshift_row2 +2+0.25;
% plot premature and late as well
if  size(trialspxmat_premature_press, 2)>3
    plot(ts_premature_press, psth_premature_press, 'color', premature_col, 'linewidth',1.5);
%     FRMax = max([FRMax max(psth_premature_press)]);
%      disp(FRMax)
end
if  size(trialspxmat_late_press, 2)>3
    plot(ts_late_press, psth_late_press, 'color', late_col, 'linewidth', 1.5)
%     FRMax = max([FRMax max(psth_late_press)]);
%     disp(FRMax)
end
axis 'auto y'
hline_press_error = line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);

% Learning press PSTH split by extra-tone volume, from the trial-time raster trials
ha_learning_press_psth_volume = axes('unit', 'centimeters', 'position', [x_trial_col yshift_row1 trial_width 2], ...
    'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
h_learning_press_volume = gobjects(1, 2);
if any(ind_learning_press_vol_lt1)
    h_learning_press_volume(1) = plot(ts_learning_press, psth_learning_press_vol_lt1, ...
        'color', [0.25 0.25 0.25], 'linewidth', 1.5);
    FRMax = max([FRMax max(psth_learning_press_vol_lt1(:))]);
end
if any(ind_learning_press_vol_eq1)
    h_learning_press_volume(2) = plot(ts_learning_press, psth_learning_press_vol_eq1, ...
        'color', full_volume_spike_col, 'linewidth', 1.5);
    FRMax = max([FRMax max(psth_learning_press_vol_eq1(:))]);
end
axis 'auto y'
xlabel('Time from press (ms)')
ylabel('Spks per s')
ind_learning_press_volume_legend = isgraphics(h_learning_press_volume);
if any(ind_learning_press_volume_legend)
    learning_press_volume_legend_labels = {'Vol < 1', 'Vol = 1'};
    learning_press_volume_legend_cols = [0.25 0.25 0.25; full_volume_spike_col];
    ha_learning_press_volume_legend = axes('unit', 'centimeters', ...
        'position', [x_trial_col yshift_row1+2.15 trial_width 0.6], ...
        'nextplot', 'add', 'xlim', [0 1], 'ylim', [0 1], 'visible', 'off');
    klegend = 0;
    for ileg = find(ind_learning_press_volume_legend)
        klegend = klegend + 1;
        ylegend = 1.05 - 0.42*klegend;
        line(ha_learning_press_volume_legend, [0.05 0.28], [ylegend ylegend], ...
            'color', learning_press_volume_legend_cols(ileg, :), 'linewidth', 1.5);
        text(ha_learning_press_volume_legend, 0.34, ylegend, ...
            learning_press_volume_legend_labels{ileg}, 'fontsize', 6, ...
            'verticalalignment', 'middle');
    end
end

% make raster plot  750 ms FP
if length(t_presses)>200
    rasterheight = 0.01;
elseif length(t_presses)>100
    rasterheight = 0.02;
else
    rasterheight = 0.04;
end

% Plot spike raster of correct trials (all FPs)
ntrials_press = 0;
nFP_i = zeros(1, nFPs);
t_portin =  PSTHOut.Pokes.Time;
for i =1:nFPs
    nFP_i(i) = size(trialspxmat_press{i}, 2);
    ntrials_press = ntrials_press + nFP_i(i);
end
ntrial_learning_press = size(trialspxmat_learning_press, 2);
axes('unit', 'centimeters', 'position', [x_trial_col yshift_row3 trial_width max([ntrial_learning_press 1])*rasterheight],...
    'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], ...
    'ylim', [-max([ntrial_learning_press 1]) 1], 'box', 'on');
ap_mat = trialspxmat_learning_press;
t_mat = tspkmat_learning_press;
xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_vol = [];
y_vol = [];
c_vol = [];
x_test = [];
y_test = [];
for i =1:ntrial_learning_press
    xx = t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-i+1;
    yy2 = [0 1]-i+1;
    yy_shade = [-i+1 -i+1; 1-i+1 1-i+1];
    iFP = learning_press_fp(i);
    plotshaded([0 iFP], yy_shade, trigger_col);
    if learning_press_volume(i)>0
        patch([0 750 750 0], [-i+1 -i+1 1-i+1 1-i+1], ...
            extra_tone_shade_col, 'FaceAlpha', extra_tone_alpha, 'EdgeColor', 'none');
    end
    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    if ~isnan(learning_press_hold_duration(i))
        xxrt_all = [xxrt_all, learning_press_hold_duration(i), learning_press_hold_duration(i), NaN];
        yyrt_all = [yyrt_all, yy2, NaN];
    end
    x_vol = [x_vol, -PressTimeDomain(1)-75];
    y_vol = [y_vol, -i+1+0.5];
    c_vol = [c_vol, learning_press_volume(i)];
    if learning_press_test(i)
        x_test = [x_test, PressTimeDomain(2)+75];
        y_test = [y_test, -i+1+0.5];
    end
end
line(xx_all, yy_all, 'color', [0.2 0.2 0.2], 'linewidth', 1);
line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5);
ind_vol_valid = ~isnan(c_vol);
scatter(x_vol(ind_vol_valid), y_vol(ind_vol_valid), 12, c_vol(ind_vol_valid), ...
    's', 'filled', 'MarkerEdgeColor', 'none', 'Clipping', 'off');
scatter(x_vol(~ind_vol_valid), y_vol(~ind_vol_valid), 12, [0.75 0.75 0.75], ...
    's', 'filled', 'MarkerEdgeColor', 'none', 'Clipping', 'off');
plot(x_test, y_test, '|', 'color', 'k', 'markersize', 4, 'linewidth', 1);
colormap(gca, parula);
caxis([0 1]);
line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
title('Trial time', 'fontsize', 7, 'fontweight','bold');
axis off
yshift_trial_press = yshift_row3+max([ntrial_learning_press 1])*rasterheight+0.5;

axes('unit', 'centimeters', 'position', [x_perf_col yshift_row3 perf_width ntrials_press*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nFPs
    ap_mat = trialspxmat_press{m};
    t_mat = tspkmat_press{m};
    rt = rt_presses_sorted{m};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:nFP_i(m)
        irt = rt(i); % time from foreperiod to release
        mFP = conditionFPs(m);
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        xxrt = irt + mFP;
        plotshaded([0 mFP],[-k -k; 1-k 1-k], trigger_col);
        if conditionVolumes(m)>0
            patch([0 750 750 0], ...
                [-k -k 1-k 1-k], extra_tone_shade_col, 'FaceAlpha', extra_tone_alpha, 'EdgeColor', 'none');
        end

        if isempty(find(isnan(ap_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy1, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
            yyrt_all = [yyrt_all, yy2, NaN];
        end
        % port access time
        itpress =t_presses_correct{m}(i);
        i_portin = t_portin - itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end
        k = k+1;
    end
    line(xx_all, yy_all, 'color', FP_cols(m, :), 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end

line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
title('Correct', 'fontsize', 7, 'fontweight','bold');
axis off

% Premature press raster plot
ntrial_premature = size(trialspxmat_premature_press, 2); % number of trials
axes('unit', 'centimeters', 'position', [x_perf_col yshift_row4 perf_width ntrial_premature*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial_premature 1], 'box', 'on');
yshift_row5    =      yshift_row4 + 0.5 + ntrial_premature*rasterheight;
ap_mat          =     trialspxmat_premature_press;
t_mat             =     tspkmat_premature_press;
k =0;
xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_portin = [];
y_portin = [];
for i =1:size(ap_mat, 2)
    ipredur = premature_duration_presses(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy2 = [0 1]-k;
    xxrt = ipredur;
    iFP = conditionFPs(FPs_premature_presses(i));
    plotshaded([0 iFP], [-k -k; 1-k 1-k], trigger_col);
    if conditionVolumes(FPs_premature_presses(i))>0
        patch([0 750 750 0], ...
            [-k -k 1-k 1-k], extra_tone_shade_col, 'FaceAlpha', extra_tone_alpha, 'EdgeColor', 'none');
    end

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
    yyrt_all = [yyrt_all, yy2, NaN];

    % plot port poke time
    i_portin = t_portin - t_premature_presses(i);
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];        
    end
    k = k+1;
end

line(xx_all, yy_all, 'color', premature_col, 'linewidth', 1)
line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5)
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1)
title('Premature', 'fontsize', 7, 'fontweight','bold')
axis off

% Late response raster plot
ntrial_late = size(trialspxmat_late_press, 2); % number of trials
axes('unit', 'centimeters', 'position', [x_perf_col yshift_row5  perf_width ntrial_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial_late 1], 'box', 'on');
yshift_row6             =      yshift_row5 + 0.5 + ntrial_late*rasterheight;
ap_mat          =     trialspxmat_late_press;
t_mat             =     tspkmat_late_press;
k =0;
xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_portin = [];
y_portin = [];
for i =1:size(ap_mat, 2)
    ilatedur =late_duration_presses(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy2 = [0 1]-k;
    xxrt = ilatedur;
    iFP = conditionFPs(FPs_late_presses(i));
    plotshaded([0 iFP], [-k -k; 1-k 1-k], trigger_col);
    if conditionVolumes(FPs_late_presses(i))>0
        patch([0 750 750 0], ...
            [-k -k 1-k 1-k], extra_tone_shade_col, 'FaceAlpha', extra_tone_alpha, 'EdgeColor', 'none');
    end

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
    yyrt_all = [yyrt_all, yy2, NaN];

    % plot port poke time
    i_portin = t_portin - t_late_presses(i);
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    k = k+1;
end

line(xx_all, yy_all, 'color', late_col, 'linewidth', 1)
line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5)
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1)
title('Late', 'fontsize', 7, 'fontweight','bold')
axis off
yshift_row6 = max([yshift_row6, yshift_trial_press]);

% this is the position of last panel
% Add information
uicontrol('Style','text','Units','centimeters','Position',[x_trial_col-0.4 yshift_row6  trial_width+0.5 1],...
    'string', 'A. Trial-time press', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');
uicontrol('Style','text','Units','centimeters','Position',[x_perf_col-0.4 yshift_row6  perf_width+0.5 1],...
    'string', 'B. Press-related activity', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

yshift_row7=yshift_row6+1.25;
ch = r.Units.SpikeNotes(ku, 1);
unit_no = r.Units.SpikeNotes(ku, 2);

if size(r.Units.SpikeNotes, 2) == 4
    cluster_id = r.Units.SpikeNotes(ku, 4);
    uicontrol('style', 'text', 'units', 'centimeters', 'position', [1 yshift_row7 6 1.2],...
        'string', (['Unit #' num2str(ku) ' (Ch ' num2str(ch) ' | UnitOnCh ' num2str(unit_no) ' | ' 'Kilosort cluster ' num2str(cluster_id) ')']),...
        'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold',  'FontName','Dejavu Sans')
else
    cluster_id = [];
    uicontrol('style', 'text', 'units', 'centimeters', 'position', [1 yshift_row7 6 1.2],...
        'string', (['Unit #' num2str(ku) ' (' num2str(ch) ' | ' num2str(unit_no) ')']),...
        'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold',  'FontName','Dejavu Sans')
end
uicontrol('style', 'text', 'units', 'centimeters', 'position', [1 yshift_row7+1.2 4 0.5],...
    'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w',...
    'fontsize', 10, 'fontweight', 'bold',  'FontName','Dejavu Sans')

fig_height = yshift_row7+2;

%% Release PSTHs
% Release-related PSTHs
width = 6*sum(ReleaseTimeDomain)/sum(PressTimeDomain);
x_release_col = x_perf_col + perf_width + 0.85;
yshift_row1 = 1;
ha_release_psth =  axes('unit', 'centimeters', 'position', [x_release_col yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;

for i =1:nFPs
    hplot_release(i) = plot(ts_release{i}, psth_release_correct{i}, 'color', FP_cols(i, :),  'linewidth', 1.5);
    FRMax = max([FRMax max(psth_release_correct{i})]);
%     disp(FRMax)
end
axis 'auto y'
hline_release = line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
xlabel('Time from release (ms)')
ylabel ('Spks per s')

% error PSTHs
ha_release_psth_error =  axes('unit', 'centimeters', 'position', [x_release_col yshift_row2 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'xticklabel',[]);
yshift_row3 = yshift_row2 +2+0.25;
if  size(trialspxmat_premature_release, 2)>3
    plot(ts_premature_release, psth_premature_release, 'color', premature_col, 'linewidth', 1.5)
%     FRMax = max([FRMax max(psth_premature_release)]);
%     disp(FRMax)
end
if  size(trialspxmat_late_release, 2)>3
    plot(ts_late_release, psth_late_release, 'color', late_col, 'linewidth', 1.5)
%     FRMax = max([FRMax max(psth_late_release)]);
%     disp(FRMax)
end
axis 'auto y'
hline_release_error =line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);

% Make raster plot
% Plot spike raster of correct trials (all FPs)
ntrials_release = 0;
nFP_i = zeros(1, nFPs);
for i =1:nFPs
    nFP_i(i) = size(trialspxmat_release{i}, 2);
    ntrials_release = ntrials_release + nFP_i(i);
end

axes('unit', 'centimeters', 'position', [x_release_col yshift_row3 width ntrials_release*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'ylim', [-ntrials_release 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_release*rasterheight+0.5;
% Paint the foreperiod
n_start = 1;
k=0;
for m =1:nFPs
    ap_mat = trialspxmat_release{m};
    t_mat = tspkmat_release{m};
    rt = rt_releases_sorted{m};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:nFP_i(m)
        irt = rt(i); % time from foreperiod to release
        mFP = conditionFPs(m);
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;

        % paint foreperiod
        plotshaded([-irt-mFP -irt]-n_start, [-k -k; 1-k 1-k], trigger_col);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, -irt-mFP, -irt-mFP, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];

        % port access time
        itrelease =t_releases_correct{m}(i);
        i_portin = t_portin - itrelease;
        i_portin = i_portin(i_portin>=-ReleaseTimeDomain(1) & i_portin<=ReleaseTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];            
        end
        k = k+1;
    end
    n_start = n_start - nFP_i(m);

    line(xx_all, yy_all, 'color', FP_cols(m, :), 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', press_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end
line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
title('Correct', 'fontsize', 7);
axis off

% Premature release raster plot
ntrial_premature = size(trialspxmat_premature_release, 2); % number of trials
axes('unit', 'centimeters', 'position', [x_release_col yshift_row4 width ntrial_premature*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'ylim', [-ntrial_premature 1], 'box', 'on');
yshift_row5    =      yshift_row4 + 0.5 + ntrial_premature*rasterheight;
ap_mat          =     trialspxmat_premature_release;
t_mat             =     tspkmat_premature_release;
k =0;
xx_all = [];
yy_all = [];
x_predur_all = [];
y_predur_all = [];
x_portin = [];
y_portin = [];
for i =1:size(ap_mat, 2)
    ipredur = premature_duration_releases(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;

    x_predur_all = [x_predur_all, -ipredur, -ipredur, NaN];
    y_predur_all = [y_predur_all, yy, NaN];

    % paint foreperiod
    iFP = conditionFPs(FPs_premature_releases(i));
    plotshaded([-ipredur -ipredur+iFP], [-k -k; 1-k 1-k], trigger_col);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end    

    % plot port poke time
    i_portin = t_portin - t_premature_releases(i);
    i_portin = i_portin(i_portin>=-ReleaseTimeDomain(1) & i_portin<=ReleaseTimeDomain(2));
    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];         
    end
    k = k+1;
end

line(x_predur_all, y_predur_all, 'color', press_col, 'linewidth', 1.5);
line(xx_all, yy_all, 'color', premature_col, 'linewidth', 1)
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1)
title('Premature', 'fontsize', 7)
axis off

% Late response raster plot
ntrial_late = size(trialspxmat_late_release, 2); % number of trials
axes('unit', 'centimeters', 'position', [x_release_col yshift_row5  width ntrial_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'ylim', [-ntrial_late 1], 'box', 'on');
yshift_row6    =      yshift_row5 + 0.5 + ntrial_late*rasterheight;
ap_mat          =     trialspxmat_late_release;
t_mat             =     tspkmat_late_release;
k =0;
xx_all = [];
yy_all = [];
x_latedur_all = [];
y_latedur_all = [];
x_portin = [];
y_portin = [];
for i =1:size(ap_mat, 2)
    ilatedur =late_duration_releases(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;
    % paint foreperiod
    iFP = conditionFPs(FPs_late_releases(i));
    plotshaded([-ilatedur -ilatedur+iFP], [-k -k; 1-k 1-k], trigger_col);
    x_latedur_all = [x_latedur_all, -ilatedur, -ilatedur, NaN];
    y_latedur_all = [y_latedur_all, yy, NaN];

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end  

    % plot port poke time
    i_portin = t_portin - t_late_releases(i);
    i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];  
    end
    k = k+1;
end
line(x_latedur_all, y_latedur_all, 'color', press_col, 'linewidth', 1.5);
line(xx_all, yy_all, 'color', late_col, 'linewidth', 1)
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1)
title('Late', 'fontsize', 7)
axis off

% Add information
uicontrol('Style','text','Units','centimeters','Position',[x_release_col-0.5 yshift_row6 width+1 1],...
    'string', 'C. Release-related', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

%% Reward
col3 = x_release_col + width + 1.8;
width = 6*sum(RewardTimeDomain)/sum(PressTimeDomain);
ha_poke =  axes('unit', 'centimeters', 'position', [col3 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-RewardTimeDomain(1) RewardTimeDomain(2)]);
for i =1:nFPs
    plot(ts_reward_pokes{i}, psth_reward_pokes{i}, 'color', FP_cols(i, :), 'linewidth', 1.5);
    FRMax = max([FRMax max(psth_reward_pokes{i})]);
%     disp(FRMax)
end
% also add non-rewarded pokes
plot(ts_nonreward_pokes, psth_nonreward_pokes, 'color', [0.6 0.6 0.6], 'linewidth', .5);
xlabel('Time from rewarded/nonrewarded poke (ms)')
ylabel ('Spks per s')
axis 'auto y'
hline_poke = line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', reward_ref_lw);
% FRMax = max([FRMax max(psth_nonreward_pokes)]);
% disp(FRMax)
% Raster plot

% Make raster plot
% Plot spike raster of correct trials (all FPs)
ntrials_rewardpoke = 0;
nFP_i = zeros(1, nFPs);
for i =1:nFPs
    nFP_i(i) = size(trialspxmat_reward_pokes{i}, 2);
    ntrials_rewardpoke = ntrials_rewardpoke + nFP_i(i);
end;

axes('unit', 'centimeters', 'position', [col3 yshift_row2 width ntrials_rewardpoke*rasterheight],...
    'nextplot', 'add', 'xlim',  [-RewardTimeDomain(1) RewardTimeDomain(2)], ...
    'ylim', [-ntrials_rewardpoke 1], 'box', 'on', 'xticklabel', []);
yshift_row3new = yshift_row2 + ntrials_rewardpoke*rasterheight + 0.5;

% Paint the foreperiod
k = 0;
for m =1:nFPs
    ap_mat = trialspxmat_reward_pokes{m};
    t_mat = tspkmat_reward_pokes{m};
    move=move_time{m};
    xx_all = [];
    yy_all = [];
    x_move_all = [];
    y_move_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:nFP_i(m)
        xx =  t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        imov = -move(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end 

        x_move_all = [x_move_all, imov, imov, NaN];
        y_move_all = [y_move_all, yy2, NaN];

        % plot port poke time
        itreward =t_reward_pokes{m}(i);
        i_portin = t_portin-itreward;
        i_portin = i_portin(i_portin>=-RewardTimeDomain(1) & i_portin<=RewardTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];            
        end
        k = k+1;
    end
    line(xx_all, yy_all, 'color', FP_cols(m,:), 'linewidth', 1)
    line(x_move_all, y_move_all, 'color', release_col, 'linewidth', reward_move_lw)
end
line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', reward_ref_lw);
title('Correct', 'fontsize', 7);
axis off


% Raster plot for unrewarded pokes
% use at most 50 events
if size(trialspxmat_nonreward_pokes, 2)>50
    plot_ind = sort(randperm(size(trialspxmat_nonreward_pokes, 2), 50));
    trialspxmat_nonreward_pokes_plot = trialspxmat_nonreward_pokes(:, plot_ind);
else
    trialspxmat_nonreward_pokes_plot = trialspxmat_nonreward_pokes;
    plot_ind = 1:size(trialspxmat_nonreward_pokes, 2);
end

ntrial_nonrewardpoke = size(trialspxmat_nonreward_pokes_plot, 2);
axes('unit', 'centimeters', 'position', [col3 yshift_row3new width ntrial_nonrewardpoke*rasterheight],...
    'nextplot', 'add', 'xlim',  [-RewardTimeDomain(1) RewardTimeDomain(2)], ...
    'ylim', [-ntrial_nonrewardpoke 1], 'box', 'on', 'xticklabel', []);
yshift_row4new = yshift_row3new+0.5+ntrial_nonrewardpoke*rasterheight;
k =0;
move_time_nonreward_plot             =                          move_time_nonreward(plot_ind);
t_nonreward_pokes_plot                  =                          t_nonreward_pokes(plot_ind);

xx_all = [];
yy_all = [];
x_move_all = [];
y_move_all = [];
x_portin = [];
y_portin = [];
for i =1:ntrial_nonrewardpoke
    if isempty(find(isnan(trialspxmat_nonreward_pokes_plot(:, i)), 1))
        xx =  tspkmat_nonreward_pokes(trialspxmat_nonreward_pokes_plot(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        imov = -move_time_nonreward_plot(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end 

        x_move_all = [x_move_all, imov, imov, NaN];
        y_move_all = [y_move_all, yy2, NaN];

        % plot port poke time
        itreward =t_nonreward_pokes_plot(i);
        i_portin = t_portin-itreward;
        i_portin = i_portin(i_portin>=-RewardTimeDomain(1) & i_portin<=RewardTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];             
        end
    end
    k = k+1;
end

line(xx_all, yy_all, 'color', [0.6 0.6 0.6], 'linewidth', 1)
line(x_move_all, y_move_all, 'color', release_col, 'linewidth', reward_move_lw)

line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', reward_ref_lw)
axis off
title('Nonrewarded pokes', 'fontname', 'dejavu sans', 'fontsize', 7)

% Add information  13.5 3+0.5 6 ntrial4*rasterheight
uicontrol('Style','text','Units','centimeters','Position',[col3-0.5 yshift_row4new 5 1.75],...
    'string', 'D. Rewarded/Nonrewarded poke-related activity', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');

yshift_row5new = yshift_row4new+1.75+1.5;

%% plot pre-press activity vs trial num or time

ha10=axes('unit', 'centimeters', 'position', [col3 yshift_row5new 5 2.5], ...
    'nextplot', 'add', 'xlim', [min(t_correct_presses_all/1000) max(t_correct_presses_all/1000)]);

ind_prepress = find(tspkmat_press_all<0);
spkmat_prepress =  trialspxmat_press_all(ind_prepress, :);
dur_prepress = abs(tspkmat_press_all(ind_prepress(1)))/1000; % total time

rate_prepress = sum(spkmat_prepress, 1)/dur_prepress; % spk rate across time
plot(ha10, t_correct_presses_all/1000, rate_prepress, 'k', 'marker', 'o', 'markersize', 3, 'linestyle', 'none');

% linear regression
Pfit = polyfit(t_correct_presses_all/1000,rate_prepress,1);
yfit = Pfit(1)*t_correct_presses_all/1000+Pfit(2);
plot(t_correct_presses_all/1000,yfit,'r:', 'linewidth', 1.5);

xlabel('Time (s)')
ylabel('Spk rate (Hz)')

yshift_row6new = yshift_row5new+3;
% Add information  13.5 3+0.5 6 ntrial4*rasterheight
uicontrol('Style','text','Units','centimeters','Position',[col3-0.5 yshift_row6new 4 0.5],...
    'string', 'E.  Activity vs time', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');

fig_height = max([fig_height, yshift_row6new+1]);

%% plot extra-tone-related activity
col4 = col3 + 7.2;
width = 3.2;
col4b = col4 + width + 0.9;
extra_titles = {'Learning extra', 'Full-volume extra'};
extra_cols = [0.25 0.25 0.25; full_volume_spike_col];
ha_trigger = gobjects(1, length(PSTHOut.ExtraTone.Time));
ha_extra_raster = gobjects(1, length(PSTHOut.ExtraTone.Time));
yshift_row4_all = zeros(1, length(PSTHOut.ExtraTone.Time));
for igroup = 1:length(PSTHOut.ExtraTone.Time)
    if igroup == 1
        this_col = col4;
    else
        this_col = col4b;
    end
    ha_trigger(igroup) = axes('unit', 'centimeters', 'position', [this_col yshift_row1 width 2], ...
        'nextplot', 'add', 'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)]);
    plot(ts_extra_tone{igroup}, psth_extra_tone{igroup}, 'color', extra_cols(igroup, :), 'linewidth', 1.5);
    if ~isempty(psth_extra_tone{igroup})
        FRMax = max([FRMax max(psth_extra_tone{igroup}(:))]);
    end
    xlabel('Time from extra tone (ms)')
    ylabel('Spks per s')
    axis 'auto y'

    ntrials_extra = size(trialspxmat_extra_tone{igroup}, 2);
    ha_extra_raster(igroup) = axes('unit', 'centimeters', 'position', [this_col yshift_row2 width max([ntrials_extra 1])*rasterheight], ...
        'nextplot', 'add', 'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], ...
        'ylim', [-max([ntrials_extra 1]) 1], 'box', 'on');
    yshift_row4_all(igroup) = yshift_row2 + max([ntrials_extra 1])*rasterheight + 0.5;
    ap_mat = trialspxmat_extra_tone{igroup};
    t_mat = tspkmat_extra_tone{igroup};
    rt = RT_extra_tone{igroup};
    volumes = volume_extra_tone{igroup};
    is_test = is_test_extra_tone{igroup};
    press_time = press_extra_tone{igroup};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    x_vol = [];
    y_vol = [];
    c_vol = [];
    for i =1:ntrials_extra
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-i+1;
        yy2 = [0 1]-i+1;
        target_from_extra = FP_extra_tone{igroup}(i) - 750;
        if target_from_extra > 0
            plotshaded([0 target_from_extra], [-i+1 -i+1; 1-i+1 1-i+1], trigger_col);
        end
        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        release_from_extra = FP_extra_tone{igroup}(i) - 750 + rt(i);
        xxrt_all = [xxrt_all, release_from_extra, release_from_extra, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];
        i_portin = t_portin - t_extra_tone{igroup}(i);
        i_portin = i_portin(i_portin>=-TriggerTimeDomain(1) & i_portin<=TriggerTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (-i+1+0.4)*ones(1,length(i_portin))];
        end
        x_vol = [x_vol, -TriggerTimeDomain(1)-75];
        y_vol = [y_vol, -i+1+0.5];
        c_vol = [c_vol, volumes(i)];
    end
    line(xx_all, yy_all, 'color', extra_cols(igroup, :), 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled', 'MarkerFaceColor', reward_col, ...
        'markerfacealpha', 0.5, 'MarkerEdgeColor', 'none');
    ind_vol_valid = ~isnan(c_vol);
    scatter(x_vol(ind_vol_valid), y_vol(ind_vol_valid), 12, c_vol(ind_vol_valid), ...
        's', 'filled', 'MarkerEdgeColor', 'none', 'Clipping', 'off');
    scatter(x_vol(~ind_vol_valid), y_vol(~ind_vol_valid), 12, [0.75 0.75 0.75], ...
        's', 'filled', 'MarkerEdgeColor', 'none', 'Clipping', 'off');
    if igroup == 2
        ind_test_rows = find(is_test & ~post_learning_extra_tone{igroup});
        if ~isempty(ind_test_rows)
            x_test_line = TriggerTimeDomain(2)+75;
            d_test = diff(ind_test_rows);
            block_start = [ind_test_rows(1); ind_test_rows(find(d_test>1)+1)];
            block_end = [ind_test_rows(find(d_test>1)); ind_test_rows(end)];
            for iBlock = 1:length(block_start)
                line([x_test_line x_test_line], [-block_end(iBlock)+1 -block_start(iBlock)+1], ...
                    'color', 'k', 'linewidth', 2, 'Clipping', 'off');
            end
        end
    end
    colormap(gca, parula);
    caxis([0 1]);
    line([0 0], get(gca, 'ylim'), 'color', trigger_col, 'linewidth', 1);
    title(extra_titles{igroup}, 'fontsize', 7);
    axis off
end

if ~isempty(ha_extra_raster)
    colormap(ha_extra_raster(end), parula);
    caxis(ha_extra_raster(end), [0 1]);
    cb_vol = colorbar(ha_extra_raster(end));
    set(cb_vol, 'Units', 'centimeters', 'Position', [col4b+width+0.35 yshift_row2 0.18 2.0], ...
        'Ticks', [0 0.5 1], 'FontSize', 6);
    ylabel(cb_vol, 'Vol', 'FontSize', 6);
end

% Add information
yshift_row4 = max(yshift_row4_all);
uicontrol('Style','text','Units','centimeters','Position',[col4-0.5  yshift_row4 width+0.8 1.2],...
    'string', 'F. Extra-tone-related activity', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
uicontrol('Style','text','Units','centimeters','Position',[col4b-0.5  yshift_row4 width+0.8 1.2],...
    'string', 'G. Full-volume extra', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
yshift_row5=yshift_row4+1.2+1.2;

FRMax = max(FRMax(:));
FRrange = [0 FRMax*1.1];
set(ha_press_psth, 'ylim', FRrange);
line(ha_press_psth, [0 0], FRrange, 'color', press_col, 'linewidth', 1);

line(ha_press_psth, [fixedFP fixedFP], FRrange, 'color', trigger_col, 'linestyle', ':', 'linewidth', 1);

set(ha_learning_press_psth_volume, 'ylim', FRrange);
line(ha_learning_press_psth_volume, [0 0], FRrange, 'color', press_col, 'linewidth', 1);
set(ha_press_psth_error, 'ylim', FRrange);
line(ha_press_psth_error, [0 0], FRrange, 'color', press_col, 'linewidth', 1);
set(ha_release_psth, 'ylim', FRrange);
line(ha_release_psth, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_release_psth_error, 'ylim', FRrange);
line(ha_release_psth_error, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_poke, 'ylim', FRrange);
line(ha_poke, [0 0], FRrange, 'color', reward_col, 'linewidth', 1);
for i =1:length(ha_trigger)
    set(ha_trigger(i), 'ylim', FRrange);
    line(ha_trigger(i), [0 0], FRrange, 'color', trigger_col, 'linewidth', 1);
end


%% plot spks
col5=col4;
thiscolor = [0 0 0];

if isfield(r.Units.SpikeTimes(ku), 'wave')
    Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
    ha0=axes('unit', 'centimeters', 'position', [col5 yshift_row5 1.5 1.5], ...
        'nextplot', 'add', 'xlim', [0 Lspk], 'ytick', -500:100:200, 'xticklabel', []);
    set(ha0, 'nextplot', 'add');
    ylabel('uV')
    allwaves = r.Units.SpikeTimes(ku).wave/4;
    if size(allwaves, 1)>100
        nplot = randperm(size(allwaves, 1), 100);
    else
        nplot=1:size(allwaves, 1);
    end
    wave2plot = allwaves(nplot, :);
    plot(1:Lspk, wave2plot, 'color', [0.8 .8 0.8]);
    plot(1:Lspk, mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
    axis([0 Lspk min(wave2plot(:)) max(wave2plot(:))])
    set (gca, 'ylim', [min(mean(allwaves, 1))*1.25 max(mean(allwaves, 1))*1.25])
    axis tight
    line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
    PSTH.SpikeWave = mean(allwaves, 1);
end

% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);
kutime = kutime(kutime>0);
kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;
[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;

ha00= axes('unit', 'centimeters', 'position', [col5+1.5+1 yshift_row5 2 1.5], 'nextplot', 'add', 'xlim', [-25 25]);
if median(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 median(c)]);
else
    set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 1], 'ylim', [0 1]);
end

switch r.Units.SpikeNotes(ku, 3)
    case 1
        title(['#' num2str(ku) '(Ch ' num2str(r.Units.SpikeNotes(ku, 1)) ' | unit' num2str(r.Units.SpikeNotes(ku, 2))  ' | SU'], 'fontsize', 7);
    case 2
        title(['#' num2str(ku) '(Ch ' num2str(r.Units.SpikeNotes(ku, 1))  ' | unit' num2str(r.Units.SpikeNotes(ku, 2))  ' | MU'], 'fontsize', 7);
    otherwise
end

PSTH.AutoCorrelation = {lags, c};

hbar = bar(lags, c);
set(hbar, 'facecolor', 'k');
xlabel('Lag(ms)')

yshift_row6 = yshift_row5+2;
% Plot all waveforms if it is a polytrode
if isfield(r.Units.SpikeTimes(ku), 'wave_mean')
    ha_wave_poly = axes('unit', 'centimeters', 'position', [col5 yshift_row6 4 3], 'nextplot', 'add');
    wave_form = r.Units.SpikeTimes(ku).wave_mean/4;
    PSTH.SpikeWaveMean = wave_form;
    n_chs = size(wave_form, 1); % number of channels
    ch_selected = 1:n_chs;
    if n_chs > 32
        n_chs = 32;
        ch_largest = r.Units.SpikeNotes(ku,1);
        if ch_largest < n_chs/2
            ch_selected = 1:n_chs;
        elseif ch_largest > size(wave_form, 1) - n_chs/2
            ch_selected = size(wave_form, 1)-n_chs+1:size(wave_form, 1);
        else
            ch_selected = ch_largest-15:ch_largest+16;
        end
    end
    n_sample = size(wave_form, 2); % sample size per spike
    n_cols = 8;
    n_rows = n_chs/n_cols;
    max_x = 0;
    colors = [25, 167, 206]/255;
    if n_rows<1
        n_rows=1;
    end
    v_sep = 100;

    t_wave_all = [];
    wave_all = [];
    for i = 1:n_rows
        for j = 1:n_cols
            k = j+(i-1)*n_cols;
            wave_k = wave_form(ch_selected(k), :)+v_sep*(i-1);
            t_wave = (1:n_sample)+n_sample*(j-1)+4;
            t_wave_all = [t_wave_all, t_wave, NaN];
            wave_all = [wave_all, wave_k, NaN];
            max_x = max([max_x, max(t_wave)]);
        end
    end
    plot(ha_wave_poly, t_wave_all, wave_all, 'linewidth', 1, 'color', colors);

    set(ha_wave_poly, 'xlim', [0 max_x], 'ylim', [-400  v_sep*(n_rows-1)+200]);
    axis off
    axis tight

    yshift_row7 = yshift_row6+3;
else
    yshift_row7 = yshift_row6;
end

uicontrol('Style','text','Units','centimeters','Position',[col5-0.5 yshift_row7 5 1.5],...
    'string', 'H. Spike waveform and autocorrelation', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
fig_height = max([fig_height, yshift_row7+2]);
% change the height of the figure
set(gcf, 'position', [2 2 35.5 fig_height])
toc;

if strcmpi(ToSave,'on')
    % save to a folder
    anm_name        =     r.BehaviorClass.Subject;
    session              =     r.BehaviorClass.Date;
    
    PSTH.ANM_Session = {anm_name, session};
    thisFolder = fullfile(pwd, 'Fig');
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    tosavename2= fullfile(thisFolder, [anm_name '_' session '_Learning_Ch'  num2str(ch) '_Unit' num2str(unit_no) ]);
    print (gcf,'-dpng', tosavename2)
    
    % save PSTH as well save(psth_new_name, 'PSTHOut');
    save([tosavename2 '.mat'], 'PSTH')
    
%     try
%         tic
%         % C:\Users\jiani\OneDrive\00_Work\03_Projects
%         thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'UnitsCollection', anm_name, session);
%         if ~exist(thisFolder, 'dir')
%             mkdir(thisFolder)
%         end
%         copyfile([tosavename2 '.png'], thisFolder)
%         copyfile([tosavename2 '.mat'], thisFolder)
%     
%         toc
%     end
end
