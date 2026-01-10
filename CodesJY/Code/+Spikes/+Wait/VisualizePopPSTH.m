function IndSortAll = VisualizePopPSTH(Pop)

% 5/14/2023 revised JY

% IndSort = PSTHOut.IndSort;
% IndSignificant = PSTHOut.IndSignificant;
% nsig = sum(IndSignificant);
IndSortAll = Pop.IndSort;
for ib = 1 : length(Pop.IndSort)

IndSort = Pop.IndSort{ib};
n_unit  = length(IndSort);

if size(Pop.Units, 2) >= 5
    idx_units = find(Pop.Units(:, 5) == ib);
else
    idx_units = 1:size(Pop.Units, 1);
end

idx_units =  idx_units+1;
% visualize PSTH (z score)
zrange              = [-4 4];
pval_pop           = zeros(1, n_unit);
tpeaks_pop      = zeros(1, n_unit);
% n_unit               = size(Pop.Units, 1);
nFP                  = length(Pop.Press);
indFP                = [nFP nFP-1];
MixedFPs        = Pop.FPs;

press_col = [5 191 219]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
reward_col = [164, 208, 164]/255;
FP_cols = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;

% IndSort = Pop.IndSort;
nsig = n_unit - length(Pop.IndUnmodulated{ib});

PressPSTHs = cell(1, length(Pop.Press));
PressPSTHZs = cell(1, length(Pop.Press));
tPressPSTHs = cell(1, length(Pop.Press));
ReleasePSTHZs = cell(1, length(Pop.Release));
ReleasePSTHs = cell(1, length(Pop.Release));
tReleasePSTHs = cell(1, length(Pop.Release));
TriggerPSTHs = cell(1, length(Pop.Release));
TriggerPSTHZs = cell(1, length(Pop.Release));
tTriggerPSTHs = cell(1, length(Pop.Release));
RewardPokePSTHs = cell(1, length(Pop.Reward));
RewardPokePSTHZs = cell(1, length(Pop.Reward));
tRewardPokePSTHs = cell(1, length(Pop.Reward));

for ifp = 1:nFP
    thisPSTH                            =       Pop.PressZ{ifp}(idx_units, :);
    PressPSTHZs{ifp}                 =       thisPSTH(IndSort, :);
    thisPSTH                            =       Pop.Press{ifp}(idx_units, :);
    PressPSTHs{ifp}                 =       thisPSTH(IndSort, :);
    tPressPSTHs{ifp}                =       Pop.PressZ{ifp}(1, :);

    thisPSTH                            =       Pop.ReleaseZ{ifp}(idx_units, :);
    ReleasePSTHZs{ifp}                 =       thisPSTH(IndSort, :);
    thisPSTH                            =       Pop.Release{ifp}(idx_units, :);
    ReleasePSTHs{ifp}                 =       thisPSTH(IndSort, :);
    tReleasePSTHs{ifp}                =       Pop.ReleaseZ{ifp}(1, :);

    thisPSTH                            =       Pop.TriggerZ{ifp}(idx_units, :);
    TriggerPSTHZs{ifp}               =       thisPSTH(IndSort, :);
    thisPSTH                            =       Pop.Trigger{ifp}(idx_units, :);
    TriggerPSTHs{ifp}                 =       thisPSTH(IndSort, :);
    tTriggerPSTHs{ifp}              =       Pop.TriggerZ{ifp}(1, :);

    thisPSTH                            =       Pop.RewardZ{ifp}(idx_units, :);
    RewardPokePSTHZs{ifp}               =       thisPSTH(IndSort, :);
    thisPSTH                            =       Pop.Reward{ifp}(idx_units, :);
    RewardPokePSTHs{ifp}                 =       thisPSTH(IndSort, :);
    tRewardPSTHs{ifp}              =       Pop.Reward{ifp}(1, :);

end; 

% Concatenate raw PSTH for computing normalized PSTHs
PSTH_Concatenate = cell(1, nFP);
PSTH_ConNorm = cell(1, nFP);
IndPress =  cell(1, nFP);
IndRelease = cell(1, nFP);
IndTrigger = cell(1, nFP);
IndReward = cell(1, nFP);
norm_range = [0 1];

