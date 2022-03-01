function VisualizePSTHPopulation(PSTHOut)

% visualize PSTH (z score)
zrange = [-4 8];

% Long FP
pval_pop = zeros(1, size(PSTHOut.Units, 1));
tpeaks_pop = zeros(1, size(PSTHOut.Units, 1));

for i = 1:length(pval_pop)
    pval_pop(i)        =      PSTHOut.PressStat{1}.StatOut(i).pval;
    tpeaks_pop(i)    =      PSTHOut.PressStat{1}.StatOut(i).tpeak; 
end;

ind_significant = find(pval_pop<0.05);
[~, indsort] = sort(tpeaks_pop(ind_significant));
ind_plot = ind_significant(indsort);

PressPSTHs2      =       PSTHOut.PressZ{2}(2:end, :);
PressPSTHs2      =       PressPSTHs2(ind_plot, :);
tPSTH2                =       PSTHOut.PressZ{2}(1, :);

PressPSTHs1      =       PSTHOut.PressZ{1}(2:end, :);
PressPSTHs1      =       PressPSTHs1(ind_plot, :);
tPSTH1                =       PSTHOut.PressZ{1}(1, :);

PressPSTHsAll      =       PSTHOut.PressAllZ(2:end, :);
PressPSTHsAll      =       PressPSTHsAll(ind_plot, :);
tPressPSTHAll       =       PSTHOut.PressAllZ(1, :);

ReleasePSTHs2      =       PSTHOut.ReleaseZ{2}(2:end, :);
ReleasePSTHs2      =       ReleasePSTHs2(ind_plot, :);
tReleasePSTH2       =       PSTHOut.ReleaseZ{2}(1, :);

ReleasePSTHs1      =       PSTHOut.ReleaseZ{1}(2:end, :);
ReleasePSTHs1      =       ReleasePSTHs1(ind_plot, :);
tReleasePSTH1       =       PSTHOut.ReleaseZ{1}(1, :);

ReleasePSTHsAll      =       PSTHOut.ReleaseAllZ(2:end, :);
ReleasePSTHsAll      =       ReleasePSTHsAll(ind_plot, :);
tReleasePSTHAll      =       PSTHOut.ReleaseAllZ(1, :);

TriggerPSTHs      =       PSTHOut.TriggerZ(2:end, :);
TriggerPSTHs      =       TriggerPSTHs(ind_plot, :);
tTriggerPSTH      =       PSTHOut.TriggerZ(1, :);

RewardPSTHs      =       PSTHOut.RewardZ(2:end, :);
RewardPSTHs      =       RewardPSTHs(ind_plot, :);
tRewardPSTH      =       PSTHOut.RewardZ(1, :);

%% Make figures

hf=27;
figure(27); clf(27)
set(gcf, 'unit', 'centimeters', 'position', [2 2 15 18], 'paperpositionmode', 'auto' ,'color', 'w')

ha1 =  axes('unit', 'centimeters', 'position', [1.5 1.5 3.5 4], 'nextplot', 'add', 'xlim', [-2000 1500],...
    'ylim', [0.5 size(PressPSTHs1, 1)+0.5], 'ydir', 'reverse');
himage = imagesc(tPSTH1, [1:size(PressPSTHs1, 1)], PressPSTHs1, zrange);

