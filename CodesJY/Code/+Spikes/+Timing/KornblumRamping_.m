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
 
printname = [];
printsize = [2 2 20 16];
tosave =1;
PressTimeDomain = [1000 3000];
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
            case 'Combined'
                combined_cue_uncue = 1;
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

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);
t_rewards_cue = [];
t_rewards_uncue = [];

% check which reward is produced by cue vs uncue trials (there might be a difference)
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
t_correctpresses = t_presses([reshape(rb.CorrectIndex, 1, []) reshape(rb.PrematureIndex, 1, []) reshape(rb.LateIndex, 1, [])]); % also takes premature presses
FPs_correctpresses = rb.Foreperiods([reshape(rb.CorrectIndex, 1, []) reshape(rb.PrematureIndex, 1, []) reshape(rb.LateIndex, 1, [])]);
FP_Kornblum = median(rb.Foreperiods); % This is the foreperiod of this session

[t_correctpresses_cue, ind_correct_cue]             =       intersect(t_correctpresses, t_presses_cue);
[t_correctpresses_uncue, ind_correct_uncue]     =       intersect(t_correctpresses, t_presses_uncue);

% index and time of correct releases
t_correctreleases = t_releases([reshape(rb.CorrectIndex, 1, []) reshape(rb.PrematureIndex, 1, []) reshape(rb.LateIndex, 1, [])]); 
t_correctreleases_cue           =       t_correctreleases(ind_correct_cue);
t_correctreleases_uncue       =       t_correctreleases(ind_correct_uncue);

% reaction time of correct responses
rt_correct                  =        t_correctreleases - t_correctpresses - FPs_correctpresses;
rt_correct_cue          =     t_correctreleases_cue - t_correctpresses_cue; %   rt_correct(ind_correct_cue);
rt_correct_uncue      =     t_correctreleases_uncue -  t_correctpresses_uncue; % rt_correct(ind_correct_uncue);

% check if any data need to be excluded
if ~isempty(compute_range)
    ind_include = find(t_correctpresses_uncue >= compute_range(1) & t_correctpresses_uncue <= compute_range(2));
    t_correctpresses_uncue = t_correctpresses_uncue(ind_include);
    rt_correct_uncue = rt_correct_uncue(ind_include);
end;

% sorting index
[rt_correct_cue_sorted, sortindex_cue] = sort(rt_correct_cue);
[rt_correct_uncue_sorted, sortindex_uncue] = sort(rt_correct_uncue);
% sort "rt_correct_uncue_sorted"
% dividing rt into 5 equal range

t_correctpresses_cue = t_correctpresses_cue(sortindex_cue);
t_correctpresses_uncue = t_correctpresses_uncue(sortindex_uncue);

[PSTHall, tPSTHall, SpkMat, tSpkMat,  ~] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses_uncue, params_press);

ItemsDiv = floor(length(rt_correct_uncue_sorted)/5);
PressTimeUncuedGroups = cell(1, Ndiv);

PSTHPressTimeUncued.TypeLabeling =  {'PSTH', 'tPSTH', 'SpkMat', 'tSpkMat', 'SDF', 'tEvents', 'PressDuration'};
PSTHPressTimeUncued.Groups = cell(1, Ndiv);

close(8);

hf=29;
figure(29); clf(29)
set(gcf, 'unit', 'centimeters', 'position', [5 5 12 10], 'paperpositionmode', 'auto' ,'color', 'w')

ha1 =  axes('unit', 'centimeters', 'position', [2 2 4 3], 'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-50 PressTimeDomain(2)], 'fontsize', 9,'ticklength', [0.0200 0.0250]);

allcolors = colormap(colmp);
ncolors = round(size(allcolors, 1)*rmax);
colorindex = fliplr(round(linspace(1, ncolors, Ndiv)));
color_selected = allcolors(colorindex, :);
MeanPressDur = zeros(1, Ndiv);
IndNdiv = zeros(Ndiv, 2);

for i =1:Ndiv
    if i~=Ndiv
        ind = [1:ItemsDiv]+(i-1)*ItemsDiv;
    else
        ind = [1+(Ndiv-1)*ItemsDiv:length(rt_correct_uncue_sorted)];
    end;
    
    IndNdiv(i, :) = [ind(1) ind(end)];
    PressDur_i = rt_correct_uncue_sorted(ind);
    PressTimeUncuedGroups{i} = t_correctpresses_uncue(ind);
    [psth_press, ts, trialspxmat, tspkmat,  t_presssorted] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctpresses_uncue(ind), params_press);
    psth_press = smoothdata (psth_press, 'gaussian', 5);
    sdf_unit = sdf(tspkmat/1000, trialspxmat, kernelwidth);
    MeanPressDur(i) = mean(PressDur_i);
    % Use a gaussian kernel to convolve spike trains to get psth
    indplot= find(tspkmat>=100-PressTimeDomain(1) & tspkmat<=PressTimeDomain(2)-100);

    PSTHPressTimeUncued.Groups{i} = {psth_press, ts, trialspxmat, tspkmat, sdf_unit, t_presssorted, PressDur_i};
    plot(ha1, tspkmat(indplot), mean(sdf_unit(indplot, :), 2), 'color', color_selected(i, :), 'linewidth', 1)
