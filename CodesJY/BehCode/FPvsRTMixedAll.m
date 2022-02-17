function FPvsRTMixedAll(bMixedFPs, name, FPMixed)
% 1.28.2020  use geometrical mean
% plot reaction time vs FP, including both correct and immature responses

if nargin<3
    FPMixed = [.5 1 1.5]*1000;
    if nargin<2
        name = [];
    end;
end;

nFP = length(FPMixed);
RTmin = 100;   % minimal RT

Performance = zeros (4, length(FPMixed)); 

% row 1: trial num
% row 2: correct num
% row 3: premature num
% row 4: late num

% Collection of press durations
RT_FPMixed          =   cell(1, length(FPMixed));
EarlyRT_FPMixed     =   cell(1, length(FPMixed));  % not really reaction time, negative number
LateRT_FPMixed      =   cell(1, length(FPMixed));

Premature_FPMixed   =   cell(1, length(FPMixed));
Late_FPMixed        =   cell (1, length(FPMixed));
PressDur_FPMixed    =   cell(1, length(FPMixed));


for i = 1:length(bMixedFPs)
    b = bMixedFPs(i);
    ind_mixed = [find(b.FPs==1400, 1, 'last') + 1 : length(b.FPs)];
    for j = 1:length(FPMixed)
        
        ind_FP                  =   find(b.FPs == FPMixed(j));  % includes all presses
        Performance(1, j)       =   Performance(1, j)+length(ind_FP);
        PressDur_FPMixed{j}     =   [PressDur_FPMixed{j} -b.PressTime(ind_FP)+b.ReleaseTime(ind_FP)];
        
        % correct 
        [ind_FPcorrect, ~]      =   intersect(ind_FP, b.Correct);
        Performance(2, j)       =   Performance(2, j)+length(ind_FPcorrect);
        RT_FPMixed{j}           =   [RT_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPcorrect)-b.PressTime(ind_FPcorrect)];
        
        % early
        [ind_FPearly, ~]        =   intersect(ind_FP, b.Premature);
        Performance(3, j)       =   Performance(3, j)+length(ind_FPearly);
        Premature_FPMixed{j}    =   [Premature_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPearly)-b.PressTime(ind_FPearly)];
        EarlyRT_FPMixed{j}      =   [EarlyRT_FPMixed{j}  -FPMixed(j)/1000+b.ReleaseTime(ind_FPearly)-b.PressTime(ind_FPearly)];
        
        % late
        [ind_FPlate, ~]         =   intersect(ind_FP, b.Late);
        Performance(4, j)       =   Performance(4, j)+length(ind_FPlate);
        Late_FPMixed{j}         =   [Late_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];
        LateRT_FPMixed{j}       =   [LateRT_FPMixed{j}  -FPMixed(j)/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];

    end;
    
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 17], 'paperpositionmode', 'auto' )

%% fraction of different trial outcomes
ha1=axes('unit', 'centimeters', 'position', [2 2 6 4], 'nextplot', 'add', 'xlim', [0 12], 'ylim', [0 1], 'xtick', [])

for i = 1:length(FPMixed)
    hb1=bar(1+4*(i-1), Performance(2, i)/sum(Performance([2:4], i)));
    set(hb1, 'facecolor', correct_col, 'edgecolor', 'k');
    
    hb2=bar(2+4*(i-1), Performance(3, i)/sum(Performance([2:4], i)), 'r');
    set(hb2, 'facecolor', premature_col, 'edgecolor', 'k');
    
    hb3=bar(3+4*(i-1), Performance(4, i)/sum(Performance([2:4], i)), 'k');
    set(hb3, 'facecolor', late_col, 'edgecolor', 'k');
    
    text(.5+4*(i-1), 0.95, sprintf( 'FP %2.0d ms', FPMixed(i)), 'fontsize', 8)
    
end;
title(bMixedFPs(1).Metadata.SubjectName)


%% distribution of press duration

edges = [0:100:3000];
edge_centers = mean(edges(1:end-1), edges(2:end));
press_distr=zeros(length(FPMixed), length(edge_centers));

press_max = 0;

for i = 1:length(FPMixed)
    
    [press_distr(i, :)] = histcounts(PressDur_FPMixed{i}*1000, edges);
    
    ha2(i)=axes('unit', 'centimeters', 'position', [10+4*(i-1) 2 3 4], 'nextplot', 'add',...
        'xlim', [0 3000], 'ylim', [0 400], 'xtick', [0:1000:3000], 'ticklength', [.02 .025])
    
    plot(edge_centers, press_distr(i, :), 'k', 'linewidth', 1)
     
    line([FPMixed(i) FPMixed(i)], [0 500], 'color', 'm', 'linewidth', 1, 'linestyle', ':')
    line([FPMixed(i) FPMixed(i)]+600, [0 500], 'color', 'm', 'linewidth', 1, 'linestyle', ':')

    if i==1
        xlabel('Press duration (ms)')
        ylabel('Counts')
    end;
