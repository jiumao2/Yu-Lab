function TrackingError(bFPs,  name)

if nargin<2
    name = [];
end;

FPMixed = [.5 1 1.5]*1000;
nFP = length(FPMixed);
RTmin = 150;   % minimal RT

Performance = zeros (4, 1);

% row 1: trial num
% row 2: correct num
% row 3: premature num
% row 4: late num

% Collection of press durations
RT_FPfixed                  =   [];
Premature_FPfixed           =   [];
Late_FPfixed                =   [];
PressDur_FPfixed            =   [];

%% successive performance:

SlidingPerformance = cell (1, length(bFPs));  % calculating performance every 20 presses, step 5

for i = 1:length(bFPs)
    b = bFPs(i);
    
    allFPs=b.FPs;
    diff_allFPs = diff(allFPs);
    
    ind_regular =  [find(abs(diff_allFPs)>0, 1, 'last')+1:length(allFPs)];
    
    count = 0;
    
    while count + 25<length(ind_regular)
        
        ind_window = ind_regular (count+1:count+25);
        
        n_correct= length(intersect(ind_window, b.Correct));
        n_premature= length(intersect(ind_window, b.Premature));
        n_late= length(intersect(ind_window, b.Late));
        
        SlidingPerformance{i}=[SlidingPerformance{i} n_correct/(n_correct+n_premature+n_late)];
        
        count =count +5;
    end;
    
    FPfixed = unique(b.FPs(ind_regular));
    
    ind_FP                      =   find(b.FPs(ind_regular) == FPfixed);  % includes all presses
    ind_FP                       =    ind_regular(ind_FP);
    
    Performance(1)       =   Performance(1)+length(ind_FP);
    PressDur_FPfixed     =   [PressDur_FPfixed -b.PressTime(ind_FP)+b.ReleaseTime(ind_FP)];
    
    % correct
    [ind_FPcorrect, ~]      =   intersect(ind_FP, b.Correct);
    Performance(2)       =   Performance(2)+length(ind_FPcorrect);
    RT_FPfixed           =   [RT_FPfixed -FPfixed/1000+b.ReleaseTime(ind_FPcorrect)-b.PressTime(ind_FPcorrect)];
    
    % early
    [ind_FPearly, ~]        =   intersect(ind_FP, b.Premature);
    Performance(3)       =   Performance(3)+length(ind_FPearly);
    Premature_FPfixed   =   [Premature_FPfixed -FPfixed/1000+b.ReleaseTime(ind_FPearly)-b.PressTime(ind_FPearly)];
    
    % late
    [ind_FPlate, ~]         =   intersect(ind_FP, b.Late);
    Performance(4)       =   Performance(4)+length(ind_FPlate);
    Late_FPfixed         =   [Late_FPfixed -FPfixed/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];
    
    
end;


correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',[2 2 21 18], 'paperpositionmode', 'auto' )

%% fraction of different trial outcomes
ha1=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0  4], 'ylim', [0 1], 'xtick', [])

hb1=bar(1, Performance(2)/Performance(1));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k');

hb2=bar(2, Performance(3)/Performance(1), 'r');
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k');

hb3=bar(3, Performance(4)/Performance(1), 'k');
set(hb3, 'facecolor', late_col, 'edgecolor', 'k');

text(2, 0.95, sprintf('FP%2.0d ms', FPfixed), 'fontsize', 8)

ylabel('Fraction')


%% distribution of press duration

edges = [0:50:3000];
edge_centers = mean(edges(1:end-1), edges(2:end));
press_distr=zeros(length(FPMixed), length(edge_centers));

i = 1;

[press_distr] = histcounts(PressDur_FPfixed*1000, edges);

ha2(i)=axes('unit', 'centimeters', 'position', [10 2 3 5], 'nextplot', 'add',...
    'ylim', [0 3000], 'xlim', [0 500], 'ytick', [0:1000:3000], 'ticklength', [.02 .025])

plot(press_distr, edge_centers,  'k', 'linewidth', 1)

axis 'auto x'

line(get(gca, 'xlim'), [FPfixed FPfixed],  'color', 'c', 'linewidth', 1, 'linestyle', ':')
line(get(gca, 'xlim'),[FPfixed FPfixed]+600,  'color', 'c', 'linewidth', 1, 'linestyle', ':')


