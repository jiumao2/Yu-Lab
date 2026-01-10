function VisualizePSTHPopulation(PSTHOut)

IndSort = PSTHOut.IndSort;
IndSignificant = PSTHOut.IndSignificant;
nsig = sum(IndSignificant);

PressPSTHs2      =       PSTHOut.PressZ{2}(2:end, :);
PressPSTHs2      =       PressPSTHs2(IndSort, :);
tPSTH2                =       PSTHOut.PressZ{2}(1, :);

PressPSTHs1      =       PSTHOut.PressZ{1}(2:end, :);
PressPSTHs1      =       PressPSTHs1(IndSort, :);
tPSTH1                =       PSTHOut.PressZ{1}(1, :);

PressPSTHsMerged      =       PSTHOut.PressMergedZ(2:end, :);
PressPSTHsMerged      =       PressPSTHsMerged(IndSort, :);
tPressPSTHMerged       =       PSTHOut.PressMergedZ(1, :);

PressPSTHsMergedRaw      =       PSTHOut.PressMerged(2:end, :);
PressPSTHsMergedRaw      =       PressPSTHsMergedRaw(IndSort, :);  

% raw PSTH for cue and uncue trials
PressPSTHCuedRaw           =        PSTHOut.Press{1}(2:end, :);
PressPSTHCuedRaw           =        PressPSTHCuedRaw(IndSort, :);
tPressPSTHCuedRaw          =        PSTHOut.Press{1}(1, :);

PressPSTHUncuedRaw           =        PSTHOut.Press{2}(2:end, :);
PressPSTHUncuedRaw           =        PressPSTHUncuedRaw(IndSort, :);
tPressPSTHUncuedRaw          =        PSTHOut.Press{2}(1, :);

ReleasePSTHs2      =       PSTHOut.ReleaseZ{2}(2:end, :);
ReleasePSTHs2      =       ReleasePSTHs2(IndSort, :);
tReleasePSTH2       =       PSTHOut.ReleaseZ{2}(1, :);

ReleasePSTHs1      =       PSTHOut.ReleaseZ{1}(2:end, :);
ReleasePSTHs1      =       ReleasePSTHs1(IndSort, :);
tReleasePSTH1       =       PSTHOut.ReleaseZ{1}(1, :);

ReleasePSTHsMerged      =       PSTHOut.ReleaseMergedZ(2:end, :);
ReleasePSTHsMerged      =       ReleasePSTHsMerged(IndSort, :);
tReleasePSTHMerged      =       PSTHOut.ReleaseMergedZ(1, :);

ReleasePSTHsMergedRaw      =       PSTHOut.ReleaseMerged(2:end, :);
ReleasePSTHsMergedRaw      =       ReleasePSTHsMergedRaw(IndSort, :); 

% raw PSTH for cue and uncue trials (release)
ReleasePSTHCuedRaw           =        PSTHOut.Release{1}(2:end, :);
ReleasePSTHCuedRaw           =        ReleasePSTHCuedRaw(IndSort, :);
tReleasePSTHCuedRaw          =        PSTHOut.Release{1}(1, :);

ReleasePSTHUncuedRaw           =    PSTHOut.Release{2}(2:end, :);
ReleasePSTHUncuedRaw           =    ReleasePSTHUncuedRaw(IndSort, :);
tReleasePSTHUncuedRaw          =    PSTHOut.Release{2}(1, :);

TriggerPSTHs      =       PSTHOut.TriggerZ(2:end, :);
TriggerPSTHs      =       TriggerPSTHs(IndSort, :);
tTriggerPSTH      =       PSTHOut.TriggerZ(1, :);

TriggerPSTHsRaw      =       PSTHOut.Trigger(2:end, :);
TriggerPSTHsRaw      =       TriggerPSTHsRaw(IndSort, :); 

RewardPSTHs1      =       PSTHOut.RewardZ{1}(2:end, :);
RewardPSTHs1      =       RewardPSTHs1(IndSort, :);
tRewardPSTH1      =       PSTHOut.RewardZ{1}(1, :);

RewardPSTHs2      =       PSTHOut.RewardZ{2}(2:end, :);
RewardPSTHs2     =       RewardPSTHs2(IndSort, :);
tRewardPSTH2     =       PSTHOut.RewardZ{2}(1, :);

RewardPSTHsMerged      =       PSTHOut.RewardMergedZ(2:end, :);
RewardPSTHsMerged     =       RewardPSTHsMerged(IndSort, :);
tRewardPSTHMerged     =       PSTHOut.RewardMergedZ(1, :);