end;

press_max = max(press_distr(:));

for i =  1:length(FPMixed)
    set(ha2(i), 'ylim', [0 press_max*1.25])
end;


%% plot all release time
ha3allpress=axes('unit', 'centimeters', 'position', [10 8 11 8], 'nextplot', 'add', 'xlim', [0.5 3.5],...
 'ylim', [-500 1100], 'xtick', [])

AllReleaseTime=cell(1, length(FPMixed));
ReleaseCat = [];
for i = 1:length(FPMixed)
    AllReleaseTime{i}=PressDur_FPMixed{i}*1000-FPMixed(i);
    ReleaseCat =[ReleaseCat; i*ones(length(AllReleaseTime{i}), 1)];
end;

if length(AllReleaseTime)==3
    plotSpread(AllReleaseTime, 'categoryIdx', ReleaseCat, 'spreadWidth',.6, 'categoryMarkers',{'.','.','.'},'categoryColors', {[.8 .8 .8], [.8 .8 .8], [.8 .8 .8]})
    set(ha3allpress, 'xlim', [0.25 3.75], 'xticklabel', {num2str(FPMixed(1)), num2str(FPMixed(2)), num2str(FPMixed(3))})
    
else
    plotSpread(AllReleaseTime, 'categoryIdx', ReleaseCat, 'spreadWidth',.6, 'categoryMarkers',{'.','.'},'categoryColors', {[.8 .8 .8], [.8 .8 .8]})
    set(ha3allpress, 'xlim', [0.25 3.75], 'xticklabel', {num2str(FPMixed(1)), num2str(FPMixed(2))})
    
end;

line([0 4], [0 0], 'color', 'm', 'linewidth', 1, 'linestyle', ':')
line([0 4], [600 600], 'color', 'm', 'linewidth', 1, 'linestyle', ':')

ylabel('Release-Trigger (ms)')
xlabel ('FP (ms)')

title(name)

%% plot successful press release and reaction time
ha3=axes('unit', 'centimeters', 'position', [2 8 6 5], 'nextplot', 'add', 'xlim', [0.5 3.5],...
 'ylim', [0 600], 'xtick', [])

AllRT=cell(1, length(FPMixed));

RTcat=[];

for i = 1:length(FPMixed)
    
    RTi = RT_FPMixed{i}*1000;
    AllRT{i}=RTi;
    RTcat=[RTcat; i*ones(length(RTi), 1)];
    
end;


if length(AllRT)==3
    plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.7, 'categoryMarkers',{'.','.','.'},'categoryColors', {[.8 .8 .8], [.8 .8 .8], [.8 .8 .8]})
    set(ha3, 'xlim', [0.25 3.75], 'xticklabel', {num2str(FPMixed(1)), num2str(FPMixed(2)),  num2str(FPMixed(3))})
else
    plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.7, 'categoryMarkers',{'.','.'},'categoryColors', {[.8 .8 .8], [.8 .8 .8]})
    set(ha3, 'xlim', [0.25 3.75], 'xticklabel', {num2str(FPMixed(1)), num2str(FPMixed(2))})
end;
 
ylabel('Reaction time (ms)')
xlabel ('FP (ms)')

ha4=axes('unit', 'centimeters', 'position', [2 14 6 2], 'nextplot', 'add', 'xlim', [0.5 3.5], 'ylim', [0 600], 'xtick', [1 2 3], 'xticklabel', [])
ci95=[];
for i = 1:length(FPMixed)
    RTi = RT_FPMixed{i}*1000;
    RTi = RTi(RTi>RTmin);
    
    RTmean(i)=geomean(RTi);
    ci95 (i, :) = geoci(RTi)
    
    axes(ha3)
    line([-0.25 .25]+i, [RTmean(i) RTmean(i)], 'color', 'k', 'linewidth', 2)
    plot(i, RTmean(i), 'ko', 'linewidth', 2)
    
    axes(ha4)
    line([i i], ci95(i, :), 'color', 'b', 'linewidth', 1)
    
end;

plot([1:length(FPMixed)], RTmean, 'ko-', 'linewidth', 1)

set(ha4, 'ylim', [250 350])
axis 'auto y'

if diff(get(gca, 'ylim'))<50
    set(gca, 'ylim', [-25 25]+mean(get(gca, 'ylim')))
end;

axes(ha3allpress)
plot([1:length(FPMixed)], RTmean, 'ko', 'linewidth', 2)

RTMixed.FPs           =    FPMixed;
RTMixed.PressDurs =  PressDur_FPMixed;
RTMixed.RT              = RT_FPMixed;
RTMixed.Performance = Performance;

savename = ['RTMixedAll_' upper(bMixedFPs(1).Metadata.SubjectName) name];
save (savename, 'RTMixed')

savename = ['MixedFPs_'  upper(bMixedFPs(1).Metadata.SubjectName) name '_Results2'];

print (gcf,'-dpng', [savename])