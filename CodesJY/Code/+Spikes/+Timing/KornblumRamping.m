function PSTHOut = KornblumRamping(r, ind, varargin)

% Jianing Yu 10/7/2022

% Test if spikes ramps to a level before release occurs
% Similar analysis to Murakami 2014
% Only look at activity related to press. 
% Group spike train based on reaction time

% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port. 
% V5: add poke events following an unsuccesful release
% SRTSpikesTimeProduction: Kornblum style

% 8/9/2022
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% 4/19/2023

if length(ind) ==2
    ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
    ind = ind_unit;
end;
    
tic
 
min_dur = 100; % any press lasting shorter than this will be removed. 
max_win = 2000;

printname = [];
printsize = [2 2 21 16];
tosave =1;
PressTimeDomain = [1000 3000];
ReleaseTimeDomain = [1000 1000];
electrode_type = 'Ch';
rasterheight = 0.02;
colmp = 'fake_parula';
rmax = 0.9;
compute_range = []; % this the the time range in which the PSTH is computed. Data outside of this range will not be included. 
combined_cue_uncue = 0; % whether we should combine cue and uncue trials. 
% Some rats show no faster reaciton on cue trials and seem to depend on self-timing entirely. We should combined data from both trials. 
params_press.pre            =              PressTimeDomain(1);
params_press.post           =              PressTimeDomain(2);
params_press.binwidth     =              20;
params_release.pre            =             ReleaseTimeDomain(1);
params_release.post           =             ReleaseTimeDomain(2);
params_release.binwidth     =              20;
kernelwidth = 50;

 % derive PSTH from these
ku = ind;
 
if ku>length(r.Units.SpikeTimes)
    display('##########################################')
    display('########### That is all you have ##############')
    display('##########################################')
    return
end;

Ndiv = 5;
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'Division'
                Ndiv = varargin{i+1};
            case 'Colormap'
                colmp = varargin{i+1}; % PSTH time domain
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1};
            case 'ComputeTimeRange'      % added 2023 so that we don't include data after dreadd in some cases.
                compute_range =  varargin{i+1};
                if max(compute_range)<10000
                    compute_range = 1000*compute_range; % convert to ms
                end;
            case 'CombinedCueUncue'
                combined_cue_uncue = varargin{i+1};
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
 
fig_handle1 = 8;
figure(fig_handle1); clf
ha = axes('nextplot', 'add', 'xlim', [0.5 3.5], 'xtick', [1:3], 'xticklabel', {'Cued', 'Uncued', 'Dark'});
bar(1, length(t_presses_cue), 'FaceColor', 'k')
bar(2, length(t_presses_uncue), 'FaceColor', 'b')
bar(3, length(t_presses_dark), 'FaceColor', [0.7 0.7 0.7])
 
ylabel('Number of presses')

% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 % press for cue and uncue trials
t_releases_cue           =       t_releases(ind_cue);
t_releases_uncue       =       t_releases(ind_uncue);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);
t_rewards_cue = [];
t_rewards_uncue = [];

% check which reward is produced by cue vs uncue trials (there might be a difference)
for i =1:length(t_rewards)
    most_recent_cue = t_releases_cue(find(t_releases_cue-t_rewards(i)<0, 1, 'last'));
    most_recent_uncue = t_releases_uncue(find(t_releases_uncue-t_rewards(i)<0, 1, 'last'));
    if ~isempty(most_recent_cue) && ~isempty(most_recent_uncue)
        if most_recent_cue > most_recent_uncue
            t_rewards_cue = [t_rewards_cue t_rewards(i)];
        else
            t_rewards_uncue = [t_rewards_uncue t_rewards(i)];
        end;
    end;
end;

% index and time of correct presses
FP_Kornblum = median(rb.Foreperiods); % This is the foreperiod of this session
max_dur = max_win +FP_Kornblum;

if size(rb.Foreperiods, 1) == 1
    diff_FP = [0 (diff(rb.Foreperiods)==0)];
else
     diff_FP = [0; (diff(rb.Foreperiods)==0)];   
end;