% Cue
RewardPSTHsCuedRaw      =       PSTHOut.Reward{1}(2:end, :);
RewardPSTHsCuedRaw      =       RewardPSTHsCuedRaw(IndSort, :); 
% Uncue
RewardPSTHsUncuedRaw      =       PSTHOut.Reward{2}(2:end, :);
RewardPSTHsUncuedRaw      =       RewardPSTHsUncuedRaw(IndSort, :); 
%Merged
RewardPSTHsMergedRaw      =       PSTHOut.RewardMerged(2:end, :);
RewardPSTHsMergedRaw      =       RewardPSTHsMergedRaw(IndSort, :); 

PSTH_Merged_Concatenate           =     [PressPSTHsMergedRaw      ReleasePSTHsMergedRaw   RewardPSTHsMergedRaw];
PSTH_Cued_Concatenate              =     [PressPSTHCuedRaw            ReleasePSTHCuedRaw        RewardPSTHsCuedRaw];
PSTH_Uncued_Concatenate          =     [PressPSTHUncuedRaw         ReleasePSTHUncuedRaw    RewardPSTHsUncuedRaw];

IndPress                      =        [1:size(PressPSTHsMergedRaw, 2)];
IndRelease                  =        [IndPress(end)+1:IndPress(end)+size(ReleasePSTHsMergedRaw, 2)];
IndReward                   =        [IndRelease(end)+1:IndRelease(end)+size(RewardPSTHsMergedRaw, 2)];

