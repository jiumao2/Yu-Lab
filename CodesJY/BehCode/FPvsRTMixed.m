function FPvsRTMixed(bMixedFPs, RTrange, name, FPMixed)
% 2020.1.28: use geometrical mean only
if nargin<4
    FPMixed = [.5 1 1.5]*1000;
    if nargin<3
        RTrange = [250 500];
        if nargin<2
            name = [];
        end;
    end;
end;
nFP = length(FPMixed);
RTmin = 50;   % minimal RT

Performance = zeros (4, length(FPMixed)); 

% row 1: trial num
% row 2: correct num
% row 3: premature num
% row 4: late num

% Collection of press durations
RT_FPMixed          =   cell(1, length(FPMixed));
Premature_FPMixed   =   cell(1, length(FPMixed));
Late_FPMixed        =   cell (1, length(FPMixed));
PressDur_FPMixed    =   cell(1, length(FPMixed));

RTevo_FPMixed          =   cell(length(FPMixed), length(FPMixed));  % change of RT as a function of FP


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
        
        RTevo_FPMixed{j, i} = -FPMixed(j)/1000+b.ReleaseTime(ind_FPcorrect)-b.PressTime(ind_FPcorrect);
        
        % early
        [ind_FPearly, ~]        =   intersect(ind_FP, b.Premature);
        Performance(3, j)       =   Performance(3, j)+length(ind_FPearly);
        Premature_FPMixed{j}    =   [Premature_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPearly)-b.PressTime(ind_FPearly)];
        
        % late
        [ind_FPlate, ~]         =   intersect(ind_FP, b.Late);
        Performance(4, j)       =   Performance(4, j)+length(ind_FPlate);
        Late_FPMixed{j}         =   [Late_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];
        
    end;
    
end;

%% plot the changes of RT over sessions
figure(22); clf(22)
set(gcf, 'unit', 'centimeters', 'position',[2 2 12 8], 'paperpositionmode', 'auto' )
ha=axes; set(ha, 'nextplot', 'add', 'xlim', [0 size(RTevo_FPMixed, 2)+1], 'ylim', [100 500])

for j = 1:size(RTevo_FPMixed, 1)  % FPx
    for i = 1:size(RTevo_FPMixed, 2) % different sessions
        
        RTij= RTevo_FPMixed{j, i}*1000;
        RTevomean(j, i)=mean(RTij);
        RTstdij = std(RTij);
        %         % 95 confidence intervals
        try
            ci95ij=bootci(1000, {@mean, RTij}, 'type','per');
            %
            line([i i],ci95ij, 'color', 'b', 'linewidth', 1)
        end;
        
    end;
    plot([1:size(RTevo_FPMixed, 2)], RTevomean(j, :), 'o-', 'markersize', 5, 'linewidth', 0.5*j, 'color', 'k');
end;

xlabel ('Sessions')
ylabel ('Reaction time (ms)')

RTMixed.Evo = RTevo_FPMixed;

savename = ['MixedFPs_'  upper(bMixedFPs(1).Metadata.SubjectName) '_Evo' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

%5

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 18], 'paperpositionmode', 'auto' )

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

 
ylabel('Fraction')
 

%% distribution of press duration

edges = [0:100:3000];
edge_centers = mean(edges(1:end-1), edges(2:end));
press_distr=zeros(length(FPMixed), length(edge_centers));

for i = 1:length(FPMixed)
    
    [press_distr(i, :)] = histcounts(PressDur_FPMixed{i}*1000, edges);
    
    ha2(i)=axes('unit', 'centimeters', 'position', [10+4*(i-1) 2 3 4], 'nextplot', 'add',...
        'xlim', [0 3000], 'ylim', [0 500], 'xtick', [0:1000:3000], 'ticklength', [.02 .025])
    
    plot(edge_centers, press_distr(i, :), 'k', 'linewidth', 1)
    
    line([FPMixed(i) FPMixed(i)], [0 500], 'color', 'c', 'linewidth', 1, 'linestyle', ':')
    
    if i==1
        xlabel('Press duration (ms)')
        ylabel('Counts')
    end;
end;


%% plot successful press release and reaction time
ha3=axes('unit', 'centimeters', 'position', [2 8 6 4], 'nextplot', 'add', 'xlim', [0.5 3.5],...
 'ylim', [0 600], 'xtick', [])

AllRT=cell(1, length(FPMixed));
RTcat=[];
            
for i = 1:length(FPMixed)
        RTi = RT_FPMixed{i}*1000;
        RTi = RTi(RTi>RTmin);
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

ha4=axes('unit', 'centimeters', 'position', [2 13 6 2], 'nextplot', 'add', 'xlim', [0.5 3.5], 'ylim', [0 600], 'xtick', [1 2 3], 'xticklabel', [])
ci95=[];

RTgeomean = zeros(1, length(FPMixed));
RTsimplemean = zeros(1, length(FPMixed));