ind_advanced = find(diff_FP & rb.Foreperiods==FP_Kornblum); % advanced stage. We only analyze those
ind_press_counted = intersect(ind_advanced, [reshape(rb.CorrectIndex, 1, []) reshape(rb.PrematureIndex, 1, []) reshape(rb.LateIndex, 1, [])]);

t_presses_counted                       =       t_presses(ind_press_counted); % also takes premature presses
[t_presses_counted_cue]             =       intersect(t_presses_counted, t_presses_cue);
[t_presses_counted_uncue]         =       intersect(t_presses_counted, t_presses_uncue);

% index and time of correct releases
t_releases_counted                  =       t_releases(ind_press_counted); 
t_releases_counted_cue           =      intersect(t_releases_counted, t_releases_cue);
t_releases_counted_uncue       =      intersect(t_releases_counted, t_releases_uncue);

if combined_cue_uncue
    t_presses_counted = [t_presses_counted_cue; t_presses_counted_uncue];
    t_releases_counted = [t_releases_counted_cue; t_releases_counted_uncue];
else
    t_presses_counted = [ t_presses_counted_uncue];
    t_releases_counted = [ t_releases_counted_uncue];
end;

durs = t_releases_counted - t_presses_counted;
t_releases_counted = t_releases_counted(durs>min_dur & durs<max_dur);
t_presses_counted = t_presses_counted(durs>min_dur & durs<max_dur);

% compute reaction time
rt_counted = t_releases_counted - t_presses_counted - FP_Kornblum;
% check if any data need to be excluded
if ~isempty(compute_range)
    ind_include = find(t_presses_counted >= compute_range(1) & t_presses_counted <= compute_range(2));
    t_presses_counted = t_presses_counted(ind_include);
    t_releases_counted = t_releases_counted(ind_include);
    rt_counted = rt_counted(ind_include);
end;

% sorting responses according to rt
[rt_counted_sorted, sortindex] = sort(rt_counted);
 
% dividing rt into 5 equal range
t_presses_counted = t_presses_counted(sortindex);
t_releases_counted = t_releases_counted(sortindex);
pressdur_counted = t_releases_counted-t_presses_counted;

[PSTH_Press, tPSTH_Press, SpkMat_Press, tSpkMat_Press,  ~] = jpsth(r.Units.SpikeTimes(ku).timings,  t_presses_counted, params_press);
[PSTH_Release, tPSTH_Release, SpkMat_Release, tSpkMat_Release,  ~] = jpsth(r.Units.SpikeTimes(ku).timings,  t_releases_counted, params_release);

ItemsDiv = floor(length(rt_counted_sorted)/5);

PressTimeGroups = cell(2, Ndiv);
PSTHPressDuration.TypeLabeling =  {'PSTH', 'tPSTH', 'SpkMat', 'tSpkMat', 'SDF', 'tEvents', 'PressDuration'};
PSTHPressDuration.PressGroups = cell(1, Ndiv);
PSTHPressDuration.ReleaseGroups = cell(1, Ndiv);

close(fig_handle1);

fig_handle2=29;
figure(fig_handle2); clf(fig_handle2)
set(gcf, 'unit', 'centimeters', 'position', [5 5 18 10], 'paperpositionmode', 'auto' ,'color', 'w')

allcolors = colormap(colmp);
ncolors = round(size(allcolors, 1)*rmax);
colorindex = fliplr(round(linspace(1, ncolors, Ndiv)));
color_selected = allcolors(colorindex, :);
MeanPressDur = zeros(1, Ndiv);
IndNdiv = zeros(Ndiv, 2);