%% Normalized to [-1 1]
norm_range = [0 1];
PSTH_Merged_ConNorm = normalize(PSTH_Merged_Concatenate', 'range',norm_range);
PSTH_Merged_ConNorm= PSTH_Merged_ConNorm';

PSTH_Cued_ConNorm = normalize(PSTH_Cued_Concatenate', 'range',norm_range);
PSTH_Cued_ConNorm = PSTH_Cued_ConNorm';

PSTH_Uncued_ConNorm = normalize(PSTH_Uncued_Concatenate', 'range',norm_range);
PSTH_Uncued_ConNorm= PSTH_Uncued_ConNorm';

%%
set_matlab_default;
mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
% visualize PSTH (z score)
zrange = [-3 3];

ylevel_cue   = 11.5;
ylevel_uncue = 6.5;
ylevel_both = 16.5;

hf=28;
figure(28); clf(28)
set(gcf, 'unit', 'centimeters', 'position', [2 2 25 22], 'paperpositionmode', 'auto' ,'color', 'w')

PressPSTHsNorm_Cued           =         PSTH_Cued_ConNorm(:, IndPress);
PressPSTHsNorm_Uncued       =         PSTH_Uncued_ConNorm(:, IndPress);
PressPSTHsNorm_Both            =         PSTH_Merged_ConNorm(:, IndPress);
 
NCells = size(PressPSTHsMerged, 1);

% Press
tRange = [tPressPSTHCuedRaw(1) 2000];
Width  = 2*diff(tRange)/2000;

% Cued, Press
ha1=axes('unit', 'centimeters', 'position', [1.5 ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 35,...
    'xticklabel', {});

himage1 = imagesc(tPressPSTHCuedRaw, [1:NCells], PressPSTHsNorm_Cued, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
line([0 0]+PSTHOut.FP, [0.5 NCells+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Cued)', PSTHOut.NumCued))

% Uncued, Press
ha2=axes('unit', 'centimeters', 'position', [1.5 ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
      'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 35);
himage2 = imagesc(tPressPSTHUncuedRaw, [1:NCells], PressPSTHsNorm_Uncued, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Uncued)', PSTHOut.NumUncued));
xloc = get(ha1, 'position'); 
xbound = sum(xloc([1, 3]))+0.25;
xlabel('Press (ms)')

% Combined, Press
ha3=axes('unit', 'centimeters', 'position', [1.5 ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 35,...
    'xticklabel', {});
himage3 = imagesc(tPressPSTHCuedRaw, [1:NCells], PressPSTHsNorm_Both, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
line([0 0]+PSTHOut.FP, [0.5 NCells+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Both)', PSTHOut.NumCued+PSTHOut.NumUncued))

% Release
ReleasePSTHsNorm_Cued           =         PSTH_Cued_ConNorm(:, IndRelease);
ReleasePSTHsNorm_Uncued       =         PSTH_Uncued_ConNorm(:, IndRelease);
ReleasePSTHsNorm_Both            =         PSTH_Merged_ConNorm(:, IndRelease);
tRange = [-500 1000];
Width  = 2*diff(tRange)/2000;

% Cue, both
ha2 =  axes('unit', 'centimeters', 'position', [xbound ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000], 'ytick', [], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 35, 'xticklabel', {});
himage2 = imagesc(tReleasePSTHCuedRaw, [1:NCells], ReleasePSTHsNorm_Both, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)

% Cue, release
ha2 =  axes('unit', 'centimeters', 'position', [xbound ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000], 'ytick', [], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 0, 'xticklabel', {});
himage2 = imagesc(tReleasePSTHCuedRaw, [1:NCells], ReleasePSTHsNorm_Cued, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)

% Uncue, release
axes('unit', 'centimeters', 'position', [xbound ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],'xtick',[-3000:1000:3000],  'ytick', [], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'xtick', [0:1000:5000], 'XTickLabelRotation', 35);
imagesc(tReleasePSTHUncuedRaw, [1:NCells], ReleasePSTHsNorm_Uncued, norm_range);
colormap('Parula')
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
xloc = get(ha2, 'position'); 
xbound = sum(xloc([1, 3]))+0.25;
xlabel('Release (ms)')

% Reward
RewardPSTHsNorm_Cued             =          PSTH_Cued_ConNorm(:, IndReward);
RewardPSTHsNorm_Uncued          =         PSTH_Uncued_ConNorm(:, IndReward);
RewardPSTHsNorm_Both               =         PSTH_Merged_ConNorm(:, IndReward);

tRange = [tRewardPSTH1(1) tRewardPSTH1(end)];
Width  = 2*diff(tRange)/2000;

% Both
axes('unit', 'centimeters', 'position', [xbound ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [],'xtick',[-3000:1000:3000], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 35, 'xticklabel', {});

imagesc(tRewardPSTH1, [1:NCells], RewardPSTHsNorm_Both, norm_range);
colormap('Parula')
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)

% Cued
axes('unit', 'centimeters', 'position', [xbound ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [],'xtick',[-3000:1000:3000], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'xtick', [0:1000:5000], 'XTickLabelRotation',  35, 'xticklabel', {});

imagesc(tRewardPSTH1, [1:NCells], RewardPSTHsNorm_Cued, norm_range);
colormap('Parula')
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)

% Uncued
axes('unit', 'centimeters', 'position', [xbound ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [],'xtick',[-3000:1000:3000], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 35);

imagesc(tRewardPSTH2, [1:NCells], RewardPSTHsNorm_Uncued, norm_range);
colormap('Parula')
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'w', 'linestyle', ':', 'linewidth', 1.5)
xlabel('Reward (ms)') 

xloc = get(gca, 'position'); 
xboundbar= sum(xloc([1, 3]))+0.1;
xboundfinal = sum(xloc([1, 3]))+3;

% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_uncue, 0.25 4],...
    'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'Norm';
hcbar.Label.FontSize = 11;

%% Plot z scores
% Press
tRange = [tPressPSTHCuedRaw(1) 2000];
Width  = 2*diff(tRange)/2000;

% Cued
ha3 =  axes('unit', 'centimeters', 'position', [xboundfinal ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'xticklabel', [],'ylim', [0.5 NCells+0.5], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'XTickLabelRotation', 35);
imagesc(tPSTH1, [1:NCells], PressPSTHs1, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
line([0 0]+PSTHOut.FP, [0.5 NCells+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Cued)', PSTHOut.NumCued), 'fontsize', 11)
colormap(ha3, mycolormap);

% Uncued
ha4 =  axes('unit', 'centimeters', 'position', [xboundfinal ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'xtick', [-3000:1000:3000],'ylim', [0.5 NCells+0.5], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'XTickLabelRotation', 35);
imagesc(tPSTH2, [1:NCells], PressPSTHs2, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
line([0 0]+PSTHOut.FP, [0.5 NCells+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Uncued)', PSTHOut.NumUncued), 'fontsize', 11)
colormap(ha4, mycolormap);
xlabel('Press (ms)')

% Both
ha5 =  axes('unit', 'centimeters', 'position', [xboundfinal ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'XTickLabelRotation', 35,'xticklabel', []);
imagesc(tPSTH2, [1:NCells], PressPSTHsMerged, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
line([0 0]+PSTHOut.FP, [0.5 NCells+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
title(sprintf('%s, Ntrials=%2.0d','Press (Both)', PSTHOut.NumUncued+PSTHOut.NumCued), 'fontsize', 11)
colormap(ha5, mycolormap);

xloc = get(ha4, 'position');
xbound = sum(xloc([1, 3]))+0.25;

% Release
tRange = [-500 1000];
Width  = 2*diff(tRange)/2000;

% cued
ha5 =  axes('unit', 'centimeters', 'position', [xbound ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5], 'ytick', [], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'xtick', [], 'XTickLabelRotation', 35, 'xticklabel', []);
himage2 = imagesc(tReleasePSTH1, [1:NCells], ReleasePSTHs1, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
colormap(ha5, mycolormap);

% uncued
ha6 = axes('unit', 'centimeters', 'position', [xbound ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ylim', [0.5 NCells+0.5],  'ytick', [], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'xtick', [0:1000:5000], 'XTickLabelRotation', 35);
imagesc(tReleasePSTH2, [1:NCells], ReleasePSTHs2, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
colormap(ha6, mycolormap);
xlabel('Release (ms)')

% Both
ha5 =  axes('unit', 'centimeters', 'position', [xbound ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse',...
    'ticklength', [0.025 0.01], 'XTickLabelRotation', 35, 'xticklabel', []);
imagesc(tPSTH2, [1:NCells], ReleasePSTHsMerged, zrange);
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
colormap(ha5, mycolormap);

xloc = get(ha6, 'position');
xbound = sum(xloc([1, 3]))+0.25;

% Reward
tRange = [tRewardPSTH1(1) tRewardPSTH1(end)];
Width  = 2*diff(tRange)/2000;

% Both
ha9 = axes('unit', 'centimeters', 'position', [xbound ylevel_both Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 0, 'xticklabel', []);
imagesc(tRewardPSTH1, [1:NCells], RewardPSTHsMerged, zrange);
line(get(gca, 'xlim'), [nsig nsig]+0.5, 'color', 'k', 'linewidth', 2)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
colormap(ha9, mycolormap);

% Cue
ha7 = axes('unit', 'centimeters', 'position', [xbound ylevel_cue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 0, 'xticklabel', []);
imagesc(tRewardPSTH1, [1:NCells], RewardPSTHs1, zrange);
line(get(gca, 'xlim'), [nsig nsig]+0.5, 'color', 'k', 'linewidth', 2)
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
colormap(ha7, mycolormap);

% Uncue
ha8 = axes('unit', 'centimeters', 'position', [xbound ylevel_uncue Width 4], 'nextplot', 'add', 'xlim', tRange,...
    'ytick', [], 'ylim', [0.5 NCells+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01],...
    'xtick', [0:1000:5000], 'XTickLabelRotation', 35);
imagesc(tRewardPSTH2, [1:NCells], RewardPSTHs2, zrange);
plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; NCells+0.5 NCells+0.5],  'w', 0.75)
line([0 0], [0.5 NCells+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
colormap(ha8, mycolormap);
xlabel('Reward (ms)') 
 
xloc = get(gca, 'position'); 
xboundbar= sum(xloc([1, 3]))+0.1;
xboundfinal = sum(xloc([1, 3]))+2;

% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_uncue, 0.25 4], 'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'z score';
hcbar.Label.FontSize = 11;
% Add information
uicontrol('Style','text','Units','normalized','Position',[0.1 0.95 0.2 0.04],...
    'string', [PSTHOut.Name ' | ' strrep(PSTHOut.Session, '_', '-')], ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 12,'BackgroundColor','w')

%% plot spk information
% write the info to a csv table. 
% number of sorted units in this experiment-this is also the number of
% rows
n_unit = size(PSTHOut.Units, 1);
% anm name
Name = repmat(PSTHOut.Name, n_unit, 1);
% session
Session =  repmat(PSTHOut.Date, n_unit, 1);

% Sorting order

Chs              =     zeros(n_unit, 1);
Ch_Units         =     zeros(n_unit, 1);
Unit_Quality_Num =   zeros(n_unit, 1);
Unit_Quality     =     cell(n_unit, 1);
SignificantMod   =     PSTHOut.IndSignificant';
Unit_Sorted      =     PSTHOut.IndSort';

for i =1:length(PSTHOut.IndSort)
    iCode = PSTHOut.Units(PSTHOut.IndSort(i), :);
    Chs(i)          =       iCode(1);
    Ch_Units(i)     =       iCode(2); 
    if iCode(3) == 1
        Unit_Quality{i} = 's';
    else
        Unit_Quality{i} = 'm';
    end; 
    Unit_Quality_Num(i) = iCode(3);
end;

tab = table(Name, Session, Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod);
aGoodName = ['PSTHOut_', PSTHOut.Name, '_' PSTHOut.Session '.csv'];
writetable(tab, aGoodName)
% % open this table
% try
%     winopen(aGoodName)
% end;

% Insert table
table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num SignificantMod];
uitable(hf, 'unit', 'centimeters','Data', table_data,...
    'ColumnName', {'Unit|Sorted', 'Channel', 'Unit|Channel',  'Quality', 'StatSignificant'},...,
    'Position', [1.5 1 15 3]);

axis off
thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['PopulationActivity' '_' PSTHOut.Name '_' strrep(PSTHOut.Session, '-', '_')]);
print (gcf,'-dpdf', tosavename);
print (gcf,'-dpng', tosavename);
print (gcf,'-depsc2', tosavename);
