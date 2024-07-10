function PSTH = ComputePlotPSTH(r, PSTHOut, ku, varargin)

% Jianing Yu 5/8/2023
% For plotting PSTHs under SRT condition.
% Extracted from SRTSpikes
% Jianing Yu 5/10/2023  This is adapted from Spikes.SRT.ComputePlotPSTH

% Modified by Yue Huang on 7/12/2023
% Change the way of making raster plots to run faster

close all;
PSTH.UnitID       = ku;
combine_cue_uncue = 0;
nTypes = 2;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'RewardTimeDomain'
                RewardTimeDomain = varargin{i+1};
            case 'TriggerTimeDomain'
                TriggerTimeDomain = varargin{i+1};
            case 'CombineCueUncue'
                combine_cue_uncue = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

% For PSTH and raster plots
press_col = [5 191 219]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
reward_col = [164, 208, 164]/255;
% FP_cols = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;
FP_cols = [76, 61, 61; 76, 61, 61]/255;

premature_col = [0.9 0.4 0.1];
late_col = [0.6 0.6 0.6];
FPKornblum = PSTHOut.Presses.FP;
nFPs = length(FPKornblum);
printsize = [2 2 25 25];

%% PSTHs for press and release
params_press.pre            =              PressTimeDomain(1);
params_press.post          =              PressTimeDomain(2);
params_press.binwidth    =              20;

params_release.pre =  ReleaseTimeDomain(1);
params_release.post = ReleaseTimeDomain(2);
params_release.binwidth = 20;