end;

xlabel('Time from press onset (ms)')
ylabel('Spk rate (spk per s)')
yrange = get(ha1, 'ylim');

for i =1:Ndiv
    line((MeanPressDur(i))*[1 1], [1 1.1]*yrange(2), 'color', color_selected(i, :), 'linewidth', 1.5)
end;

axes(ha1)
set(ha1, 'ylim', [0 yrange(2)*1.1]);
yrange = get(ha1, 'ylim');
line([0 0], yrange, 'color', [0 173 238]/255, 'linestyle', '--')
% plotshaded([1000 3000], [0 0; yrange(2)*0.1 yrange(2)*0.1], 'g')

hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position', [6.5 2 0.25 3],...
    'ticks', fliplr(colorindex)/size(allcolors, 1),'TickLabels', string(fliplr(round(MeanPressDur))), ...
    'ticklength', 0.02, 'Limits', [0 rmax+0.05]);

%% make raster plot
ntrial2 =length(t_correctpresses_uncue);

ha2 =  axes('unit', 'centimeters', 'position', [2 6 4 3], 'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-50 PressTimeDomain(2)],...
    'ylim', [-ntrial2 1],'fontsize', 9,'xtick', []);
axis off
for i =1:Ndiv
    line([-PressTimeDomain(1) -PressTimeDomain(1)]-50, -[IndNdiv(i, :)], 'color', color_selected(i, :), 'linewidth', 4);
end;

k =0;
for i =1:size(SpkMat, 2)

    irt =rt_correct_uncue_sorted(i);
    xx = tSpkMat(find(SpkMat(:, i)));
    xx = xx(xx>=100-PressTimeDomain(1) & xx<=PressTimeDomain(2)-100);

    yy = [0 1]-k;
    xxrt = [irt; irt];

    if  isempty(find(isnan(SpkMat(:, i))))
        if ~isempty(xx)
            line([xx; xx], yy, 'color', 'k', 'linewidth', 1)
        end;
        disp(i)
        line([xxrt xxrt], yy, 'color', [200 65 81]/255, 'linewidth', 1.5)
        k = k+1;
    end;
end;

line([0 0], get(gca, 'ylim'), 'color', [0 173 238]/255, 'linewidth', 1)
title('Uncued')

PSTHPressTimeUncued.All.tSpkMat = tSpkMat;
PSTHPressTimeUncued.All.SpkMat = SpkMat;
PSTHPressTimeUncued.All.PSTH = PSTHall;
PSTHPressTimeUncued.All.tPSTH = tPSTHall;
PSTHPressTimeUncued.All.HoldTime = rt_correct_uncue_sorted;

%% plot spike waveform
thiscolor = [0 0 0];
Lspk = size(r.Units.SpikeTimes(ku).wave, 2);

ha0=axes('unit', 'centimeters', 'position', [8.5 4.5 2.5 2],...
    'nextplot', 'add', 'xlim', [0 Lspk]);

set(ha0, 'nextplot', 'add');
allwaves = r.Units.SpikeTimes(ku).wave;

PSTHPressTimeUncued.Spikes.Wave = allwaves;

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
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1)) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU']);
    case 2
        title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1))  ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU']);
    otherwise
end

% plot autocorrelation
kutime = r.Units.SpikeTimes(ku).timings;
kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;

PSTHPressTimeUncued.Spikes.Timing_ms = kutime;

[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;

PSTHPressTimeUncued.Spikes.Autocorrelation = {lags, c};
PSTHPressTimeUncued.ComputeRange_ms = compute_range;


ha00= axes('unit', 'centimeters', 'position', [8.5 2 2.5 2], 'nextplot', 'add', 'xlim', [-100 100]);
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

uicontrol('style', 'text', 'units', 'centimeters', 'position', [7 8 4 1],...
    'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

uicontrol('style', 'text', 'units', 'centimeters', 'position', [7 7 4.5 1],...
    'string', (['Unit#' num2str(ku) '(' electrode_type num2str(ch) ')']), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')
%  
PSTHPressTimeUncued.Meta = {[r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)], ['Unit#' num2str(ku) '(' electrode_type num2str(ch) ')']};

% save to a folder
% anm_name = r.Meta(1).Subject;
% session =strrep(r.Meta(1).DateTime(1:11), '-','');

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename2= fullfile(thisFolder, ['Ramping' '_' electrode_type num2str(ch) '_Unit' num2str(unit_no) printname]);

print (gcf,'-depsc2', tosavename2)
print (gcf,'-dpng', tosavename2)

PSTHOut = PSTHPressTimeUncued;
tosavename3= fullfile(thisFolder, ['Ramping' '_' electrode_type num2str(ch) '_Unit' num2str(unit_no) printname]);
save(tosavename3, 'PSTHOut');

% Target folder for collection
% C:\Users\jiani\OneDrive\00_Work\03_Projects\06_TimingBehavior\EphysData\Ramping
try
    this_folder          =      pwd;
    folder_split          =     split(this_folder, '\');
    rat_name            =       r.Meta(1).Subject;
    session_name    =       folder_split{find(strcmp(folder_split, rat_name))+1};
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