for ifp = 1:length(Pop.Press)
    PSTH_Concatenate{ifp}      =      [PressPSTHs{ifp} TriggerPSTHs{ifp} ReleasePSTHs{ifp} RewardPokePSTHs{ifp}];
    PSTH_ConNorm{ifp}          =       normalize(PSTH_Concatenate{ifp}' , 'range', norm_range);
    PSTH_ConNorm{ifp}          =       PSTH_ConNorm{ifp}';
    IndPress{ifp}                       =       [1:size(PressPSTHs{ifp}, 2)];
    IndTrigger{ifp}                    =      IndPress{ifp}(end)+[1:size(TriggerPSTHs{ifp} ,2)];
    IndRelease{ifp}                    =      IndTrigger{ifp}(end)+[1:size(ReleasePSTHs{ifp}, 2)];    
    IndReward{ifp}                     =      IndRelease{ifp}(end)+[1:size(RewardPokePSTHs{ifp} ,2)];
end

%% Plot 
set_matlab_default;
mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
% visualize PSTH (z score) 
hf=48;
figure(hf); clf(hf)
set(gcf, 'unit', 'centimeters', 'position', [2 2 24 20], 'paperpositionmode', 'auto' ,'color', 'w')
size_factor = 1.5;
space = 0.1;
xlevel_start = 1.25;
% A. Press
ylevel_start = 2;
map_height = 3;
tRange = [tPressPSTHs{ifp}(1) 2000];
Width  = size_factor*diff(tRange)/2000;
for ifp = indFP
    ha_press(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_start ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height], 'nextplot', 'add',...
        'xlim', tRange, 'xtick', [-3500:500:2000],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
    if ifp == indFP(end)
        set(ha_press(ifp), 'xticklabel', [])
    else
        ylabel('Units')
        xlabel('Press (ms)')
    end;    
    PressPSTH_thisFP = PSTH_ConNorm{ifp}(:, IndPress{ifp});
    himage1 = imagesc(tPressPSTHs{ifp}, [1:n_unit], PressPSTH_thisFP, norm_range);
    colormap('Parula')
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', press_col, 'linestyle', ':', 'linewidth', 1.5);
    
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
    if ifp ==indFP(1)
        title(sprintf('Ntrials=%2.0d,FP < %2.0d ms', Pop.Trials(ifp) , max(MixedFPs)));
    else
        line([0 0]+MixedFPs(ifp), yrange, 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
        title(sprintf('Ntrials=%2.0d,FP = %2.0d ms', Pop.Trials(ifp) ,MixedFPs(ifp)));
    end
end
ylevel_now = ylevel_start+(map_height+0.5)*(length(indFP)-1)+map_height+0.5;
uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now  6 0.7],...
    'string', ['A. Normalized activity ([0-1])'], ...
    'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');
xlevel_now = xlevel_start + Width+space;