if i==1
    ylabel('Press duration (ms)')
    xlabel('Counts')
end;

%% plot all release time
ha3=axes('unit', 'centimeters', 'position', [15 2 4 5], 'nextplot', 'add', 'xlim', [0.5 1],...
    'ylim', [0-FPfixed 3000-FPfixed], 'xtick', [])

AllReleaseTime=[];
ReleaseCat = [];

AllReleaseTime=PressDur_FPfixed*1000-FPfixed;
ReleaseCat =[ones(length(AllReleaseTime), 1)];

plotSpread({AllReleaseTime}, 'categoryIdx', [ReleaseCat], 'spreadWidth',.6, 'categoryMarkers',{'.'},'categoryColors', {[0 0 0]})

line([0 4], [0 0], 'color', 'm', 'linewidth', 1, 'linestyle', ':')
line([0 4], [600 600], 'color', 'm', 'linewidth', 1, 'linestyle', ':')

set(ha3, 'xlim', [0.25  1.75], 'xticklabel', {'500', '1000', '1500'})
ylabel('Release-Trigger (ms)')
xlabel ('FP (ms)')


%% plot successful press release and reaction time
ha3=axes('unit', 'centimeters', 'position', [2 9 3 5], 'nextplot', 'add', 'xlim', [0.5 1.5],...
    'ylim', [0 600], 'xtick', [])

AllRT={};
RTcat=[];

i=1;
RTi = RT_FPfixed*1000;
AllRT{i}=RTi;
RTcat=[RTcat; i*ones(length(RTi), 1)];

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.7, 'categoryMarkers',{'.'},'categoryColors', {[0.8 0.8 0.8]})
set(ha3, 'xlim', [0.25 1.75], 'xticklabel', {'500'})
ylabel('Reaction time (ms)')
xlabel ('FP (ms)')

ha4=axes('unit', 'centimeters', 'position', [2 14.5 3 2], 'nextplot', 'add', 'xlim', [0.5 1.5], 'ylim', [0 600], 'xtick', [1 2 3], 'xticklabel', [])
ci95=[];
i =1;
RTi = RT_FPfixed*1000;
RTi = RTi(RTi>0);

% RTmean(i)=mean(RTi);
% use geometrical mean

RTmean(i) = geomean(RTi);

try
    % 95 confidence intervals
    ci95(i, :)=bootci(1000, @geomean, RTi);
    
    axes(ha3)
    line([-0.25 .25]+i, [RTmean(i) RTmean(i)], 'color', 'k', 'linewidth', 2)
    axes(ha4)
    line([i i], ci95(i, :), 'color', 'b', 'linewidth', 1)
end

plot(1, RTmean, 'ko-', 'linewidth', 1)

axis 'auto y'

RTFixed.FPs           =    FPfixed;
RTFixed.RTmean_geo   =    RTmean;
RTFixed.RTci_geo          =   ci95;

%% FP after correct and error trials

RT_history= cell(1, 5);  
% 1. after a correct response, 
% 2. after one premature release, 
% 3. after one late response
% 4. after one premature or late response
% 5. after two correct responses

ncount = zeros(1, 5);

for i = 1:length(bFPs)
    b = bFPs(i);
    
    allFPs=b.FPs;
    diff_allFPs = diff(allFPs);
    
    ind_regular =  [find(abs(diff_allFPs)>0, 1, 'last')+1:length(allFPs)];
    
    for j = 2:length(ind_regular)
        indj=ind_regular(j);  %
        
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Correct==indj-1))  % both current and last presses have to be correct
            RT_current = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - FPfixed;
            RT_history{1} = [RT_history{1} RT_current];
            ncount(1)=ncount(1)+1;
        end;
        %
        
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Premature==indj-1))  % both current and last presses have to be correct
            RT_current = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - FPfixed;
            RT_history{2} = [RT_history{2} RT_current];
            ncount(2)=ncount(2)+1;
        end;
        
        
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Late==indj-1))  % both current and last presses have to be correct
            RT_current = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - FPfixed;
            RT_history{3} = [RT_history{3} RT_current];
            ncount(3)=ncount(3)+1;
        end;
        
        AllErrors = [b.Premature b.Late];
        
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(AllErrors==indj-1))  % both current and last presses have to be correct
            RT_current = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - FPfixed;
            RT_history{4} = [RT_history{4} RT_current];
            ncount(4)=ncount(4)+1;
        end;
        
        if j>3 && ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Correct==indj-1)) && ~isempty(find(b.Correct==indj-2))  % both current and last presses have to be correct
            RT_current = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - FPfixed;
            RT_history{5} = [RT_history{1} RT_current];
            ncount(5)=ncount(5)+1;
        end;
        
    end;
