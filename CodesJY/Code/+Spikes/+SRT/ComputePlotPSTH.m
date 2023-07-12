function PSTH = ComputePlotPSTH(r, PSTHOut, ku, varargin)

% Jianing Yu 5/8/2023
% For plotting PSTHs under SRT condition.
% Extracted from SRTSpikes

% Modified by Yue Huang on 6/26/2023
% Change the way of making raster plots to run faster

close all;
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
reward_col = [164, 208, 164]/255;
MixedFPs = PSTHOut.Presses.FP{1};
nFPs = length(MixedFPs);
if nFPs == 2
    FP_cols = [192, 127, 0; 76, 61, 61]/255;
else
    FP_cols = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;
end
premature_col = [0.9 0.4 0.1];
late_col = [0.6 0.6 0.6];
printsize = [2 2 25 25];

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
PSTH.PrematureLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDuration', 'FP'};


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
t_late_presses                 =         PSTHOut.Presses.Time{nFPs+2};
[psth_late_press, ts_late_press, trialspxmat_late_press, tspkmat_late_press,...
    t_late_presses, ind]        =           Spikes.jpsth(r.Units.SpikeTimes(ku).timings, ...
    t_late_presses, params_press);
psth_late_press                =             smoothdata (psth_late_press, 'gaussian', 5);
FPs_late_presses            =              PSTHOut.Presses.FP{3};
FPs_late_presses             =             FPs_late_presses(ind);
late_duration_presses      =             PSTHOut.Presses.PressDur.Late;
late_duration_presses      =             late_duration_presses(ind);
PSTH.LatePresses = {psth_late_press, ts_late_press, trialspxmat_late_press,...
    tspkmat_late_press, t_late_presses,late_duration_presses,FPs_late_presses};
PSTH.LateLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDuration', 'FP'};

% late release PSTH
t_late_releases                 =         PSTHOut.Releases.Time{nFPs+2};
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
t_triggers_late = PSTHOut.Triggers.Time{nFPs+1};
RT_triggers_late = PSTHOut.Triggers.RT{nFPs+1};
FP_triggers_late = PSTHOut.Triggers.FP{end};
[psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger, tspkmat_late_trigger, t_triggers_late,...
    ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_triggers_late, params);
RT_triggers_late = RT_triggers_late(ind);
FP_triggers_late=FP_triggers_late(ind);
psth_late_trigger = smoothdata (psth_late_trigger, 'gaussian', 5);
PSTH.TriggersLate =  {psth_late_trigger, ts_late_trigger, trialspxmat_late_trigger,...
    tspkmat_late_trigger, t_triggers_late, RT_triggers_late, FP_triggers_late};
PSTH.TriggerLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'RT', 'FP'};
for i =1:nFPs
    t_triggers_correct{i} = PSTHOut.Triggers.Time{i};
    RT_triggers_correct{i} = PSTHOut.Triggers.RT{i};
    [psth_trigger_correct{i}, ts_trigger_correct{i}, trialspxmat_trigger_correct{i}, tspkmat_trigger_correct{i}, t_triggers_correct{i},...
        ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_triggers_correct{i}, params);
    RT_triggers_correct{i} = RT_triggers_correct{i}(ind);
    psth_trigger_correct{i} = smoothdata (psth_trigger_correct{i}, 'gaussian', 5);
    PSTH.Triggers{i} =  {psth_trigger_correct{i}, ts_trigger_correct{i}, trialspxmat_trigger_correct{i},...
        tspkmat_trigger_correct{i}, t_triggers_correct{i}, RT_triggers_correct{i}, MixedFPs(i)};
end

%% Plot raster and spks
hf=27;
figure(hf); clf(hf)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')
% PSTH of correct trials
yshift_row1 = 1;
ha_press_psth =  axes('unit', 'centimeters', 'position', [1.25 yshift_row1 6 2], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;
hplot_press= zeros(1, nFPs);
FRMax = 10;
for i =1:nFPs
    hplot_press(i) = plot(ts_press{i}, psth_presses_correct{i}, 'color', FP_cols(i, :),  'linewidth', 1.5);
    FRMax = max([FRMax max(psth_presses_correct{i})]);
%     disp(FRMax)
end
axis 'auto y'
xlabel('Time from press (ms)')
ylabel ('Spks per s')

% PSTH of error trials (premature and late)
ha_press_psth_error =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2 6 2], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1) PressTimeDomain(2)], 'xticklabel', []);
yshift_row3 = yshift_row2 +2+0.25;
% plot premature and late as well
if  size(trialspxmat_premature_press, 2)>3
    plot(ts_premature_press, psth_premature_press, 'color', premature_col, 'linewidth',1.5);
    FRMax = max([FRMax max(psth_premature_press)]);