% Trigger
ylevel_start = 2;
map_height = 3;
tRange = [-600 500];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_release(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
    if ifp == indFP(end)
        set(ha_release(ifp), 'xticklabel', [])
    else
        xlabel('Trigger (ms)')
    end;    
    TriggerPSTH_thisFP = PSTH_ConNorm{ifp}(:, IndTrigger{ifp});
    imagesc(tTriggerPSTHs{ifp}, [1:n_unit], TriggerPSTH_thisFP, norm_range);
    colormap('Parula')
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'w', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
end
xlevel_now = xlevel_now + Width+space;

% Release
ylevel_start = 2;
map_height = 3;
tRange = [-600 tReleasePSTHs{1}(end)];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_release(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
    if ifp == indFP(end)
        set(ha_release(ifp), 'xticklabel', [])
    else
        xlabel('Release (ms)')
    end;    
    ReleasePSTH_thisFP = PSTH_ConNorm{ifp}(:, IndRelease{ifp});
    imagesc(tReleasePSTHs{ifp}, [1:n_unit], ReleasePSTH_thisFP, norm_range);
    colormap('Parula')
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'w', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
end
xlevel_now = xlevel_now + Width+space;

% Reward
ylevel_start = 2;
map_height = 3;
tRange = [-1000 tRewardPSTHs{1}(end)];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_reward(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
    if ifp == indFP(end)
        set(ha_reward(ifp), 'xticklabel', [])
    else
        xlabel('Reward (ms)')
    end    
    RewardPSTH_thisFP = PSTH_ConNorm{ifp}(:, IndReward{ifp});
    imagesc(tRewardPSTHs{ifp}, [1:n_unit], RewardPSTH_thisFP, norm_range);
    colormap('Parula')
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'w', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
 end
ylevel_now = ylevel_start+(map_height+0.5)*(length(indFP)-1)+map_height+0.5;
xloc = get(gca, 'position'); 
xboundbar= sum(xloc([1, 3]))+space;
% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_start, 0.25 3], 'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'normalized';
hcbar.Label.FontSize = 9;


%% Plot z scores
% Press
% A. Press
xlevel_start = xboundbar+2.5;
ylevel_start = 2;
map_height = 3;
tRange = [tPressPSTHs{1}(1) 2000];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP
    ha_press(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_start ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height], 'nextplot', 'add',...
        'xlim', tRange, 'xtick', [-3500:500:2000],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
    colormap(ha_press(ifp), mycolormap);
    if ifp == indFP(end)
        set(ha_press(ifp), 'xticklabel', [])
    else
        ylabel('Units')
        xlabel('Press (ms)')
    end;
    imagesc(tPressPSTHs{ifp} , [1:n_unit],  PressPSTHZs{ifp}, zrange);
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', press_col, 'linestyle', ':', 'linewidth', 1.5);
    
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
    if ifp ==indFP(1)
        title(sprintf('Ntrials=%2.0d,FP < %2.0d ms', Pop.Trials(ifp) , max(MixedFPs)));
    else
        line([0 0]+MixedFPs(ifp), yrange, 'color', 'm', 'linestyle', ':', 'linewidth', 1.5)
        title(sprintf('Ntrials=%2.0d,FP = %2.0d ms', Pop.Trials(ifp) ,MixedFPs(ifp)));
    end
end

ylevel_now = ylevel_start+(map_height+0.5)*(length(indFP)-1)+map_height+0.5;
uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now  6 0.7],...
    'string', ['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']'], ...
    'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');
 xlevel_now = xlevel_start + Width+space;

 % Trigger
ylevel_start = 2;
map_height = 3;
tRange = [-600 500];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_release(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
       colormap(ha_release(ifp), mycolormap);
    if ifp == indFP(end)
        set(ha_release(ifp), 'xticklabel', [])
    else
        xlabel('Trigger (ms)')
    end;
    imagesc(tTriggerPSTHs{ifp} , [1:n_unit],  TriggerPSTHZs{ifp}, zrange);
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'k', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75);
end
xlevel_now = xlevel_now + Width+space;

% Release
ylevel_start = 2;
map_height = 3;
tRange = [-600 tReleasePSTHs{1}(end)];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_release(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
       colormap(ha_release(ifp), mycolormap);
    if ifp == indFP(end)
        set(ha_release(ifp), 'xticklabel', [])
    else
        xlabel('Release (ms)')
    end;
    imagesc(tReleasePSTHs{ifp} , [1:n_unit],  ReleasePSTHZs{ifp}, zrange);
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'k', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75);
end
xlevel_now = xlevel_now + Width+space;