end;

RTFixed.HistoryTypes = {'Correct-Correct', 'Premature-Correct', 'Late-Correct', 'Error-Correct', 'Correct-Correct-Correct'};
RTFixed.RT_history = RT_history;


meanRT=zeros(1, 5);  % history x current
ciRT = zeros(5, 2);

ha5=axes('unit', 'centimeters', 'position', [6 9 6 5],...
    'nextplot', 'add', 'xlim', [0 6],'xtick', [0 6], 'ylim', [0 600], 'fontsize', 8)
RTcat =[];

RTall = [];
RTallNames = [];

for i =1:5
    RTcat=[RTcat; i*ones(length(RT_history{i}), 1)];
    RTall =[RTall; RT_history{i}']
    new_name = pad(RTFixed.HistoryTypes{i}, 30);
    RTallNames = [RTallNames; repmat(new_name, length(RT_history{i}), 1)];
    
end;

%% use RTall and RTallNames to derive statistics
figure(10); clf(10)
[p,t,stats] = anova1(RTall,RTallNames,'off');
[c,m,h,nms] = multcompare(stats);

RTFixed.RTall               = RTall;
RTFixed.RTallNames          = RTallNames;
RTFixed.stats.p             = p;
RTFixed.stats.t             = t;
RTFixed.stats.stats         = stats;
RTFixed.stats.c             = c;
RTFixed.stats.m             = m;
RTFixed.stats.h             = h;
RTFixed.stats.nms           = nms;

figure(21)
axes(ha5)
plotSpread(RT_history, 'categoryIdx', RTcat, 'spreadWidth',.7, 'categoryMarkers',{'.','.','.','.', '.'},...
    'categoryColors', {[0.8 0.8 0.8], [0.8 0.8 0.8], [0.8 0.8 0.8], [0.8 0.8 0.8], [0.8 0.8 0.8]})

ha5=axes('unit', 'centimeters', 'position', [6 14.5 6 2],...
    'nextplot', 'add', 'xlim', [0 6],'xtick', [1:5], 'ylim', [0 1000], 'xticklabel', {'correct', 'premt', 'late', 'errors', 'correctx2'})

for i =1:5
    RT_history_i = RT_history{i};
    RT_history_i = RT_history_i(RT_history_i>0);
    meanRT(i) = geomean(RT_history_i);
    ciRT(i, :)=bootci(1000, @geomean, RT_history_i);
    line([i i], ciRT(i, :) , 'color', 'b', 'linewidth', 1)
end;

plot([1:5], meanRT, 'ko',  'linewidth',1)

axis 'auto y'
title(bFPs(1).Metadata.SubjectName)

%% plot progress:

ha6=axes('unit', 'centimeters', 'position', [13.5 9 6 5],...
    'nextplot', 'add', 'xlim', [0 1000],'xtick', [0:20:1000], 'ylim', [0 1], 'fontsize', 8)
ncount =0;
plotcolor = {'c', 'm'};

for i = 1: length(SlidingPerformance)
    
    plot([1:length(SlidingPerformance{i})]+ncount, SlidingPerformance{i}, 'o-', 'linewidth', 1, 'markersize', 4, 'color', plotcolor{rem(i, 2)+1})
    ncount =ncount +length(SlidingPerformance{i})+5;
    
end;

axis 'auto x'
xmax = max(get(ha6, 'xlim'));
set(ha6, 'xtick', [0:xmax/5:xmax]);

xlabel ('Press blocks')
ylabel ('Performance')


savename = ['ErrorSignal_'  upper(bFPs(1).Metadata.SubjectName) '_Results' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])
saveas(gcf, savename, 'fig')

savename = ['RTFixed_' upper(bFPs(1).Metadata.SubjectName) name];
save (savename, 'RTFixed')