%      disp(FRMax)
end
if  size(trialspxmat_late_press, 2)>3
    plot(ts_late_press, psth_late_press, 'color', late_col, 'linewidth', 1.5)
    FRMax = max([FRMax max(psth_late_press)]);
%     disp(FRMax)
end
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

% Plot spike raster of correct trials (all FPs)
ntrials_press = 0;
nFP_i = zeros(1, nFPs);
t_portin =  PSTHOut.Pokes.Time;
for i =1:nFPs
    nFP_i(i) = size(trialspxmat_press{i}, 2);
    ntrials_press = ntrials_press + nFP_i(i);
end
axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
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
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy2 = [0 1]-k;
        xxrt = irt+MixedFPs(m);
        plotshaded([0 MixedFPs(m)],[-k -k; 1-k 1-k], trigger_col);

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
axes('unit', 'centimeters', 'position', [1.25 yshift_row4 6 ntrial_premature*rasterheight],...
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
    % plot trigger stimulus FPs_premature_presses
    itrigger = FPs_premature_presses(i);
    plotshaded([0 itrigger], [-k -k; 1-k 1-k], trigger_col);

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
axes('unit', 'centimeters', 'position', [1.25 yshift_row5  6 ntrial_late*rasterheight],...
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
    % plot trigger stimulus FPs_premature_presses
    itrigger = FPs_late_presses(i);
    plotshaded([0 itrigger], [-k -k; 1-k 1-k], trigger_col);

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

% this is the position of last panel
% Add information
uicontrol('Style','text','Units','centimeters','Position',[0.5 yshift_row6  6 1],...
    'string', 'A. Press-related activity', ...
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
yshift_row1 = 1;
ha_release_psth =  axes('unit', 'centimeters', 'position', [8.25 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)]);
yshift_row2 = yshift_row1+2+0.25;

for i =1:nFPs
    hplot_release(i) = plot(ts_release{i}, psth_release_correct{i}, 'color', FP_cols(i, :),  'linewidth', 1.5);
    FRMax = max([FRMax max(psth_release_correct{i})]);
%     disp(FRMax)
end
axis 'auto y'
hline_release = line([0 0], get(gca, 'ylim'), 'color', press_col, 'linewidth', 1);
xlabel('Time from release (ms)')
ylabel ('Spks per s')

% error PSTHs
ha_release_psth_error =  axes('unit', 'centimeters', 'position', [8.25 yshift_row2 width 2], 'nextplot', 'add', ...
    'xlim', [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)], 'xticklabel',[]);
yshift_row3 = yshift_row2 +2+0.25;
if  size(trialspxmat_premature_release, 2)>3
    plot(ts_premature_release, psth_premature_release, 'color', premature_col, 'linewidth', 1.5)
    FRMax = max([FRMax max(psth_premature_release)]);
%     disp(FRMax)
end
if  size(trialspxmat_late_release, 2)>3
    plot(ts_late_release, psth_late_release, 'color', late_col, 'linewidth', 1.5)
    FRMax = max([FRMax max(psth_late_release)]);
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

axes('unit', 'centimeters', 'position', [8.25 yshift_row3 width ntrials_release*rasterheight],...
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
    mFP = MixedFPs(m);
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:nFP_i(m)
        irt = rt(i); % time from foreperiod to release
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
axes('unit', 'centimeters', 'position', [8.25 yshift_row4 width ntrial_premature*rasterheight],...
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
    iFP = FPs_premature_releases(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;

    x_predur_all = [x_predur_all, -ipredur, -ipredur, NaN];
    y_predur_all = [y_predur_all, yy, NaN];

    % paint foreperiod
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
axes('unit', 'centimeters', 'position', [8.25 yshift_row5  width ntrial_late*rasterheight],...
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
    iFP = FPs_late_releases(i);
    xx =  t_mat(ap_mat(:, i)==1);
    yy1 = [0 0.8]-k;
    yy = [0 1]-k;
    % paint foreperiod
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
uicontrol('Style','text','Units','centimeters','Position',[7.75 yshift_row6 width+1 1],...
    'string', 'B. Release-related', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

%% Reward
col3 = 13;
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
hline_poke = line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
FRMax = max([FRMax max(psth_nonreward_pokes)]);
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
    mFP = MixedFPs(m);
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
    line(x_move_all, y_move_all, 'color', release_col, 'linewidth', 1)
    scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
line([0 0], get(gca, 'ylim'), 'color', release_col, 'linewidth', 1);
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
line(x_move_all, y_move_all, 'color', release_col, 'linewidth', 1)
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1)
axis off
title('Nonrewarded pokes', 'fontname', 'dejavu sans', 'fontsize', 7)

% Add information  13.5 3+0.5 6 ntrial4*rasterheight
uicontrol('Style','text','Units','centimeters','Position',[col3-0.5 yshift_row4new 5 1.75],...
    'string', 'C. Rewarded/Nonrewarded poke-related activity', ...
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
    'string', 'D.  Activity vs time', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');

fig_height = max([fig_height, yshift_row6new+1]);

%% plot trigger-related activity
col4 = 20;
width = 6*sum(TriggerTimeDomain)/sum(PressTimeDomain);

ha_trigger =  axes('unit', 'centimeters', 'position', [col4 yshift_row1 width 2], 'nextplot', 'add', ...
    'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)]);
for i=1:nFPs
    plot(ts_trigger_correct{i}, psth_trigger_correct{i}, 'color', FP_cols(i, :), 'linewidth', 1.5);
    FRMax = max([FRMax max(psth_trigger_correct{i})]);
%     disp(FRMax)
end
plot(ts_late_trigger, psth_late_trigger, 'color', late_col, 'linewidth', 1.5)
xlabel('Time from trigger stimulus (ms)')
ylabel ('Spks per s')

FRMax = max([FRMax max(psth_late_trigger)]);
% disp(FRMax)
xlim = max(get(gca, 'xlim'));
axis 'auto y'

% raster plot of trigger-related activity
ntrials_trigger = 0;
nFP_i = zeros(1, nFPs);
for i =1:nFPs
    nFP_i(i) = size(trialspxmat_trigger_correct{i}, 2);
    ntrials_trigger = ntrials_trigger + nFP_i(i);
end

axes('unit', 'centimeters', 'position', [col4 yshift_row2 width ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'ylim', [-ntrials_trigger 1], 'box', 'on');
yshift_row3 = yshift_row2+ntrials_trigger*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nFPs
    ap_mat = trialspxmat_trigger_correct{m};
    t_mat = tspkmat_trigger_correct{m};
    rt = RT_triggers_correct{m};
    mFP = MixedFPs(m);
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:nFP_i(m)
        irt = rt(i); % time from trigger to release
        xx = t_mat(ap_mat(:, i)==1);
        yy1 = [0 0.8]-k;
        yy = [0 1]-k;
        % paint foreperiod
        plotshaded([-mFP 0], [-k -k; 1-k 1-k], trigger_col);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end 

        % plot release time
        xxrt_all = [xxrt_all, irt, irt, NaN];
        yyrt_all = [yyrt_all, yy, NaN];

        % port access time
        it_trigger =t_triggers_correct{m}(i);
        i_portin = t_portin - it_trigger;
        i_portin = i_portin(i_portin>=-TriggerTimeDomain(1) & i_portin<=TriggerTimeDomain(2));
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
line([0 0], get(gca, 'ylim'), 'color', trigger_col, 'linewidth', 1);
title('Correct', 'fontsize', 7);
axis off

% trigger following late FP
ntrials_trigger_late = size(trialspxmat_late_trigger, 2);
axes('unit', 'centimeters', 'position', [col4 yshift_row3 width ntrials_trigger_late*rasterheight],...
    'nextplot', 'add', 'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'ylim', [-ntrials_trigger_late 1], ...
    'box', 'on', 'xticklabel', []);
yshift_row4 = yshift_row3+ntrials_trigger_late*rasterheight+0.5;
k =0;
xx_all = [];
yy_all = [];
xxrt_all = [];
yyrt_all = [];
x_portin = [];
y_portin = [];
for i =1:ntrials_trigger_late
    xx =  tspkmat_late_trigger(trialspxmat_late_trigger(:, i)==1);
    iFP = FP_triggers_late(i);
    yy1 = [0 0.8]-k;
    yy2 = [0 1]-k;
    % paint foreperiod
    plotshaded([-iFP 0], [-k -k; 1-k 1-k], trigger_col);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end 

    % plot release time
    irt = RT_triggers_late(i);
    xxrt_all = [xxrt_all, irt, irt, NaN];
    yyrt_all = [yyrt_all, yy2, NaN];
    % plot port poke time
    itrigger = t_triggers_late(i);
    i_portin = t_portin-itrigger;
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
scatter(x_portin, y_portin, 8, 'o', 'filled','MarkerFaceColor', reward_col,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')

line([0 0], get(gca, 'ylim'), 'color',trigger_col, 'linewidth', 1)
title('late', 'fontname', 'dejavu sans', 'fontsize', 7)
axis off

% Add information
uicontrol('Style','text','Units','centimeters','Position',[col4-0.5  yshift_row4 5 1.2],...
    'string', 'E. Trigger-related activity', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
yshift_row5=yshift_row4+1.2+1.2;

FRrange = [0 FRMax*1.1];
set(ha_press_psth, 'ylim', FRrange);
line(ha_press_psth, [0 0], FRrange, 'color', press_col, 'linewidth', 1);

line(ha_press_psth, [MixedFPs(1) MixedFPs(1)], get(gca, 'ylim'), 'color', trigger_col, 'linestyle', ':', 'linewidth', 1);
line(ha_press_psth, [MixedFPs(2) MixedFPs(2)], get(gca, 'ylim'), 'color', trigger_col, 'linestyle', ':', 'linewidth', 1);

set(ha_press_psth_error, 'ylim', FRrange);
line(ha_press_psth_error, [0 0], FRrange, 'color', press_col, 'linewidth', 1);
line(ha_press_psth, [MixedFPs; MixedFPs], FRrange, 'color', trigger_col, 'linewidth', 1);
set(ha_release_psth, 'ylim', FRrange);
line(ha_release_psth, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_release_psth_error, 'ylim', FRrange);
line(ha_release_psth_error, [0 0], FRrange, 'color', release_col, 'linewidth', 1);
set(ha_poke, 'ylim', FRrange);
line(ha_poke, [0 0], FRrange, 'color', reward_col, 'linewidth', 1);
set(ha_trigger, 'ylim', FRrange);
line(ha_trigger, [0 0], FRrange, 'color', trigger_col, 'linewidth', 1);


%% plot spks
col5=19.5;
thiscolor = [0 0 0];
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
% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);
kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;
[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;

ha00= axes('unit', 'centimeters', 'position', [19.5+1.5+1 yshift_row5 2 1.5], 'nextplot', 'add', 'xlim', [-25 25]);
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
    for i =1:n_rows
        for j=1:n_cols
            k = j+(i-1)*n_cols;
            wave_k = wave_form(k, :)+v_sep*(i-1);
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

uicontrol('Style','text','Units','centimeters','Position',[19 yshift_row7 5 1.5],...
    'string', 'F. Spike waveform and autocorrelation', ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],'ForegroundColor', 'k', ...
    'HorizontalAlignment','Left');
fig_height = max([fig_height, yshift_row7+2]);
% change the height of the figure
set(hf, 'position', [2 2 25 fig_height])
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
    tosavename2= fullfile(thisFolder, [anm_name '_' session '_Ch'  num2str(ch) '_Unit' num2str(unit_no) ]);
    print (gcf,'-dpng', tosavename2)
    
    % save PSTH as well save(psth_new_name, 'PSTHOut');
    save([tosavename2 '.mat'], 'PSTH')
    
    try
        tic
        % C:\Users\jiani\OneDrive\00_Work\03_Projects
        thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'UnitsCollection', anm_name, session);
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
        copyfile([tosavename2 '.png'], thisFolder)
        copyfile([tosavename2 '.mat'], thisFolder)
    
        toc
    end
end