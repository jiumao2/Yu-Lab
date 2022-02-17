function FPvsRTMixedGeo(bMixedFPs)

% Using Geometric mean

FPMixed = [.5 1 1.5]*1000;
nFP = length(FPMixed);
RTmin = 150;   % minimal RT

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
        
        % late
        [ind_FPlate, ~]         =   intersect(ind_FP, b.Late);
        Performance(4, j)       =   Performance(4, j)+length(ind_FPlate);
        Late_FPMixed{j}         =   [Late_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];
        
    end;
    
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 18], 'paperpositionmode', 'auto' )

%% fraction of different trial outcomes
ha1=axes('unit', 'centimeters', 'position', [2 2 6 4], 'nextplot', 'add', 'xlim', [0 12], 'ylim', [0 1], 'xtick', [])

hb1=bar(1, Performance(2, 1)/Performance(1, 1));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k');

hb2=bar(2, Performance(3, 1)/Performance(1, 1), 'r');
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k');

hb3=bar(3, Performance(4, 1)/Performance(1, 1), 'k');
set(hb3, 'facecolor', late_col, 'edgecolor', 'k');
 
text(.5, 0.95, 'FP 500 ms', 'fontsize', 8)

hb1=bar(5, Performance(2, 2)/Performance(1, 2));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k');

hb2=bar(6, Performance(3, 2)/Performance(1, 2), 'r');
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k');

hb3=bar(7, Performance(4, 2)/Performance(1, 2), 'k');
set(hb3, 'facecolor', late_col, 'edgecolor', 'k');

text(5, 0.95, '1000 ms', 'fontsize', 8)

hb1= bar(9, Performance(2, 3)/Performance(1, 3))
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k');

hb2=bar(10, Performance(3, 3)/Performance(1, 3), 'r')
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k');

hb3=bar(11, Performance(4, 3)/Performance(1, 3), 'k')
set(hb3, 'facecolor', late_col, 'edgecolor', 'k');

text(9, 0.95, '1500 ms', 'fontsize', 8)

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
        
        AllRT{i}=RTi;
        RTcat=[RTcat; i*ones(length(RTi), 1)];

end;

plotSpread(AllRT, 'categoryIdx', RTcat, 'spreadWidth',.7, 'categoryMarkers',{'.','.','.'},'categoryColors', {[.8 .8 .8], [.8 .8 .8], [.8 .8 .8]})
set(ha3, 'xlim', [0.25 3.75], 'xticklabel', {'500', '1000', '1500'})
ylabel('Reaction time (ms)')
xlabel ('FP (ms)')

ha4=axes('unit', 'centimeters', 'position', [2 13 6 2], 'nextplot', 'add', 'xlim', [0.5 3.5], 'ylim', [0 600], 'xtick', [1 2 3], 'xticklabel', [])

for i = 1:length(FPMixed)
    RTi = RT_FPMixed{i}*1000;
    
    RTi = RTi(RTi>150);
    
    RTmean(i)=geomean(RTi);
    
    % 95 confidence intervals
    ci95(i, :)=bootci(1000, @geomean, RTi);
    
    RTstd(i)=std(RTi);
    axes(ha3)
    line([-0.25 .25]+i, [RTmean(i) RTmean(i)], 'color', 'k', 'linewidth', 2)
    axes(ha4)
    line([i i], ci95(i, :), 'color', 'b', 'linewidth', 1)
    
end;

plot([1 2 3], RTmean, 'ko-', 'linewidth', 1)

set(ha4, 'ylim', [250 350])

RTMixed.FPs           =    FPMixed;
RTMixed.RTmean   =    RTmean;
RTMixed.RTci          =   ci95;



%% FP and previous trial
% if last trial is a failure, it won't count

RT_history= cell(length(FPMixed), length(FPMixed));

for i = 1:length(bMixedFPs)
    b = bMixedFPs(i);
    ind_mixed = [find(b.FPs==1400, 1, 'last') + 1 : length(b.FPs)];
    
    for j = 2:length(ind_mixed)
        indj=ind_mixed(j);  %
        if ~isempty(find(b.Correct==indj)) && ~isempty(find(b.Correct==indj-1))  % both current and last presses have to be correct
            
            indFP=      find(FPMixed == b.FPs(indj)); % which FP it is
            indFPlast=  find(FPMixed == b.FPs(indj-1)); % which FP it is
            
            RTij = 1000*(b.ReleaseTime(indj) - b.PressTime(indj)) - b.FPs(indj);
            if RTij>150
                RT_history{indFPlast, indFP} = [RT_history{indFP, indFPlast} RTij];
            end;
            
        end;
    end;
end;

meanRT=zeros(nFP, nFP);  % history x current
ciRT = zeros(nFP, nFP, 2);

for i = 1:nFP  % history
    
    ha5(i)=axes('unit', 'centimeters', 'position', [10 8+2.8*(i-1) 5 2],...
        'nextplot', 'add', 'xlim', [250 1750],'xtick', [500:500:1500], 'ylim', [250 380])
   
    for j = 1:nFP  % current
        meanRT(i, j) = geomean(RT_history{i, j});
        ciRT(i, j, :) = bootci(1000, @geomean, RT_history{i, j});
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
    'nextplot', 'add', 'xlim', [250 1750], 'xtick', [500:500:2000], 'ylim', [250 380], 'ytick', [200:50:500])

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


RTMixed.SequentialRTmean = meanRT;
RTMixed.SequentialRTci = ciRT;

ha8=axes('unit', 'centimeters', 'position', [16.5 13.5 4 4],...
    'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 20])

for i = 1:length(bMixedFPs)
    text(0, i, [sprintf('%2.0d) ', i) bMixedFPs(i).SessionName], 'fontsize', 6)
    
end

axis off

savename = ['MixedFPs_'  upper(bMixedFPs(1).Metadata.SubjectName) '_GeoResults'];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')

savename = ['RTMixedGeo_' upper(bMixedFPs(1).Metadata.SubjectName)];
save (savename, 'RTMixed')