line([0 0], [0.5 size(PressPSTHs1, 1)+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
line([750 750], [0.5 size(PressPSTHs1, 1)+0.5], 'color', [0.8 0.8 0.8], 'linestyle', ':', 'linewidth', 1.5)
xlabel('press')
title('Short FPs')
colormap('hot')

ha2 =  axes('unit', 'centimeters', 'position', [1.5 7 4.5 4], 'nextplot', 'add', 'xlim', [-2000 2500],...
    'ylim', [0.5 size(PressPSTHs2, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tPSTH2, [1:size(PressPSTHs2, 1)], PressPSTHs2,  zrange);
colormap('hot')

line([0 0], [0.5 size(PressPSTHs2, 1)+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)
line([1500 1500], [0.5 size(PressPSTHs1, 1)+0.5], 'color', [0.8 0.8 0.8], 'linestyle', ':', 'linewidth', 1.5)

 xlabel('press')
title('Long FPs')

ha3 =  axes('unit', 'centimeters', 'position', [1.5 12.5 2.75 4], 'nextplot', 'add', 'xlim', [-2000 750],...
    'ylim', [0.5 size(PressPSTHsAll, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tPressPSTHAll, [1:size(PressPSTHsAll, 1)], PressPSTHsAll, zrange);
colormap('hot')

line([0 0], [0.5 size(PressPSTHsAll, 1)+0.5], 'color', 'k', 'linestyle', ':', 'linewidth', 1.5)

yloc = get(ha3, 'position'); 
ybound = sum(yloc([1, 3]))+0.25;

xlabel('press')
title('Both FPs')
 

%% Plot trigger
ha6 =  axes('unit', 'centimeters', 'position', [ybound 12.5 1.5 4], 'nextplot', 'add', 'xlim', [-500 1000],...
    'ytick', [], 'ylim', [0.5 size(ReleasePSTHsAll, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tTriggerPSTH, [1:size(TriggerPSTHs, 1)], TriggerPSTHs, zrange);
colormap('hot')

line([0 0], [0.5 size(TriggerPSTHs, 1)+0.5], 'color', [0.8 0.8 0.8], 'linestyle', ':', 'linewidth', 1.5)
xlabel('trigger')
title('Both FPs')

yloc = get(ha6, 'position'); 
ybound = sum(yloc([1, 3]))+0.25;
%% Plot release
ha7 =  axes('unit', 'centimeters', 'position', [ybound 1.5 1.5 4], 'nextplot', 'add', 'xlim', [-500 1000],...
     'ytick', [],  'ylim', [0.5 size(ReleasePSTHs1, 1)+0.5], 'ydir', 'reverse');
himage = imagesc(tReleasePSTH1, [1:size(ReleasePSTHs1, 1)], ReleasePSTHs1, zrange);
colormap('hot')

line([0 0], [0.5 size(ReleasePSTHs1, 1)+0.5], 'color', 'g', 'linestyle', ':', 'linewidth', 1.5)
 xlabel('release')
title('Short FPs')

ha8 =  axes('unit', 'centimeters', 'position', [ybound  7 1.5 4], 'nextplot', 'add', 'xlim', [-500 1000],...
   'ytick', [],  'ylim', [0.5 size(ReleasePSTHs2, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tReleasePSTH2, [1:size(ReleasePSTHs2, 1)], ReleasePSTHs2, zrange);
colormap('hot')

line([0 0], [0.5 size(ReleasePSTHs2, 1)+0.5], 'color', 'g', 'linestyle', ':', 'linewidth', 1.5)
xlabel('release')
title('Long FPs')

ha9 =  axes('unit', 'centimeters', 'position', [ybound 12.5 1.5 4], 'nextplot', 'add', 'xlim', [-500 1000],...
     'ytick', [],  'ylim', [0.5 size(ReleasePSTHsAll, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tReleasePSTHAll, [1:size(ReleasePSTHsAll, 1)], ReleasePSTHsAll, zrange);
colormap('hot')

line([0 0], [0.5 size(ReleasePSTHs2, 1)+0.5], 'color', 'g', 'linestyle', ':', 'linewidth', 1.5)
xlabel('release')
title('Both FPs')

yloc = get(ha9, 'position'); 
ybound = sum(yloc([1, 3]))+0.25;
%% plot reward
ha10 =  axes('unit', 'centimeters', 'position', [ybound 12.5 3 4], 'nextplot', 'add', 'xlim', [-1000 2000],...
    'ytick', [], 'ylim', [0.5 size(RewardPSTHs, 1)+0.5], 'ydir', 'reverse');
himage2 = imagesc(tRewardPSTH, [1:size(RewardPSTHs, 1)], RewardPSTHs, zrange);
colormap('hot')

line([0 0], [0.5 size(RewardPSTHs, 1)+0.5], 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
xlabel('reward') 
yloc = get(ha10, 'position'); 
yboundfinal = sum(yloc([1, 3]))+0.1;
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [yboundfinal, 12.5, 0.2 1.5])


%% plot spk information
ha11 =  axes('unit', 'centimeters', 'position', [ybound 1.5 5 10], 'nextplot', 'add', 'xlim', [0 10],...
    'ylim', [-2 length(ind_plot)+4]);

text(1,length(ind_plot)+3, PSTHOut.Name)
text(1, length(ind_plot)+2, strrep(PSTHOut.Session, '_', '-'))

% ind_plot

for i=1:length(ind_plot)
    unit_i = ' ';
    if PSTHOut.Units(ind_plot(i), 3)==1;
        unit_i = 's';
    elseif PSTHOut.Units(ind_plot(i), 3)==2;
        unit_i = 'm';
    end;
    text(1, size(PSTHOut.Units, 1)+1-i, sprintf('N#%2.0d, Ch%2.0d, Unit%2.0d, Type %s ', i, PSTHOut.Units(ind_plot(i), 1), PSTHOut.Units(ind_plot(i), 2), unit_i),...
        'fontsize', 8);
end;

axis off

thisFolder = fullfile('A:\Ephys\UnitsCollection', PSTHOut.Name);
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['PopulationActivity' '_' PSTHOut.Name '_' strrep(PSTHOut.Session, '-', '_')]);

print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

thisFolder = fullfile(pwd, 'Fig');

if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder, ['PopulationActivity' '_' PSTHOut.Name '_' strrep(PSTHOut.Session, '-', '_')]);

print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)
print (gcf,'-depsc2', tosavename);