for i = 1:length(FPMixed)
    
    RTi = RT_FPMixed{i}*1000;
    RTi = RTi(RTi>RTmin);
    
    RTgeomean(i)=geomean(RTi);
    geoci95 (i, :) = geoci(RTi);
    
    
    RTsimplemean(i)=mean(RTi);
    simpleci95 (i, :) = simpleci(RTi);
    
    axes(ha3)
    line([-0.25 .25]+i, [RTgeomean(i) RTgeomean(i)], 'color', 'k', 'linewidth', 2)
        line([-0.25 .25]+i, [RTsimplemean(i) RTsimplemean(i)], 'color', 'k', 'linewidth', 2)

    axes(ha4)
    line([i i], geoci95(i, :), 'color', 'b', 'linewidth', 1)
    line([i i], simpleci95(i, :), 'color', 'b', 'linewidth', 1)

end;

plot([1:length(FPMixed)], RTgeomean, 'ko-', 'linewidth', 1)
plot([1:length(FPMixed)], RTsimplemean, 'ro-', 'linewidth', 1)


axis 'auto y'

if diff(get(ha4, 'ylim'))<50
    set(ha4, 'ylim', mean(get(ha4, 'ylim'))+[-25 25])
end;

RTMixed.FPs                   =    FPMixed;
RTMixed.RTmean_geo   =    RTgeomean;
RTMixed.RTci_geo          =   geoci95;
RTMixed.RTmean_simple   =    RTsimplemean;
RTMixed.RTci_simple          =   simpleci95;
RTMixed.RTall                 = RT_FPMixed;

%% FP and previous trial
% if last trial is a failure, it won't count

RT_history= cell(length(FPMixed), length(FPMixed));
ncount = 0;

try
for i = 1:length(bMixedFPs)
    b = bMixedFPs(i);
    ind_mixed = [find(b.FPs==1400, 1, 'last') + 1 : length(b.FPs)];
    
    for j = 2:length(ind_mixed)
        indj=ind_mixed(j);  %
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Correct==indj-1))  % both current and last presses have to be correct
            
            indFP=      find(FPMixed == b.FPs(indj)); % which FP it is
            indFPlast=  find(FPMixed == b.FPs(indj-1)); % which FP it is
            
            RTij = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - b.FPs(indj);
            %             if RTij>150
            RT_history{indFPlast, indFP} = [RT_history{indFPlast, indFP} RTij];
            %             end;
            ncount = ncount + 1;
            
            
        end;
    end;
end;

meanRT=zeros(nFP, nFP);  % history x current
ciRT = zeros(nFP, nFP, 2);

for i = 1:nFP  % history
    
    ha5(i)=axes('unit', 'centimeters', 'position', [10 8+2.8*(i-1) 5 2],...
        'nextplot', 'add', 'xlim', [250 2000],'xtick', [500:500:1500], 'ylim', RTrange)
   
    for j = 1:nFP  % current
        
        RT_history_ij = RT_history{i, j};
        RT_history_ij = RT_history_ij(RT_history_ij>0);
        
        meanRT(i, j) = geomean(RT_history_ij);
        
         ciRT(i, j, :)  = geoci(RT_history_ij);
        
        ciRTj = squeeze(ciRT(i, j, :));
        line([FPMixed(j) FPMixed(j)], ciRTj , 'color', 'b', 'linewidth', 1)
    end;
    
    plot(FPMixed, meanRT(i, :), 'ko',  'linewidth',1)
    plot(FPMixed, meanRT(i, :), 'k-',  'linewidth', i*0.5)
    
    title (['FPlast: ' sprintf('%2.0d',FPMixed(i)) 'ms'], 'fontsize', 8)
    
    if i==1
        xlabel('FP (ms)')
    end
    
    if i==2
        ylabel('Reaction time (ms)')
    end;
end;


ha7=axes('unit', 'centimeters', 'position', [16.5 8 5 5],...
    'nextplot', 'add', 'xlim', [250 2000], 'xtick', [500:500:2000], 'ylim', RTrange, 'ytick', [200:50:500])

for i = 1:nFP
    
    for j = 1:nFP  % current
        ciRTj = squeeze(ciRT(i, j, :));
        line([FPMixed(j) FPMixed(j)], ciRTj, 'color', 'b', 'linewidth', 1)
    end;
    
    plot(FPMixed, meanRT(i, :), 'ko',  'linewidth',1)
    plot(FPMixed, meanRT(i, :), 'k-',  'linewidth', i*0.5)
    
end;
xlabel ('FP (ms)')
ylabel ('RT (ms)')

RTMixed.RTHistory = RT_history;
RTMixed.SequentialRTmean_geo = meanRT;
RTMixed.SequentialRTci_geo = ciRT;

ha8=axes('unit', 'centimeters', 'position', [16.5 13.5 4 4],...
    'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 20])

for i = 1:length(bMixedFPs)
    text(0, i, [sprintf('%2.0d) ', i) bMixedFPs(i).SessionName], 'fontsize', 6)
    
end

axis off

axis 'auto y'
end;

savename = ['MixedFPs_'  upper(bMixedFPs(1).Metadata.SubjectName) '_Results' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')

savename = ['RTMixed_' upper(bMixedFPs(1).Metadata.SubjectName) name];
save (savename, 'RTMixed')