% Reward
ylevel_start = 2;
map_height = 3;
tRange = [-1000 tRewardPSTHs{1}(end)];
Width  = size_factor*diff(tRange)/2000;
for ifp =indFP    
    ha_reward(ifp) = axes('unit', 'centimeters', 'position',...
        [xlevel_now ylevel_start+(map_height+0.6)*(nFP-ifp)  Width map_height],...
        'nextplot', 'add', 'xlim', tRange, 'xtick', [-500:500:2000],'ytick', [], 'yticklabel', [],...
        'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
       colormap(ha_reward(ifp), mycolormap);
    if ifp == indFP(end)
        set(ha_reward(ifp), 'xticklabel', [])
    else
        xlabel('Reward (ms)')
    end;
     imagesc(tRewardPSTHs{ifp}, [1:n_unit], RewardPokePSTHZs{ifp}, zrange);
    yrange = [0.5 n_unit+0.5];
    line([0 0], yrange, 'color', 'w', 'linestyle', ':', 'linewidth', 1.5);
    plotshaded([get(gca, 'xlim')], [nsig+.5 nsig+.5; n_unit+0.5 n_unit+0.5],  'w', 0.75)
end
xlevel_now = xlevel_now + Width+space;
xloc = get(gca, 'position'); 
xboundbar= sum(xloc([1, 3]))+0.1;

% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_start, 0.25 3], 'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'z score';
hcbar.Label.FontSize = 9;

ylevel_now = ylevel_start+(map_height+0.5)*(length(indFP)-1)+map_height+2;

%% add unit table

% write the info to a csv table. 
% number of sorted units in this experiment-this is also the number of
% rows
n_unit = length(IndSort);
% anm name
Name = repmat(Pop.Name, n_unit, 1);
% session
Session =  repmat(Pop.Date, n_unit, 1);

% Sorting order
Chs              =     zeros(n_unit, 1);
Ch_Units         =     zeros(n_unit, 1);
Unit_Quality_Num =   zeros(n_unit, 1);
Unit_Quality     =     cell(n_unit, 1);
% IndUnmodulated
SignificantMod = ones(n_unit, 1);
SignificantMod(Pop.IndUnmodulated{ib}) = 0;
Unit_Sorted      =     Pop.IndSort{ib}';

for i =1:length(Pop.IndSort{ib})
    iCode = Pop.Units(Pop.IndSort{ib}(i), :);
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
% aGoodName = ['PopOut', Pop.Name, '_' Pop.Session '.csv'];
% writetable(tab, aGoodName)
% % open this table
% try
%     winopen(aGoodName)
% end;

% Insert table
table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num SignificantMod];
htable = uitable(hf, 'unit', 'centimeters','Data', table_data,...
    'ColumnName', {'Unit|Sorted', 'Channel', 'Unit|Channel',  'Quality', 'StatSignificant'},...,
    'Position', [1 ylevel_now 8 3], 'ColumnWidth',{50, 50, 50, 50, 100});

% Add information
if ~isfield(Pop, 'UnitsColumn5')
    str_this = [Pop.Name ' | ' strrep(Pop.Session, '_', '-') ' | ' Pop.Protocol];
else
    str_this = [Pop.Name ' | ', Pop.UnitsColumn5{ib} ' | ' strrep(Pop.Session, '_', '-') ' | ' Pop.Protocol];
end

uicontrol('Style','text','Units','centimeters','Position',[10 ylevel_now  6 2],...
    'string', str_this, ...
    'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 12,'BackgroundColor','w')

% Re-adjust figure height
fig_height = ylevel_now + 3+0.5;
 
figsize = get(hf, 'Position');
figsize(4) = fig_height;
set(hf, 'Position', figsize)

%% Save this figure
thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end
if ~isfield(Pop, 'UnitsColumn5')
    tosavename= fullfile(thisFolder, ['PopulationActivity' '_' Pop.Name '_' strrep(Pop.Session, '_', '')]);
else
    tosavename= fullfile(thisFolder, ['PopulationActivity' '_' Pop.Name '_' Pop.UnitsColumn5{ib} '_' strrep(Pop.Session, '_', '')]);
end
disp('########## making figure ########## ')
tic
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)
print (gcf,'-depsc2', tosavename);
toc
try
    thisFolder = fullfile(findonedrive, '00_Work' , '03_Projects', '05_Physiology', 'Data', 'PopulationPSTH', Pop.Name);
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    disp('##########  copying figure ########## ')
    tic
    copyfile([tosavename '.png'], thisFolder)
    copyfile([tosavename '.eps'], thisFolder)
    toc
end

end