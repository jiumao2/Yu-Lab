Subjects = {
    'Steve'          'RTMixedAll_STEVEPreLesion.mat'
    'John'            'RTMixedAll_JOHNPreLesion.mat'
    'Bob'            'RTMixedAll_BOBPreLesion.mat'
    'Tom'           'RTMixedAll_TOMPreLesion.mat'
    'Mark'          'RTMixedAll_MARKPreLesion.mat'
    'Mike'           'RTMixedAll_MIKEPreLesion.mat'
};
Nsubject = size(Subjects, 1);

figure(27); clf(27)
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 10], 'paperpositionmode', 'auto' )

ha1 = axes;  % for performance
set(ha1, 'units', 'centimeters', 'position', [1 1 3.5 2.5], 'xlim', [0.5 3.5], 'ylim', [0 1], 'ytick', [0:0.2:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250])

haFP(1) = axes;  % for press distribution FP0.5
set(haFP(1), 'units', 'centimeters', 'position', [7 1 2 2.5], 'xlim', [0 2.5], 'ylim', [0 0.1], 'ytick', [0:0.05:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
fill([0.5 0.5+0.6 0.5+0.6 0.5], [0 0 0.2 0.2], 'c')
haRT(1) = axes;  % RT for press distribution FP0.5
set(haRT(1), 'units', 'centimeters', 'position', [7 3.5 1.5 0.5], 'xlim', [0 2.5], 'ylim', [0 1+Nsubject], 'ytick', [],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
axis off

haFP(2) = axes;  % for press distribution FP 1
set(haFP(2), 'units', 'centimeters', 'position', [9.5 1 2 2.5], 'xlim', [0 2.5], 'ylim', [0 0.1], 'ytick', [0:0.05:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
fill([1 1+0.6 1+0.6 1], [0 0 0.2 0.2], 'c')
haRT(2) = axes;  % RT for press distribution FP 1
set(haRT(2), 'units', 'centimeters', 'position', [9.5 3.5 1.5 0.5], 'xlim', [0 2.5], 'ylim', [0 1+Nsubject], 'ytick', [],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
axis off

haFP(3) = axes;  % for press distribution FP1.5
set(haFP(3), 'units', 'centimeters', 'position', [12 1 2 2.5], 'xlim', [0 2.5], 'ylim', [0 0.1], 'ytick', [0:0.05:1],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
fill([1.5 1.5+0.6 1.5+0.6 1.5], [0 0 0.2 0.2], 'c')
haRT(3) = axes;  % RT for press distribution FP0.5
set(haRT(3), 'units', 'centimeters', 'position', [12 3.5 1.5 0.5], 'xlim', [0 2.5], 'ylim', [0 1+Nsubject], 'ytick', [],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
axis off


haRTall = axes;  % RT
set(haRTall, 'units', 'centimeters', 'position', [1 5 2.5 2.5], 'xlim', [0 2000], 'ylim', [0 500], 'ytick', [0:100:500],'nextplot', 'add', 'TickLength', [0.01500 0.0250])
xlabel('FP(ms)')
ylabel('RT(ms)')


CorrAll = zeros(3, size(Subjects, 1));  % performance. correct, each row is for one FP
PremAll = zeros(3, size(Subjects, 1));  % performance. premature
LatAll = zeros(3, size(Subjects, 1));  % performance. late
Durs = [0:20:2500]/1000;
PressDens = cell(1, 3);
RTs = cell(1, 3);
FPs = [0.5 1 1.5];

for i = 1:size(Subjects, 1)
    
    fileloc = fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Animals', Subjects{i, 1}, Subjects{i, 2});
    load(fileloc);
    
    for j = 1:length(RTMixed.FPs)
        
        CorrAll(j, i)           = RTMixed.Performance(2, j)/sum(RTMixed.Performance([2:4], j));
        PremAll(j, i)           = RTMixed.Performance(3, j)/sum(RTMixed.Performance([2:4], j));
        LatAll(j, i)            = RTMixed.Performance(4, j)/sum(RTMixed.Performance([2:4], j));
        F = 20/1000*ksdensity(RTMixed.PressDurs{j}, Durs);
        PressDens{j} = [PressDens{j}; F];
        RTij = RTMixed.RT{j};
        RTs{j}(i, :)=[mean(RTij), std(bootstrp(1000, @mean, RTij))];
        
    end;
    
end;

correct_col     =   [0 1 0]*.8;
premature_col   =   [.6 0 0];
late_col        =   [.6 .6 .6];

subcolors = varycolor(size(Subjects, 1));

axes(ha1)
% 0.5 s
hb1=bar(0.75, mean(CorrAll(1, :)));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1, mean(PremAll(1, :)));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25, mean(LatAll(1, :)));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

    
% 1 s
hb1=bar(0.75+1, mean(CorrAll(2, :)));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+1, mean(PremAll(2, :)));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+1, mean(LatAll(2, :)));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);


% 1.5 s
hb1=bar(0.75+2, mean(CorrAll(3, :)));
set(hb1, 'facecolor', correct_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb2=bar(1+2, mean(PremAll(3, :)));
set(hb2, 'facecolor', premature_col, 'edgecolor', 'k', 'barwidth', 0.2);
hb3=bar(1.25+2, mean(LatAll(3, :)));
set(hb3, 'facecolor', late_col, 'edgecolor', 'k', 'barwidth', 0.2);

        

for j = 1:size(CorrAll, 1)
    for i = 1:size(CorrAll, 2)
        plot(j-0.25+0.1*(rand-0.5),  CorrAll(j, i), 'ko', 'markersize', 2, 'markerfacecolor', 'k');
        plot(j+0.1*(rand-0.5),   PremAll(j, i) , 'ko', 'markersize', 2, 'markerfacecolor', 'k');
        plot(j+0.25+0.1*(rand-0.5),   LatAll(j, i) , 'ko', 'markersize', 2, 'markerfacecolor', 'k');
    end;
end;
    
ylabel ('Fraction')
 
allrt = RTs{1}(:, 1);
[~, sortindex]= sort(allrt);
RTmean = [];

%% plot reaction time
for j=1:length(RTs);
    RTs{j}=RTs{j}(sortindex, :);
    RTmean(j) = 1000*mean(RTs{j}(:, 1));
    RTse =1000*std(RTs{j}(:, 1))/sqrt(Nsubject);
    axes(haRTall)
    plot(FPs(j)*1000, RTmean(j), 'marker', 'o', 'markersize', 5, 'color', 'k')
    line([FPs(j)*1000 FPs(j)*1000], [-RTse RTse]+RTmean(j), 'color', 'k', 'linewidth', 1)
end;

plot(FPs*1000, RTmean, 'color', 'k')
set(haRTall, 'ylim', [250 350], 'ytick', [250 :50:350], 'xtick', [500:500:1500])

% plot press duration distribution

for j =1:length(haFP)
    meanDens = mean(PressDens{j}, 1);
    seDens = std(PressDens{j}, 0, 1)/sqrt(Nsubject);
    
    axes(haFP(j))
    
    hp = shadedplot(Durs, meanDens-seDens, meanDens+seDens, [0.7 0.7 0.7]);
    hold on
    hp2= plot(Durs, meanDens, 'color', 'k', 'linewidth', 1)
       
    for i = 1:size(Subjects, 1)
        yrand = i;
%         axes(haRT(j))
        
        RTijmean = RTs{j}(i, 1)+FPs(j);
        RTijse = RTs{j}(i, 2);
%         line([RTijmean-RTijse RTijmean+RTijse], [yrand yrand], 'color', 'k')
%         plot(RTijmean, yrand, 'o','markersize', 2, 'color', 'k')
%         
    end;
end;



savefolder = 'C:\Users\jiani\OneDrive\Work\Behavior\Figures';
savename = fullfile(savefolder, 'MixedFPs_Characterizations');

print (gcf,'-dpng', [savename])
saveas(gcf, savename, 'epsc')