width1 = 4;
ha1 =  axes('unit', 'centimeters', 'position', [2 2 width1 3], 'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-50 PressTimeDomain(2)], 'fontsize', 9,'ticklength', [0.0200 0.0250]);

width2 = 2*width1/(sum(PressTimeDomain)+50)*sum(ReleaseTimeDomain+50);
ha2 =  axes('unit', 'centimeters', 'position', [2+width1+1 2 width2 3], 'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1)-50 ReleaseTimeDomain(2)], 'fontsize', 9,'ticklength', [0.0200 0.0250], 'ytick', []);

for i =1:Ndiv
    if i~=Ndiv
        ind = [1:ItemsDiv]+(i-1)*ItemsDiv;
    else
        ind = [1+(Ndiv-1)*ItemsDiv:length(t_presses_counted)];
    end;
    
    IndNdiv(i, :) = [ind(1) ind(end)];
    PressDur_i                      =               t_releases_counted(ind)- t_presses_counted(ind);
    PressTimeGroups{1, i}        =           t_presses_counted(ind); % collection of press times that produce a specific range of release times. 
    PressTimeGroups{2, i}        =           t_releases_counted(ind); % collection of press times that produce a specific range of release times. 

    % Press-aligned
    [psth_press, ts, trialspxmat, tspkmat,  t_press_sorted] = jpsth(r.Units.SpikeTimes(ku).timings,  PressTimeGroups{1, i} , params_press);
    psth_press = smoothdata (psth_press, 'gaussian', 5);
    sdf_unit = sdf(tspkmat/1000, trialspxmat, kernelwidth);
    MeanPressDur(i) = mean(PressDur_i); % mean press duration
    % Use a gaussian kernel to convolve spike trains to get psth
    indplot= find(tspkmat>=100-PressTimeDomain(1) & tspkmat<=PressTimeDomain(2)-100);
    PSTHPressDuration.PressGroups{i} = {psth_press, ts, trialspxmat, tspkmat, sdf_unit, t_press_sorted, PressDur_i};
    plot(ha1, tspkmat(indplot), mean(sdf_unit(indplot, :), 2), 'color', color_selected(i, :), 'linewidth', 1)

    % Release-aligned
    [psth_release, ts, trialspxmat, tspkmat,  t_release_sorted] = jpsth(r.Units.SpikeTimes(ku).timings,  PressTimeGroups{2, i} , params_release);
    psth_release = smoothdata (psth_release, 'gaussian', 5);
    sdf_unit = sdf(tspkmat/1000, trialspxmat, kernelwidth);
     % Use a gaussian kernel to convolve spike trains to get psth
    indplot= find(tspkmat>=100-ReleaseTimeDomain(1) & tspkmat<=ReleaseTimeDomain(2)-100);
    PSTHPressDuration.ReleaseGroups{i} = {psth_release, ts, trialspxmat, tspkmat, sdf_unit, t_release_sorted, PressDur_i};
    plot(ha2, tspkmat(indplot), mean(sdf_unit(indplot, :), 2), 'color', color_selected(i, :), 'linewidth', 1)
end;

ylim1 = get(ha1, 'ylim');
ylim2 = get(ha2, 'ylim');
ylim_new = [0 max([ylim1, ylim2])];
set(ha1, 'ylim', ylim_new);
set(ha2, 'ylim', ylim_new);
line(ha1, [0 0], ylim_new, 'color',  [0 173 238]/255, 'linestyle','-.', 'linewidth', 1)
line(ha2, [0 0], ylim_new, 'color',  [0 173 238]/255, 'linestyle','-.', 'linewidth', 1)
axes(ha1)
xlabel('Time from press (ms)')
ylabel('Spk rate (spk per s)')
axes(ha2)
xlabel('Release (ms)')
MeanPressDur(MeanPressDur>PressTimeDomain(2))=PressTimeDomain(2);
for i =1:Ndiv
    line(ha1, (MeanPressDur(i))*[1 1], [0.9 1]*ylim_new(2), 'color', color_selected(i, :), 'linewidth', 1.5)
end;
 
hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position', [2+width1+1+width2+0.5 2 0.25 3],...
    'ticks', fliplr(colorindex)/size(allcolors, 1),'TickLabels', string(fliplr(round(MeanPressDur))), ...
    'ticklength', 0.02, 'Limits', [0 rmax+0.05]);

%% make raster plot
ntrial2 =length(t_presses_counted);

ha4 =  axes('unit', 'centimeters', 'position', [2 6 width1 3], 'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-50 PressTimeDomain(2)],...
    'ylim', [-ntrial2 1.5],'fontsize', 9,'xtick', []);
axis off
for i =1:Ndiv
    line([-PressTimeDomain(1) -PressTimeDomain(1)]-50, -[IndNdiv(i, :)], 'color', color_selected(i, :), 'linewidth', 4);
end;

k =0;
for i =1:size(SpkMat_Press, 2)
    idur = pressdur_counted(i);
    xx = tSpkMat_Press(find(SpkMat_Press(:, i)));
    xx = xx(xx>=100-PressTimeDomain(1) & xx<=PressTimeDomain(2)-100);
    yy = [0 1]-k;
    xxdur = [idur idur];
    if  isempty(find(isnan(SpkMat_Press(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        disp(i)
        line([xxdur], yy, 'color', [200 65 81]/255, 'linewidth', 1.5)
        k = k+1;
    end;
end;

line([0 0], get(gca, 'ylim'), 'color', [0 173 238]/255, 'linewidth', 1)
title('Press aligned')

PSTHPressDuration.Press.tSpkMat = tSpkMat_Press;
PSTHPressDuration.Press.SpkMat = SpkMat_Press;
PSTHPressDuration.Press.PSTH = PSTH_Press;
PSTHPressDuration.Press.tPSTH = tPSTH_Press;
PSTHPressDuration.Press.HoldTime = pressdur_counted;

% Plot release spike raster
ntrial2 =length(t_presses_counted);
ha5 =  axes('unit', 'centimeters', 'position', [2+width1+1 6 width2 3], 'nextplot', 'add',...
    'xlim', [-ReleaseTimeDomain(1)-50 ReleaseTimeDomain(2)],...
    'ylim', [-ntrial2 1.5],'fontsize', 9,'xtick', []);
axis off
for i =1:Ndiv
    line([-ReleaseTimeDomain(1) -ReleaseTimeDomain(1)]-50, -[IndNdiv(i, :)], 'color', color_selected(i, :), 'linewidth', 4);
end;

k =0;
for i =1:size(SpkMat_Release, 2)
    idur = pressdur_counted(i);
    if idur>ReleaseTimeDomain(1)
        idur = [];
    end;
    xx = tSpkMat_Release(find(SpkMat_Release(:, i)));
    xx = xx(xx>=100-ReleaseTimeDomain(1) & xx<=ReleaseTimeDomain(2)-100);
    yy = [0 1]-k;
    xxdur = [idur  idur];
    if  isempty(find(isnan(SpkMat_Release(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        disp(i)
        if ~isempty(idur)
            line(-xxdur, yy, 'color', [200 65 81]/255, 'linewidth', 1.5)
        end;
        k = k+1;
    end;
end;

line([0 0], get(gca, 'ylim'), 'color', [0 173 238]/255, 'linewidth', 1)
title('Release aligned')

PSTHPressDuration.Press.tSpkMat = tSpkMat_Press;
PSTHPressDuration.Press.SpkMat = SpkMat_Press;
PSTHPressDuration.Press.PSTH = PSTH_Press;
PSTHPressDuration.Press.tPSTH = tPSTH_Press;
PSTHPressDuration.Press.HoldTime = pressdur_counted;

PSTHPressDuration.Release.tSpkMat = tSpkMat_Release;
PSTHPressDuration.Release.SpkMat = SpkMat_Release;
PSTHPressDuration.Release.PSTH = PSTH_Release;
PSTHPressDuration.Release.tPSTH = tPSTH_Release;
PSTHPressDuration.Release.HoldTime = pressdur_counted;


%% plot spike waveform
thiscolor = [0 0 0];
Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
x_now = 2+width1+1+width2+3;
ha0=axes('unit', 'centimeters', 'position', [x_now 4.5 2.5 2],...
    'nextplot', 'add', 'xlim', [0 Lspk]);
set(ha0, 'nextplot', 'add');
allwaves = r.Units.SpikeTimes(ku).wave;
PSTHPressDuration.Spikes.Wave = allwaves;
if size(allwaves, 1)>50
    nplot = randperm(size(allwaves, 1), 50);
else
    nplot=[1:size(allwaves, 1)];
end;
wave2plot = allwaves(nplot, :);
plot([1:Lspk], wave2plot, 'color', [0.8 .8 0.8]);
plot([1:Lspk], mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)

axis([0 Lspk min(wave2plot(:)) max(wave2plot(:))])
set (gca, 'ylim', [min(mean(allwaves, 1))*1.5 max(mean(allwaves, 1))*1.5])
axis tight

line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
axis off
switch r.Units.SpikeNotes(ku, 3)
    case 1
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1)) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU'], 'fontsize', 10);
    case 2
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1))  ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU'], 'fontsize', 10);
    otherwise
end

% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);
kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;

PSTHPressDuration.Spikes.Timing_ms = kutime;

[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;

PSTHPressDuration.Spikes.Autocorrelation = {lags, c};
PSTHPressDuration.ComputeRange_ms = compute_range;


ha00= axes('unit', 'centimeters', 'position', [x_now 2 2.5 2], 'nextplot', 'add', 'xlim', [-100 100]);
if median(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', [-100:50:100], 'ytick', [0 median(c)]);
else
    set(ha00, 'nextplot', 'add', 'xtick', [-100:50:100], 'ytick', [0 1], 'ylim', [0 1]);
end;

hbar = bar(lags, c, 1);
set(hbar, 'facecolor', 'k')

xlabel('Lag(ms)')

ch = r.Units.SpikeNotes(ku, 1);
unit_no = r.Units.SpikeNotes(ku, 2);

uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_now-1 8.5 4 1.5],...
    'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w', 'fontsize', 11, 'fontweight','bold')
uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_now-1 7.5 4.5 1],...
    'string', (['Unit#' num2str(ku) '(' electrode_type num2str(ch) ')']), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')
%
if combined_cue_uncue
    uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_now-1 7 4.5 1],...
        'string', (['Cue/Uncue combined']), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')
end;

PSTHPressDuration.Meta = {[r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)], ['Unit#' num2str(ku) '(' electrode_type num2str(ch) ')']};

% save to a folder
% anm_name = r.Meta(1).Subject;
% session =strrep(r.Meta(1).DateTime(1:11), '-','');

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

rat_name            =       r.Meta(1).Subject;
session_name    =       r.BehaviorClass.Date;

tosavename2= fullfile(thisFolder, [rat_name '_' session_name '_' 'Ramping' '_' electrode_type num2str(ch) '_Unit' num2str(unit_no) printname]);

print (gcf,'-depsc2', tosavename2)
print (gcf,'-dpng', tosavename2)

PSTHOut = PSTHPressDuration;
tosavename3= fullfile(thisFolder, [rat_name '_' session_name '_' 'Ramping' '_' electrode_type num2str(ch) '_Unit' num2str(unit_no) printname]);
save(tosavename3, 'PSTHOut');
 
try
    this_folder          =      pwd;
    folder_split          =     split(this_folder, '\');
    rat_name            =       r.Meta(1).Subject;
    session_name    =       r.BehaviorClass.Date;
    disp(rat_name)
    disp(session_name)
    thatfolder = fullfile(findonedrive, '00_Work', '03_Projects', '06_TimingBehavior', 'EphysData', 'Ramping', 'fig');
    tosavename2thatfolder= fullfile(thatfolder, [rat_name '_' session_name '_' electrode_type num2str(ch) '_Unit' num2str(unit_no) printname]);
    print (gcf,'-depsc2', tosavename2thatfolder)
    print (gcf,'-dpng', tosavename2thatfolder)
    thatfolder = fullfile(findonedrive, '00_Work', '03_Projects', '06_TimingBehavior', 'EphysData', 'Ramping', 'data');

    tosavename3thatfolder= fullfile(thatfolder, [rat_name '_' session_name '_'  electrode_type num2str(ch) '_Unit' num2str(unit_no) printname '.mat']);
    save(tosavename3thatfolder, 'PSTHOut');
end