t_presses = PSTHOut.Presses.Time{strcmp(PSTHOut.Presses.TimeLabels, 'All')};
[psth_presses_all, ts_press_all, trialspxmat_press_all, tspkmat_press_all,  t_correct_presses_all,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_presses_all = smoothdata (psth_presses_all, 'gaussian', 5);
PSTH.PressesAllLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents'};
PSTH.PressesAll =  {psth_presses_all, ts_press_all, trialspxmat_press_all, tspkmat_press_all,  t_correct_presses_all};

psth_presses_correct= [];
ts_press=[];
trialspxmat_press=[];
tspkmat_press=[];

psth_release_correct=[];
ts_release=[];
trialspxmat_release=[];
tspkmat_release=[];

% Press cue (correct)
type = {'Cue', 'Uncue'};
for i =1:length(type)
    keyword = ['Correct' type{i}];
    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_presses_correct{i} = PSTHOut.Presses.Time{ind_type};
    [psth_presses_correct{i}, ts_press{i}, trialspxmat_press{i}, tspkmat_press{i}, t_presses_correct{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_presses_correct{i}, params_press);
    psth_presses_correct{i} = smoothdata (psth_presses_correct{i}, 'gaussian', 5);

    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_releases_correct{i} = PSTHOut.Releases.Time{ind_type};
    [psth_releases_correct{i}, ts_release{i}, trialspxmat_release{i}, tspkmat_release{i}, t_releases_correct{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_releases_correct{i}, params_release);
    psth_releases_correct{i} = smoothdata (psth_releases_correct{i}, 'gaussian', 5);

    keyword = ['RTCorrect' type{i}];
    ind_type = strcmp(PSTHOut.Presses.RTLabels, keyword);
    rt_presses_sorted{i}  = PSTHOut.Presses.RT_Correct{ind_type};
    rt_presses_sorted{i} =  rt_presses_sorted{i}(ind);

    ind_type = strcmp(PSTHOut.Releases.RTLabels, keyword);
    rt_releases_sorted{i}  = PSTHOut.Releases.RT_Correct{ind_type};
    rt_releases_sorted{i} =  rt_releases_sorted{i}(ind);
end
PSTH.PressesTypes = type;
PSTH.PressesLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT'};
PSTH.Presses = {psth_presses_correct, ts_press, trialspxmat_press, tspkmat_press,   t_presses_correct, rt_presses_sorted};
PSTH.ReleasesTypes = type;
PSTH.ReleasesLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT'};
PSTH.Releases = {psth_releases_correct, ts_release, trialspxmat_release, tspkmat_release,   t_releases_correct, rt_releases_sorted};

% Premature press/release PSTH
type = {'Cue', 'Uncue'};
for i =1:length(type)
    keyword = ['Premature' type{i}];
    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_premature_presses{i} = PSTHOut.Presses.Time{ind_type};
    [psth_premature_presses{i}, ts_premature_presses{i}, trialspxmat_premature_presses{i}, tspkmat_premature_presses{i}, t_premature_presses{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_premature_presses{i}, params_press);
    psth_premature_presses{i} = smoothdata (psth_premature_presses{i}, 'gaussian', 5);

    % Upadate premature release duration 
    keyword = [type{i}];
    ind_type = strcmp(PSTHOut.Presses.PressDurLabels, keyword);
    premature_press_duration{i}  = PSTHOut.Presses.PressDur.Premature{ind_type};
    premature_press_duration{i} =  premature_press_duration{i}(ind);

    keyword = ['Premature' type{i}];
    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_premature_releases{i} = PSTHOut.Releases.Time{ind_type};
    [psth_premature_releases{i}, ts_premature_releases{i}, trialspxmat_premature_releases{i}, tspkmat_premature_releases{i}, t_premature_releases{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_premature_releases{i}, params_release);
    psth_premature_releases{i} = smoothdata (psth_premature_releases{i}, 'gaussian', 5);

    keyword = [type{i}];
    ind_type = strcmp(PSTHOut.Presses.PressDurLabels, keyword);
    premature_release_duration{i}  = PSTHOut.Releases.PressDur.Premature{ind_type};
    premature_release_duration{i} =  premature_release_duration{i}(ind);

end
PSTH.PrematureLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'PressDuration'};
PSTH.PrematurePresses        =    {psth_premature_presses, ts_premature_presses, trialspxmat_premature_presses, tspkmat_premature_presses,   t_premature_presses, premature_press_duration};
PSTH.PrematureReleases      =    {psth_premature_releases, ts_premature_releases, trialspxmat_premature_releases, tspkmat_premature_releases, t_premature_releases, premature_release_duration};

% Late press/release PSTH
type = {'Cue', 'Uncue'};
for i =1:length(type)
    keyword = ['Late' type{i}];
    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_late_presses{i} = PSTHOut.Presses.Time{ind_type};
    [psth_late_presses{i}, ts_late_presses{i}, trialspxmat_late_presses{i}, tspkmat_late_presses{i}, t_late_presses{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_late_presses{i}, params_press);
    psth_late_presses{i} = smoothdata (psth_late_presses{i}, 'gaussian', 5);

    % Upadate late release duration 
    keyword = [type{i}];
    ind_type = strcmp(PSTHOut.Presses.PressDurLabels, keyword);
    late_press_duration{i}  = PSTHOut.Presses.PressDur.Late{ind_type};
    late_press_duration{i} =  late_press_duration{i}(ind);

    keyword = ['Late' type{i}];
    ind_type = strcmp(PSTHOut.Presses.TimeLabels, keyword);
    t_late_releases{i} = PSTHOut.Releases.Time{ind_type};
    [psth_late_releases{i}, ts_late_releases{i}, trialspxmat_late_releases{i}, tspkmat_late_releases{i}, t_late_releases{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_late_releases{i}, params_release);
    psth_late_releases{i} = smoothdata (psth_late_releases{i}, 'gaussian', 5);

    keyword = [type{i}];
    ind_type = strcmp(PSTHOut.Presses.PressDurLabels, keyword);
    late_release_duration{i}  = PSTHOut.Releases.PressDur.Late{ind_type};
    late_release_duration{i} =  late_release_duration{i}(ind);

end
PSTH.LateLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'PressDuration'};
PSTH.LatePresses        =    {psth_late_presses, ts_late_presses, trialspxmat_late_presses, tspkmat_late_presses,   t_late_presses, late_press_duration};
PSTH.LateReleases      =    {psth_late_releases, ts_late_releases, trialspxmat_late_releases, tspkmat_late_releases, t_late_releases, late_release_duration};

% Trigger PSTH
params_trigger.pre = TriggerTimeDomain(1);
params_trigger.post = TriggerTimeDomain(2);
params_trigger.binwidth    =              20;
% For Kornblum paradigm, we only care about correct and late responss
t_triggers              =       PSTHOut.Triggers.Time;
RT_triggers          =       PSTHOut.Triggers.RT;

% correct response
ind_correct = strcmp(PSTHOut.Triggers.Outcome, 'Correct');
t_triggers_correct = t_triggers(ind_correct);
RT_triggers_correct = RT_triggers(ind_correct);

[psth_correct_trigger, ts_correct_trigger, trialspxmat_correct_trigger, tspkmat_correct_trigger, t_triggers_correct,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_triggers_correct, params_trigger);
psth_correct_trigger = smoothdata (psth_correct_trigger, 'gaussian', 5);
RT_triggers_correct =RT_triggers_correct(ind);
PSTH.TriggerLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT'};
PSTH.Trigger            = {psth_correct_trigger, ts_correct_trigger, trialspxmat_correct_trigger,...
    tspkmat_correct_trigger, t_triggers_correct, RT_triggers_correct};

% late response
ind_late = strcmp(PSTHOut.Triggers.Outcome, 'Late');
t_triggers_late = t_triggers(ind_late);
RT_triggers_late = RT_triggers(ind_late);
[psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger, tspkmat_late_trigger, t_triggers_late,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_triggers_late, params_trigger);
psth_late_trigger = smoothdata (psth_late_trigger, 'gaussian', 5);
RT_triggers_late =RT_triggers_late(ind);
PSTH.LateTrigger  = {psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger,...
    tspkmat_late_trigger, t_triggers_late, RT_triggers_late};

% Poke PSTH
params_poke.pre = RewardTimeDomain(1);
params_poke.post = RewardTimeDomain(2);
params_poke.binwidth    =              20;

type = {'Cue', 'Uncue'};
t_reward_pokes = [];
movement_time_reward_pokes = [];
for i =1:length(type)
    keyword=type{i};
    ind_type = strcmp(PSTHOut.Pokes.RewardPoke.Type, keyword);
    t_reward_pokes{i} = PSTHOut.Pokes.RewardPoke.Time{ind_type};
    movement_time_reward_pokes{i} = PSTHOut.Pokes.RewardPoke.Move_Time{ind_type};
    [psth_reward_pokes{i}, ts_reward_pokes{i}, trialspxmat_reward_pokes{i}, tspkmat_reward_pokes{i},...
        t_reward_pokes{i}, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings, t_reward_pokes{i}, params_poke);
    psth_reward_pokes{i} = smoothdata (psth_reward_pokes{i}, 'gaussian', 5);
    movement_time_reward_pokes{i} = movement_time_reward_pokes{i}(ind);
end

PSTH.RewardPokes =  {psth_reward_pokes, ts_reward_pokes, trialspxmat_reward_pokes,...
    tspkmat_reward_pokes, t_reward_pokes, movement_time_reward_pokes};
PSTH.PokeLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'MoveTime'};

% bad poke PSTH
t_nonreward_pokes       =           PSTHOut.Pokes.NonrewardPoke.Time;
movement_time_nonreward_pokes  =           PSTHOut.Pokes.NonrewardPoke.Move_Time;
[psth_nonreward_pokes, ts_nonreward_pokes, trialspxmat_nonreward_pokes, tspkmat_nonreward_pokes,...
    t_nonreward_pokes, ind]              =    Spikes.jpsth(r.Units.SpikeTimes(ku).timings, t_nonreward_pokes, params_poke);
psth_nonreward_pokes                     =     smoothdata (psth_nonreward_pokes, 'gaussian', 5);
movement_time_nonreward_pokes                      =     movement_time_nonreward_pokes(ind);
PSTH.NonrewardPokes =  {psth_nonreward_pokes, ts_nonreward_pokes,...
    trialspxmat_nonreward_pokes, tspkmat_nonreward_pokes, t_nonreward_pokes, movement_time_nonreward_pokes};

%% Plot raster and spks
hf=27;
figure(hf); clf(hf)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')
% PSTH of correct trials
yshift_row1 = 1.4;
ha_press_psth =  axes('unit', 'centimeters', 'position', [1.25 yshift_row1 6 2] ...
    , 'nextplot', 'add', 'xlim', [-PressTimeDomain(1)-25 PressTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;
 for i =1:nTypes
    if i ==2
        line_style = '-.';
    else
        line_style='-';
    end
    hplot_press(i) = plot(ts_press{i}, psth_presses_correct{i}, 'color', FP_cols(i, :),...
        'linewidth', 1.5, 'linestyle', line_style);
    FRMax = max([max(psth_presses_correct{i})]);
end;
hline_press = line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);

axis 'auto y'
xlabel('Time from press (ms)')
ylabel ('Spks per s')

% PSTH of error trials (premature and late)
ha_press_psth_error =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2 6 2], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'xticklabel', []);
yshift_row3 = yshift_row2 +2+0.25;
% plot premature and late as well
for i =1:nTypes
    if i ==2
        line_style = '-.';
    else
        line_style='-';
    end
    if  size(trialspxmat_premature_presses{i}, 2)>3
        plot(ts_premature_presses{i}, psth_premature_presses{i}, 'color', premature_col,...
            'linewidth',1.5,'linestyle', line_style);
    end;
    if  size(trialspxmat_late_presses{i}, 2)>3
        plot(ts_late_presses{i}, psth_late_presses{i}, 'color', late_col, 'linewidth', 1.5 ,'linestyle', line_style)
    end;
end;

axis 'auto y'
hline_press_error = line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);

% make raster plot  750 ms FP
if num2str(length(t_presses))>200
    rasterheight = 0.01;
elseif num2str(length(t_presses))>100
    rasterheight = 0.02;
else
    rasterheight = 0.04;
end

% Plot spike raster of correct trials (Cue and Uncue)
ntrials_press = 0;
n_press_types = zeros(1, nTypes);
t_portin =  PSTHOut.Pokes.Time;
for i =1:nTypes
    n_press_types(i) = size(trialspxmat_press{i}, 2);
    ntrials_press = ntrials_press + n_press_types(i);
end;
axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'ylim', [-ntrials_press-2 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nTypes
    ap_mat = trialspxmat_press{m};
    t_mat = tspkmat_press{m};
    rt = rt_presses_sorted{m};
    for i =1:n_press_types(m)
        irt = rt(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        xxrt = irt+FPKornblum;
        if m == 1 % cue trials
            plotshaded([0 FPKornblum],[-k -k; 1-k 1-k], trigger_col);
        end;
        if  isempty(find(isnan(ap_mat(:, i)), 1))
            if ~isempty(xx)
                line([xx; xx], yy1, 'color', FP_cols(m, :), 'linewidth', 1);
            end;
            line([xxrt; xxrt], yy2, 'color', release_col, 'linewidth', 1.5);
        end;
        % port access time
        itpress =t_presses_correct{m}(i);
        i_portin = t_portin - itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
        if ~isempty(i_portin)
            scatter(i_portin, 0.4-k, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
        end
        k = k+1;
    end;
     k = k+2;
end;
 
line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
title(['Correct'], 'fontsize', 7, 'fontweight','bold');
axis off

% Premature press raster plot
ntrial_premature = 0;
n_press_types = zeros(1, nTypes);
 for i =1:nTypes
    n_press_types(i) = size(trialspxmat_premature_presses{i}, 2);
    ntrial_premature = ntrial_premature + n_press_types(i);
end;
 
axes('unit', 'centimeters', 'position', [1.25 yshift_row4 6 ntrial_premature*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'ylim', [-ntrial_premature-2 1], 'box', 'on');
yshift_row5    =      yshift_row4 + 0.5 + ntrial_premature*rasterheight;

k=0;
for m =1:nTypes
    ap_mat = trialspxmat_premature_presses{m};
    t_mat = tspkmat_premature_presses{m};
    pressdur = premature_press_duration{m};

    for i =1:n_press_types(m)
        idur = pressdur(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;

        if m == 1 % cue trials
            plotshaded([0 FPKornblum],[-k -k; 1-k 1-k], trigger_col);
        end;

        if  isempty(find(isnan(ap_mat(:, i)), 1))
            if ~isempty(xx)
                line([xx; xx], yy1, 'color', premature_col, 'linewidth', 1);
            end;
            line([idur; idur], yy2, 'color', release_col, 'linewidth', 1.5);
        end;
        % port access time
        itpress =t_premature_presses{m}(i);
        i_portin = t_portin - itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
        if ~isempty(i_portin)
            scatter(i_portin, 0.4-k, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
        end
        k = k+1;
    end;
     k = k+2;
end;
 
line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
title(['Premature'], 'fontsize', 7, 'fontweight','bold');
axis off

% Late press raster plot
ntrial_late = 0;
n_press_types = zeros(1, nTypes);
 for i =1:nTypes
    n_press_types(i) = size(trialspxmat_late_presses{i}, 2);
    ntrial_late = ntrial_late + n_press_types(i);
end;
 
axes('unit', 'centimeters', 'position', [1.25 yshift_row5 6 ntrial_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'ylim', [-ntrial_late-2 1], 'box', 'on');
yshift_row6    =      yshift_row5 + 0.5 + ntrial_late*rasterheight;

k=0;
for m =1:nTypes
    ap_mat = trialspxmat_late_presses{m};
    t_mat = tspkmat_late_presses{m};
    pressdur = late_press_duration{m};
    xx_all = [];
    yy_all = [];
    xxdur_all = [];
    yydur_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:n_press_types(m)
        idur = pressdur(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;

        if m == 1 % cue trials
            plotshaded([0 FPKornblum],[-k -k; 1-k 1-k], trigger_col);
        end

        if isempty(find(isnan(ap_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy1, NaN];
            end
            xxdur_all = [xxdur_all, idur, idur, NaN];
            yydur_all = [yydur_all, yy2, NaN];
        end
        % port access time
        itpress =t_late_presses{m}(i);
        i_portin = t_portin - itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end
        k = k+1;
    end;
    k = k+2;
    line(xx_all, yy_all, 'color', late_col, 'linewidth', 1);
    line(xxdur_all, yydur_all, 'color', release_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end;
 
line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
title(['Late'], 'fontsize', 7, 'fontweight','bold');
axis off

% this is the position of last panel
% Add information
uicontrol('Style','text','Units','centimeters','Position',[0.5 yshift_row6  6 0.5],...
    'string', ['A. Press-related activity'], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

yshift_row7=yshift_row6+0.75;
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
ha_release_psth =  axes('unit', 'centimeters', 'position', [8.25 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1)-25 ReleaseTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;
for i =1:nTypes
    if i ==2
        line_style = '-.';
    else
        line_style='-';
    end
    hplot_release(i) = plot(ts_release{i}, psth_releases_correct{i}, 'color', FP_cols(i, :),...
        'linewidth', 1.5, 'linestyle', line_style);
    FRMax = max([max(psth_releases_correct{i})]);
end;
hline_release = line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);

axis 'auto y'
xlabel('Time from release (ms)')

% error PSTHs
ha_release_psth_error =  axes('unit', 'centimeters', 'position', [8.25 yshift_row2 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'xticklabel',[]);
yshift_row3 = yshift_row2 +2+0.25;
% plot premature and late as well
for i =1:nTypes
    if i ==2
        line_style = '-.';
    else
        line_style='-';
    end
    if  size(trialspxmat_premature_releases{i}, 2)>3
        plot(ts_premature_releases{i}, psth_premature_releases{i}, 'color', premature_col,...
            'linewidth',1.5,'linestyle', line_style);
    end;
    if  size(trialspxmat_late_releases{i}, 2)>3
        plot(ts_late_releases{i}, psth_late_releases{i}, 'color', late_col, 'linewidth', 1.5 ,'linestyle', line_style)
    end;
end;
axis 'auto y'
hline_release_error =line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);

% Make raster plot Correct
ntrials_release = 0;
n_release_types = zeros(1, nTypes);
for i =1:nTypes
    n_release_types(i) = size(trialspxmat_release{i}, 2);
    ntrials_release = ntrials_release + n_release_types(i);
end;
axes('unit', 'centimeters', 'position', [8.25 yshift_row3 width ntrials_release*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1)-25 ReleaseTimeDomain(2)], 'ylim', [-ntrials_release-2 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_release*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nTypes
    ap_mat = trialspxmat_release{m};
    t_mat = tspkmat_release{m};
    rt = rt_releases_sorted{m};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:n_release_types(m)
        irt = rt(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        xxrt = irt+FPKornblum;
        if m == 1 % cue trials
                plotshaded([-irt-FPKornblum -irt], [-k -k; 1-k 1-k], trigger_col);      
        end

        if isempty(find(isnan(ap_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy1, NaN];
            end
            xxrt_all = [xxrt_all, -irt-FPKornblum, -irt-FPKornblum, NaN];
            yyrt_all = [yyrt_all, yy2, NaN];
        end

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
    k = k+2;
    line(xx_all, yy_all, 'color', FP_cols(m, :), 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', press_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end
 
line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
title(['Correct'], 'fontsize', 7, 'fontweight','bold');
axis off

% Premature release 
ntrials_premature_release = 0;
n_premature_release_types = zeros(1, nTypes);
for i =1:nTypes
    n_premature_release_types(i) = size(trialspxmat_premature_releases{i}, 2);
    ntrials_premature_release = ntrials_premature_release +n_premature_release_types(i);
end;

axes('unit', 'centimeters', 'position', [8.25 yshift_row4 width ntrials_premature_release*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1)-25 ReleaseTimeDomain(2)], 'ylim', [-ntrials_premature_release-2 1], 'box', 'on');
yshift_row5 = yshift_row4+ntrials_premature_release*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nTypes
    ap_mat = trialspxmat_premature_releases{m};
    t_mat = tspkmat_premature_releases{m};
    pressdur = premature_release_duration{m};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:n_premature_release_types(m)
        ipressdur = pressdur(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        
        if m == 1 % cue trials
                plotshaded([-ipressdur -ipressdur+FPKornblum], [-k -k; 1-k 1-k], trigger_col);      
        end

        if isempty(find(isnan(ap_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy1, NaN];
            end
            xxrt_all = [xxrt_all, -ipressdur, -ipressdur, NaN];
            yyrt_all = [yyrt_all, yy2, NaN];
        end
        % port access time
        itrelease =t_premature_releases{m}(i);
        i_portin = t_portin - itrelease;
        i_portin = i_portin(i_portin>=-ReleaseTimeDomain(1) & i_portin<=ReleaseTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end
        k = k+1;
    end
    k = k+2;
    line(xx_all, yy_all, 'color', premature_col, 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', press_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end
 
line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
title(['Premature'], 'fontsize', 7, 'fontweight','bold');
axis off

% Late release raster plot
ntrials_late_release = 0;
n_late_release_types = zeros(1, nTypes);
for i =1:nTypes
    n_late_release_types(i) = size(trialspxmat_late_releases{i}, 2);
    ntrials_late_release = ntrials_late_release +n_late_release_types(i);
end;

axes('unit', 'centimeters', 'position', [8.25 yshift_row5 width ntrials_late_release*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1)-25 ReleaseTimeDomain(2)], 'ylim', [-ntrials_late_release-2 1], 'box', 'on');
yshift_row6 = yshift_row5+ntrials_late_release*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nTypes
    ap_mat = trialspxmat_late_releases{m};
    t_mat = tspkmat_late_releases{m};
    pressdur = late_release_duration{m};
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:n_late_release_types(m)
        ipressdur = pressdur(i); % time from foreperiod to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        if m == 1 % cue trials
            plotshaded([-ipressdur -ipressdur+FPKornblum], [-k -k; 1-k 1-k], trigger_col);
        end;
        if isempty(find(isnan(ap_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy1, NaN];
            end
            xxrt_all = [xxrt_all, -ipressdur, -ipressdur, NaN];
            yyrt_all = [yyrt_all, yy2, NaN];
        end
        % port access time
        itrelease =t_late_releases{m}(i);
        i_portin = t_portin - itrelease;
        i_portin = i_portin(i_portin>=-ReleaseTimeDomain(1) & i_portin<=ReleaseTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end
        k = k+1;
    end
    k = k+2;
    line(xx_all, yy_all, 'color', late_col, 'linewidth', 1);
    line(xxrt_all, yyrt_all, 'color', press_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end
 
line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
title(['Late'], 'fontsize', 7, 'fontweight','bold');
axis off

% Add information
uicontrol('Style','text','Units','centimeters','Position',[7.75 yshift_row6 width+1 0.5],...
    'string', ['B. Release-related'], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

%% Reward
col3 = 13;
width = 6*sum(RewardTimeDomain)/sum(PressTimeDomain);
ha_poke =  axes('unit', 'centimeters', 'position', [col3 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-RewardTimeDomain(1)-25 RewardTimeDomain(2)]);
for i =1:nTypes
    if i ==2
        line_style = '-.';
    else
        line_style='-';
    end
    plot(ts_reward_pokes{i}, psth_reward_pokes{i}, 'k', 'linewidth', 1.5, 'linestyle', line_style);
    FRMax = max([max( psth_reward_pokes{i})]);
end;
xlabel('Time from rewarded/nonrewarded poke (ms)')
ylabel ('Spks per s')
axis 'auto y'
hline_poke = line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);

ha_poke_nonreward =  axes('unit', 'centimeters', 'position', [col3 yshift_row2 width 2], 'nextplot', 'add', ...
    'xlim', [-RewardTimeDomain(1)-25 RewardTimeDomain(2)], 'xticklabel', []);
plot(ts_nonreward_pokes, psth_nonreward_pokes, 'color', [0.6 0.6 0.6], 'linewidth', 1.5);
hline_poke_nonreward = line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
% FRMax = max([FRMax max(psth_nonreward_pokes)]);

% Reward raster plot
trialspxmat_reward_pokes_plot=cell(1, length(psth_reward_pokes));
move_time_reward_plot = cell(1, length(psth_reward_pokes));
ntrials_reward_pokes = 0;
n_reward_pokes_types = zeros(1, nTypes);
t_reward_pokes_plot = cell(1, length(psth_reward_pokes));

for i = 1:length(psth_reward_pokes)
    % Raster plot
    if size(trialspxmat_reward_pokes{i}, 2)>50
        plot_ind = sort(randperm(size(trialspxmat_reward_pokes{i}, 2), 50));
        trialspxmat_reward_pokes_plot{i} = trialspxmat_reward_pokes{i}(:, plot_ind);
        move_time_reward_plot{i} =  movement_time_reward_pokes{i}(plot_ind);
        ntrials_reward_pokes = ntrials_reward_pokes + length(plot_ind);
        n_reward_pokes_types(i) = length(plot_ind);
        t_reward_pokes_plot{i} = t_reward_pokes{i}(plot_ind);
    else
        trialspxmat_reward_pokes_plot{i} = trialspxmat_reward_pokes{i};
        move_time_reward_plot{i} =  movement_time_reward_pokes{i}; 
        ntrials_reward_pokes = ntrials_reward_pokes + size(trialspxmat_reward_pokes{i}, 2);
        n_reward_pokes_types(i) = size(trialspxmat_reward_pokes{i}, 2);
        t_reward_pokes_plot{i} =t_reward_pokes{i};
    end
end
 
axes('unit', 'centimeters', 'position', [col3 yshift_row3 width ntrials_reward_pokes*rasterheight],...
    'nextplot', 'add', 'xlim',  [-RewardTimeDomain(1)-25 RewardTimeDomain(2)], ...
    'ylim', [-ntrials_reward_pokes-2 1], 'box', 'on', 'xticklabel', []);
yshift_row4 = yshift_row3 +ntrials_reward_pokes*rasterheight+0.5;

k=0;
for m =1:nTypes
    ap_mat = trialspxmat_reward_pokes_plot{m};
    t_mat = tspkmat_reward_pokes{m};
    move_time = move_time_reward_plot{m};
    xx_all = [];
    yy_all = [];
    xxmt_all = [];
    yymt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:n_reward_pokes_types(m)
        imovetime = move_time(i);
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxmt_all = [xxrt_all, -imovetime, -imovetime, NaN];
        yymt_all = [yyrt_all, yy2, NaN];
        % port access time
        itpoke = t_reward_pokes_plot{m}(i);
        i_portin = t_portin - itpoke;
        i_portin = i_portin(i_portin>=-RewardTimeDomain(1) & i_portin<=RewardTimeDomain(2));
        if ~isempty(i_portin)
            i_portin = reshape(i_portin,1,[]);
            x_portin = [x_portin, i_portin];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end
        k = k+1;
    end
    k = k+2;
    line(xx_all, yy_all, 'color', FP_cols(m, :), 'linewidth', 1);
    line(xxmt_all, yymt_all, 'color', release_col, 'linewidth', 1.5);
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
end
line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1)
axis off
title('Rewarded pokes', 'fontname', 'dejavu sans', 'fontsize', 7)

% Nonreward raster plot
trialspxmat_nonreward_pokes_plot=[];
move_time_nonreward_plot = [];
ntrials_nonreward_pokes = 0;
n_nonreward_pokes_types = 0;
t_nonreward_pokes_plot = [];

if size(trialspxmat_nonreward_pokes, 2)>50
    plot_ind = sort(randperm(size(trialspxmat_nonreward_pokes, 2), 50));
    trialspxmat_nonreward_pokes_plot = trialspxmat_nonreward_pokes(:, plot_ind);
    move_time_nonreward_plot =  movement_time_nonreward_pokes(plot_ind);
    ntrials_nonreward_pokes = ntrials_nonreward_pokes + length(plot_ind);
    t_nonreward_pokes_plot =t_nonreward_pokes(plot_ind);
else
    plot_ind = [1:size(trialspxmat_nonreward_pokes, 2)];
    trialspxmat_nonreward_pokes_plot = trialspxmat_nonreward_pokes(:, plot_ind);
    move_time_nonreward_plot =  movement_time_nonreward_pokes(plot_ind);
    ntrials_nonreward_pokes = ntrials_nonreward_pokes + length(plot_ind);
    t_nonreward_pokes_plot =t_nonreward_pokes(plot_ind);
end;

axes('unit', 'centimeters', 'position', [col3 yshift_row4 width ntrials_nonreward_pokes*rasterheight],...
    'nextplot', 'add', 'xlim',  [-RewardTimeDomain(1)-25 RewardTimeDomain(2)], ...
    'ylim', [-ntrials_nonreward_pokes 1], 'box', 'on', 'xticklabel', []);
yshift_row5 = yshift_row4 +ntrials_nonreward_pokes*rasterheight+1;

k=0;
ap_mat = trialspxmat_nonreward_pokes_plot;
t_mat = tspkmat_nonreward_pokes;
move_time = move_time_nonreward_plot;

xx_all = [];
yy_all = [];
xxmt_all = [];
yymt_all = [];
x_portin = [];
y_portin = [];
for i =1:ntrials_nonreward_pokes
    imovetime = move_time(i);
    xx = t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy2 = [0 1]-k;

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxmt_all = [xxrt_all, -imovetime, -imovetime, NaN];
    yymt_all = [yyrt_all, yy2, NaN];
    % port access time
    itpoke = t_nonreward_pokes_plot(i);
    i_portin = t_portin - itpoke;
    i_portin = i_portin(i_portin>=-RewardTimeDomain(1) & i_portin<=RewardTimeDomain(2));
    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    k = k+1;
end
line(xx_all, yy_all, 'color', [0.6 0.6 0.6], 'linewidth', 1);
line(xxmt_all, yymt_all, 'color', release_col, 'linewidth', 1.5);
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');

line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1)
axis off
title('Non-rewarded pokes', 'fontname', 'dejavu sans', 'fontsize', 7)

% Add information  13.5 3+0.5 6 ntrial4*rasterheight
uicontrol('Style','text','Units','centimeters','Position',[col3-0.5 yshift_row5 5 1.6],...
    'string', ['C. Rewarded/Nonrewarded poke-related activity'], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');

yshift_row6 = yshift_row5+1.8;
%% plot pre-press activity vs trial num or time
ha10=axes('unit', 'centimeters', 'position', [col3 yshift_row6 5 2.5], ...
    'nextplot', 'add', 'xlim', [min(t_presses/1000) max(t_presses/1000)]);
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
yshift_row7 = yshift_row6+3;
% Add information  13.5 3+0.5 6 ntrial4*rasterheight
uicontrol('Style','text','Units','centimeters','Position',[col3-0.5 yshift_row7 4 0.5],...
    'string', ['D.  Activity vs time'], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
fig_height = max([fig_height, yshift_row7+1]);
%% plot trigger-related activity
col4 = 20;
width = 6*sum(TriggerTimeDomain)/sum(PressTimeDomain);

ha_trigger =  axes('unit', 'centimeters', 'position', [col4 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)]);

plot(ts_correct_trigger, psth_correct_trigger, 'color', FP_cols(1, :), 'linewidth', 1.5);
FRMax = max([FRMax max(psth_correct_trigger)]);
plot(ts_late_trigger, psth_late_trigger, 'color', late_col, 'linewidth', 1.5);
line([0 0], get(gca, 'ylim'), 'color', trigger_col, 'linewidth', 1);
xlabel('Time from trigger stimulus (ms)')
ylabel ('Spks per s')
% FRMax = max([FRMax max(psth_late_trigger)]);
xlim = max(get(gca, 'xlim'));
axis 'auto y'

% raster plot of trigger-related activity
ntrials_trigger = length(t_triggers_correct);
axes('unit', 'centimeters', 'position', [col4 yshift_row2 width ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-TriggerTimeDomain(1)-25 TriggerTimeDomain(2)], 'ylim', [-ntrials_trigger 1], 'box', 'on');
yshift_row3 = yshift_row2+ntrials_trigger*rasterheight+0.5;
% Paint the foreperiod
k=0;
ap_mat = trialspxmat_correct_trigger;
t_mat = tspkmat_correct_trigger;
rt = RT_triggers_correct;

xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_portin = [];
y_portin = [];
for i =1:ntrials_trigger
    irt = rt(i); % time from trigger to release
    xx = t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;
    % paint foreperiod
    plotshaded([-FPKornblum 0], [-k -k; 1-k 1-k], trigger_col);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxrt_all = [xxrt_all, irt, irt, NaN];
    yyrt_all = [yyrt_all, yy, NaN];

    % port access time
    it_trigger =t_triggers_correct(i);
    i_portin = t_portin - it_trigger;
    i_portin = i_portin(i_portin>=-TriggerTimeDomain(1) & i_portin<=TriggerTimeDomain(2));

    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    k = k+1;
end
line(xx_all, yy_all, 'color',  FP_cols(1, :), 'linewidth', 1);
line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5);
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');

line([0 0], get(gca, 'ylim'), 'color', trigger_col, 'linewidth', 1);
title(['Correct'], 'fontsize', 7);
axis off

% raster plot of trigger-related activity (late)
ntrials_trigger = length(t_triggers_late);
axes('unit', 'centimeters', 'position', [col4 yshift_row3 width ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-TriggerTimeDomain(1)-25 TriggerTimeDomain(2)], 'ylim', [-ntrials_trigger 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_trigger*rasterheight+0.5;
% Paint the foreperiod
k=0;
ap_mat = trialspxmat_late_trigger;
t_mat = tspkmat_late_trigger;
rt = RT_triggers_late;

xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_portin = [];
y_portin = [];
for i =1:ntrials_trigger
    irt = rt(i); % time from trigger to release
    xx = t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;
    % paint foreperiod
    plotshaded([-FPKornblum 0], [-k -k; 1-k 1-k], trigger_col);
    
    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxrt_all = [xxrt_all, irt, irt, NaN];
    yyrt_all = [yyrt_all, yy, NaN];

    % port access time
    it_trigger =t_triggers_late(i);
    i_portin = t_portin - it_trigger;
    i_portin = i_portin(i_portin>=-TriggerTimeDomain(1) & i_portin<=TriggerTimeDomain(2));

    if ~isempty(i_portin)
        i_portin = reshape(i_portin,1,[]);
        x_portin = [x_portin, i_portin];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    k = k+1;
end
line(xx_all, yy_all, 'color', late_col, 'linewidth', 1);
line(xxrt_all, yyrt_all, 'color', release_col, 'linewidth', 1.5);
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');

line([0 0], get(gca, 'ylim'), 'color', trigger_col, 'linewidth', 1);
if ntrials_trigger>0
    title(['Late'], 'fontsize', 7);
end
axis off

% Add information
uicontrol('Style','text','Units','centimeters','Position',[col4-0.5  yshift_row4 5 1.2],...
    'string', ['E. Trigger-related activity'], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
yshift_row5=yshift_row4+1.2+1.2;

FRMax = max(FRMax, 1);
FRrange = [0 FRMax*1.5];
set(ha_press_psth, 'ylim', FRrange);
line(ha_press_psth, [0 0], FRrange, 'color', press_col, 'linewidth', 1);
set(ha_press_psth_error, 'ylim', FRrange);
line(ha_press_psth_error, [0 0], FRrange, 'color', press_col, 'linewidth', 1);
line(ha_press_psth, [FPKornblum FPKornblum], FRrange, 'color', trigger_col, 'linewidth', 1);
set(ha_release_psth, 'ylim', FRrange);
line(ha_release_psth, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_release_psth_error, 'ylim', FRrange);
line(ha_release_psth_error, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_poke, 'ylim', FRrange);
line(ha_poke, [0 0], FRrange, 'color', reward_col, 'linewidth', 1);
set(ha_poke_nonreward, 'ylim', FRrange);
line(ha_poke_nonreward, [0 0], FRrange, 'color', reward_col, 'linewidth', 1);
set(ha_trigger, 'ylim', FRrange);
line(ha_trigger, [0 0], FRrange, 'color', trigger_col, 'linewidth', 1);

f=get(ha_press_psth,'Children');
legend([f(4),f(5)],'Uncue','Cue', 'Box', 'off', 'Location', 'best')


%% plot spks
  col5=19.5;
    thiscolor = [0 0 0];
    Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
    ha0=axes('unit', 'centimeters', 'position', [col5 yshift_row5 1.5 1.5], ...
        'nextplot', 'add', 'xlim', [0 Lspk], 'xticklabel', []);

    set(ha0, 'nextplot', 'add');
    ylabel('uV')
    allwaves = r.Units.SpikeTimes(ku).wave/4;
    if size(allwaves, 1)>100
        nplot = randperm(size(allwaves, 1), 100);
    else
        nplot=[1:size(allwaves, 1)];
    end;    
    wave2plot = allwaves(nplot, :);
    plot([1:Lspk], wave2plot, 'color', [0.8 .8 0.8]);
    plot([1:Lspk], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
    axis([0 Lspk min(wave2plot(:)) max(wave2plot(:))])
    axis tight
    PSTH.SpikeWave = mean(allwaves, 1);    
    % plot autocorrelation
    kutime = round(r.Units.SpikeTimes(ku).timings);
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime)=1;
    [c, lags] = xcorr(kutime2, 100); % max lag 100 ms
    c(lags==0)=0;
    
    ha00= axes('unit', 'centimeters', 'position', [19.5+1.5+1 yshift_row5 2 1.5], 'nextplot', 'add', 'xlim', [-25 25]);
    if median(c)>1
        set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 median(c)]);
    else
        set(ha00, 'nextplot', 'add', 'xtick', [-50:10:50], 'ytick', [0 1], 'ylim', [0 1]);
    end;
    
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

    % Plot all waveforms if it is a polytrode
    if isfield(r.Units.SpikeTimes(ku), 'wave_mean')
        yshift_row6 = yshift_row5+2;
        ha_wave_poly = axes('unit', 'centimeters', 'position', [col5 yshift_row6 4 3], 'nextplot', 'add');
        wave_form = r.Units.SpikeTimes(ku).wave_mean/4;
        PSTH.SpikeWaveMean = wave_form;
        n_chs = size(wave_form, 1); % number of channels
        ch_selected = 1:n_chs;
        if n_chs > 32
            ch_largest = r.Units.SpikeNotes(ku,1);
            n_chs = 32;
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
    end;
    
    uicontrol('Style','text','Units','centimeters','Position',[19 yshift_row7 5 1.5],...
        'string', ['F. Spike waveform and autocorrelation'], ...
        'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
        'HorizontalAlignment','Left');    
    fig_height = max([fig_height, yshift_row7+2]);    
    % change the height of the figure    
    set(hf, 'position', [2 2 25 fig_height])
    toc;

    % save to a folder
    anm_name        =     r.BehaviorClass.Subject;
    session              =     r.BehaviorClass.Date;

    PSTH.ANM_Session = {anm_name, session};
    thisFolder = fullfile(pwd, 'Fig');
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    tosavename2= fullfile(thisFolder, [anm_name '_' session '_Ch'  num2str(ch) '_Unit' num2str(unit_no) ]);
    print (gcf,'-dpng', tosavename2)

    % save PSTH as well save(psth_new_name, 'PSTHOut');
    save([tosavename2 '.mat'], 'PSTH')

    try
        tic
        % C:\Users\jiani\OneDrive\00_Work\03_Projects
        thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'UnitsCollection', anm_name, session);
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
        copyfile([tosavename2 '.png'], thisFolder)
        copyfile([tosavename2 '.mat'], thisFolder)

        toc
    end