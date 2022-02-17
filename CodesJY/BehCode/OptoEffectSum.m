function OptoEffectSum(bM1Opto, figname, note, stimprofile)

% find short and long FPs
xnum=unique(bM1Opto(1).FPs);
r=histc(bM1Opto(1).FPs, xnum);
ind_SL = find(r>20);
FPsl = sort(xnum(ind_SL));

if nargin<4
    stimprofile = [];
if nargin<3
    note = [];
    if nargin<2
        figname =[];
    end;
end;
end;

name = upper(bM1Opto(1).Metadata.Metadata.SubjectName);

stimcolor =  [0 170 255]/255;

% PR Press duration

PR_Nostim_Short     =       [];
PR_Stim_Short         =       [];
PR_Nostim_Long      =       [];
PR_Stim_Long          =       [];

for i =1:length(bM1Opto)
    
    indbeg = find(bM1Opto(i).FPs==FPsl(1), 1, 'first'); 
    
    IndShortNoStim = find(bM1Opto(i).FPs>=indbeg & bM1Opto(i).FPs==FPsl(1) & bM1Opto(i).Stim==0);
    IndShortStim = find(bM1Opto(i).FPs>=indbeg & bM1Opto(i).FPs==FPsl(1) & bM1Opto(i).Stim==1);
    IndLongNoStim = find(bM1Opto(i).FPs>=indbeg & bM1Opto(i).FPs==FPsl(2) & bM1Opto(i).Stim==0);
    IndLongStim = find(bM1Opto(i).FPs>=indbeg & bM1Opto(i).FPs==FPsl(2) & bM1Opto(i).Stim==1);
    
    PR_Nostim_Short         = [PR_Nostim_Short bM1Opto(i).ReleaseTime(IndShortNoStim)-bM1Opto(i).PressTime(IndShortNoStim)];
    PR_Stim_Short             = [PR_Stim_Short bM1Opto(i).ReleaseTime(IndShortStim)-bM1Opto(i).PressTime(IndShortStim)];
    PR_Nostim_Long          = [PR_Nostim_Long bM1Opto(i).ReleaseTime(IndLongNoStim)-bM1Opto(i).PressTime(IndLongNoStim)];
    PR_Stim_Long              = [PR_Stim_Long bM1Opto(i).ReleaseTime(IndLongStim)-bM1Opto(i).PressTime(IndLongStim)];
end;

PR_Nostim_Short       =         1000*PR_Nostim_Short;
PR_Stim_Short           =         1000*PR_Stim_Short;
PR_Nostim_Long        =         1000*PR_Nostim_Long;
PR_Stim_Long            =         1000*PR_Stim_Long;

RTall_Nostim_Short = 1000*cell2mat(arrayfun(@(x)x.RT_Short_Nostim, bM1Opto, 'Uniformoutput', false));
RTall_Nostim_Short = RTall_Nostim_Short(RTall_Nostim_Short>100);
RTall_Nostim_Short_se = prctile(bootstrp(2000, @geomean, RTall_Nostim_Short), [2.5 97.5]);


RTall_Nostim_Short = 1000*cell2mat(arrayfun(@(x)x.RT_Short_Nostim, bM1Opto, 'Uniformoutput', false));
RTall_Nostim_Short = RTall_Nostim_Short(RTall_Nostim_Short>100);
RTall_Nostim_Short_se = prctile(bootstrp(2000, @geomean, RTall_Nostim_Short), [2.5 97.5]);


RTall_Stim_Short = 1000*cell2mat(arrayfun(@(x)x.RT_Short_Stim, bM1Opto, 'Uniformoutput', false));
RTall_Stim_Short = RTall_Stim_Short(RTall_Stim_Short>100);
RTall_Stim_Short_se = prctile(bootstrp(2000, @geomean, RTall_Stim_Short), [2.5 97.5]);


RTall_Nostim_Long = 1000*cell2mat(arrayfun(@(x)x.RT_Long_Nostim, bM1Opto, 'Uniformoutput', false));
RTall_Nostim_Long = RTall_Nostim_Long(RTall_Nostim_Long>100);
RTall_Nostim_Long_se = prctile(bootstrp(2000, @geomean, RTall_Nostim_Long), [2.5 97.5]);


RTall_Stim_Long = 1000*cell2mat(arrayfun(@(x)x.RT_Long_Stim, bM1Opto, 'Uniformoutput', false));
RTall_Stim_Long = RTall_Stim_Long(RTall_Stim_Long>100);
RTall_Stim_Long_se = prctile(bootstrp(2000, @geomean, RTall_Stim_Long), [2.5 97.5]);


RTdata_all = [{RTall_Nostim_Short} {RTall_Stim_Short} {RTall_Nostim_Long} {RTall_Stim_Long}];
catIdx_RT_all = [ones(1, length(RTall_Nostim_Short)) 2*ones(1, length(RTall_Stim_Short))  3*ones(1, length(RTall_Nostim_Long))  4*ones(1, length(RTall_Stim_Long)) ];

markers ={'.', '.', '.', '.'};
markercolors = [
    0 0 0
    stimcolor
    0 0 0
    stimcolor];
    

figure(27); clf(27)
set(gcf, 'unit', 'centimeters', 'position',[2 2 25 16], 'paperpositionmode', 'auto' )


ha1= axes('unit', 'centimeters', 'position', [1.5 2 6 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 600],'ytick', [0:200:1000], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [1:5], 'xticklabel', {'Short', 'Short', 'Long', 'Long'}, 'xlim', [0 5])

title(name)
hp3 = plotSpread(RTdata_all, 'CategoryIdx',catIdx_RT_all,...
    'categoryMarkers',markers,'categoryColors',markercolors, 'spreadWidth', 0.5)

plot(1, geomean(RTall_Nostim_Short), 'ro', 'linewidth', 1)
line([1 1], [RTall_Nostim_Short_se], 'linewidth', 2, 'color', 'r')


plot(2, geomean(RTall_Stim_Short), 'ro',  'linewidth', 1)
line([2 2],RTall_Stim_Short_se , 'linewidth', 2, 'color', 'r')

line([1 2], [geomean(RTall_Nostim_Short) geomean(RTall_Stim_Short)], 'color', 'k', 'linestyle','--')

sprintf('RT short FP is %2.2f (nostim) vs %2.2f (stim)', geomean(RTall_Nostim_Short), geomean(RTall_Stim_Short))

plot(3, geomean(RTall_Nostim_Long), 'ro',  'linewidth', 1)
line([3 3],RTall_Nostim_Long_se, 'linewidth', 2, 'color', 'r')

plot(4, geomean(RTall_Stim_Long), 'ro',  'linewidth', 1)
line([4 4], RTall_Stim_Long_se, 'linewidth', 2, 'color', 'r')
line([3 4], [geomean(RTall_Nostim_Long) geomean(RTall_Stim_Long)], 'color', 'k', 'linestyle','--')

ylabel('Reaction time (ms)')

sprintf('RT long FP is %2.2f (nostim) vs %2.2f (stim)', geomean(RTall_Nostim_Long), geomean(RTall_Stim_Long))


[p, h]=ranksum(RTall_Nostim_Short, RTall_Stim_Short);
text(1, 50, sprintf('p=%2.5f', p))

[p, h]=ranksum(RTall_Nostim_Long, RTall_Stim_Long);
text(3, 50, sprintf('p=%2.5f', p))

% PR_Nostim_Short       =         1000*PR_Nostim_Short;
% PR_Stim_Short           =         1000*PR_Stim_Short;
% PR_Nostim_Long        =         1000*PR_Nostim_Long;
% PR_Stim_Long            =         1000*PR_Stim_Long;

PRdata_all = [{PR_Nostim_Short} {PR_Stim_Short} {PR_Nostim_Long} {PR_Stim_Long}];
catIdx_PR_all = [ones(1, length(PR_Nostim_Short)) 2*ones(1, length(PR_Stim_Short))  3*ones(1, length(PR_Nostim_Long))  4*ones(1, length(PR_Stim_Long)) ];


%% plot RT distribution
% RTdata_all = [{RTall_Nostim_Short} {RTall_Stim_Short} {RTall_Nostim_Long} {RTall_Stim_Long}];
% catIdx_RT_all = [ones(1, length(RTall_Nostim_Short)) 2*ones(1, length(RTall_Stim_Short))  3*ones(1, length(RTall_Nostim_Long))  4*ones(1, length(RTall_Stim_Long)) ];

bins = [0:50:600];
RTbincenters = mean(bins(1:end-1), bins(2:end));

P_RT_Short_Nostim = histcounts(RTall_Nostim_Short, bins)/length(RTall_Nostim_Short);
P_RT_Short_Stim = histcounts(RTall_Stim_Short, bins)/length(RTall_Stim_Short);

P_RT_Long_Nostim = histcounts(RTall_Nostim_Long, bins)/length(RTall_Nostim_Long);
P_RT_Long_Stim = histcounts(RTall_Stim_Long, bins)/length(RTall_Stim_Long);

ha2a= axes('unit', 'centimeters', 'position', [9 2 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 600],'ytick', [0:200:600], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [0:0.1:0.5], 'xlim', [0 0.5]);

plotshaded([0 1], [FPsl(1) FPsl(1); FPsl(1)+600 FPsl(1)+600], [200 186 200]/255);

plot(P_RT_Short_Nostim, RTbincenters, 'k', 'linewidth', 1)
plot(P_RT_Short_Stim, RTbincenters,'color', stimcolor,'linewidth', 1.5)

xlabel('Probability')
ylabel('Reaction time (ms)')

ha2b= axes('unit', 'centimeters', 'position', [12 2 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 600],'ytick', [0:200:600],'yticklabel', [],  'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [0:0.1:0.5], 'xlim', [0 0.5]);



plotshaded([0 1], [1500 1500; 1500+600 1500+600], [200 186 200]/255);

plot(P_RT_Long_Nostim, RTbincenters, 'k', 'linewidth', 1)
plot(P_RT_Long_Stim, RTbincenters, 'color', stimcolor,'linewidth', 1.5)
 
%% Press duration related
ha2= axes('unit', 'centimeters', 'position', [1.5 6.5 6 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 3000],'ytick', [0:500:3000], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [1:5], 'xticklabel', {'Short ', 'Short ', 'Long ', 'Long '}, 'xlim', [0 5]);
title(name)

if ~isempty(stimprofile)
    plotshaded([.5 2.5], [stimprofile(1) stimprofile(1); stimprofile(1)+stimprofile(2) stimprofile(1)+stimprofile(2)],[204 204 255]/255);
    plotshaded(2+[.5 2.5], [stimprofile(1) stimprofile(1); stimprofile(1)+stimprofile(2) stimprofile(1)+stimprofile(2)],[204 204 255]/255);
end;

plotshaded([.5 2.5], [FPsl(1) FPsl(1); FPsl(1)+600 FPsl(1)+600], [200 186 200]/255);
plotshaded([2.5 4.5], [FPsl(2) FPsl(2) ; FPsl(2)+600 FPsl(2)+600], [200 186 200]/255);

hp4 = plotSpread(PRdata_all, 'CategoryIdx',catIdx_PR_all,...
    'categoryMarkers',markers,'categoryColors',markercolors, 'spreadWidth', 0.5);

ylabel('Press duration (ms)')


%% plot distribution
bins = [0:50:3000];
PRbincenters = mean(bins(1:end-1), bins(2:end));

P_PR_Short_Nostim = histcounts(PR_Nostim_Short, bins)/length(PR_Nostim_Short);
P_PR_Short_Stim = histcounts(PR_Stim_Short, bins)/length(PR_Stim_Short);

P_PR_Long_Nostim = histcounts(PR_Nostim_Long, bins)/length(PR_Nostim_Long);
P_PR_Long_Stim = histcounts(PR_Stim_Long, bins)/length(PR_Stim_Long);

ha2a= axes('unit', 'centimeters', 'position', [9 6.5 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 3000],'ytick', [0:500:3000], 'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [0:0.1:0.5], 'xlim', [0 0.5]);

if ~isempty(stimprofile)
    plotshaded([0 0.5], [stimprofile(1) stimprofile(1); stimprofile(1)+stimprofile(2) stimprofile(1)+stimprofile(2)],[204 204 255]/255);
end;

plotshaded([0 1], [FPsl(1)  FPsl(1) ; FPsl(1)+600 FPsl(1)+600], [200 186 200]/255);

plot(P_PR_Short_Nostim, PRbincenters, 'k', 'linewidth', 1)
plot(P_PR_Short_Stim, PRbincenters, 'color', stimcolor, 'linewidth', 1.5)

xlabel('Probability')
ylabel('Press duration')

ha2b= axes('unit', 'centimeters', 'position', [12 6.5 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 3000],'ytick', [0:500:3000],'yticklabel', [],  'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [0:0.1:0.5], 'xlim', [0 0.5]);

if ~isempty(stimprofile)
    plotshaded([0 0.5], [stimprofile(1) stimprofile(1); stimprofile(1)+stimprofile(2) stimprofile(1)+stimprofile(2)],[204 204 255]/255);
end;

plotshaded([0 1], [FPsl(2)  FPsl(2) ; FPsl(2)+600 FPsl(2)+600], [200 186 200]/255);

plot(P_PR_Long_Nostim, PRbincenters, 'k', 'linewidth', 1)
plot(P_PR_Long_Stim, PRbincenters, 'color', stimcolor, 'linewidth', 1.5)
 

%% test statistics
% short
n1 = length(find(PR_Nostim_Short>FPsl(1) & PR_Nostim_Short<=FPsl(1)+600));
N1 = length(PR_Nostim_Short);
n2 = length(find(PR_Stim_Short>FPsl(1) & PR_Stim_Short<=FPsl(1)+600));
N2 = length(PR_Stim_Short);
[tbl_short_correct,chi2stat_short_correct,pval_short_correct]=chi2test_twogroups(n1, N1, n2, N2)

n1 = length(find(PR_Nostim_Short<=FPsl(1)));
N1 = length(PR_Nostim_Short);
n2 = length(find(PR_Stim_Short<FPsl(1)));
N2 = length(PR_Stim_Short);
[tbl_short_premature,chi2stat_short_premature,pval_short_premature]=chi2test_twogroups(n1, N1, n2, N2)

n1 = length(find(PR_Nostim_Short>FPsl(1)+600));
N1 = length(PR_Nostim_Short);
n2 = length(find(PR_Stim_Short>FPsl(1)+600));
N2 = length(PR_Stim_Short);
[tbl_short_late,chi2stat_short_late,pval_short_late]=chi2test_twogroups(n1, N1, n2, N2)

% long
n1 = length(find(PR_Nostim_Long>FPsl(2) & PR_Nostim_Long<=FPsl(2)+600));
N1 = length(PR_Nostim_Long);
n2 = length(find(PR_Stim_Long>FPsl(2) & PR_Stim_Long<=FPsl(2)+600));
N2 = length(PR_Stim_Long);
[tbl_long_correct,chi2stat_long_correct,pval_long_correct]=chi2test_twogroups(n1, N1, n2, N2)


n1 = length(find(PR_Nostim_Long<FPsl(2)));
N1 = length(PR_Nostim_Long);
n2 = length(find(PR_Stim_Long<FPsl(2)));
N2 = length(PR_Stim_Long);
[tbl_long_premature,chi2stat_long_premature,pval_long_premature]=chi2test_twogroups(n1, N1, n2, N2)

n1 = length(find(PR_Nostim_Long>FPsl(2)+600));
N1 = length(PR_Nostim_Long);
n2 = length(find(PR_Stim_Long>FPsl(2)+600));
N2 = length(PR_Stim_Long);
[tbl_long_late,chi2stat_long_late,pval_long_late]=chi2test_twogroups(n1, N1, n2, N2)

hastat= axes('unit', 'centimeters', 'position', [15 11 3 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [5 15],'ytick', [0:.2:1],'yticklabel', [],  'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [], 'xlim', [0 19]);

text(1, 14, 'Short')
text(1, 12, sprintf('pval correct: %2.5g', pval_short_correct))
text(1, 10, sprintf('pval premature: %2.5g', pval_short_premature))
text(1, 8, sprintf('pval late: %2.5g', pval_short_late))

axis off

hastat= axes('unit', 'centimeters', 'position', [20 11 3 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [5 15],'ytick', [0:.2:1],'yticklabel', [],  'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [1:18], 'xlim', [0 20]);
text(1, 14, 'Long')
text(1, 12, sprintf('pval correct: %2.5g', pval_long_correct))
text(1, 10, sprintf('pval premature: %2.5g', pval_long_premature))
text(1, 8, sprintf('pval late: %2.5g', pval_long_late))

axis off

% calculate success rate
hapremature= axes('unit', 'centimeters', 'position', [16 6.5 7 3], 'fontsize', 8, 'nextplot', 'add', ...
    'ylim', [0 1],'ytick', [0:.2:1],  'tickdir', 'out', 'ticklength', [0.015 0.1],...
    'xtick', [1 2 3 6 7 8 12 13 14 16 17 18], 'xticklabel', [], 'xlim', [0 20.5]);

Premature_Nostim_short = length(find(PR_Nostim_Short<FPsl(1)))/length(PR_Nostim_Short);
Late_Nostim_short = length(find(PR_Nostim_Short>FPsl(1)+600))/length(PR_Nostim_Short);
Correct_Nostim_short = 1-Premature_Nostim_short-Late_Nostim_short;

plotshaded([5 9], [0 0; 1 1], [0 170 255]/255)

hbar1 = bar([1], [Correct_Nostim_short],'FaceColor', [55 255 0]/255);
hbar2 = bar([2], [Premature_Nostim_short], 'FaceColor',  [153 51 0]/255);
hbar3 = bar([3], [Late_Nostim_short], 'FaceColor', 'r');

Premature_Stim_short = length(find(PR_Stim_Short<FPsl(1)))/length(PR_Stim_Short);
Late_Stim_short = length(find(PR_Stim_Short>FPsl(1)+600))/length(PR_Stim_Short);
Correct_Stim_short = 1-Premature_Stim_short-Late_Stim_short;

hbar1 = bar([6], [Correct_Stim_short],'FaceColor', [55 255 0]/255);
hbar2 = bar([7], [Premature_Stim_short], 'FaceColor',  [153 51 0]/255);
hbar3 = bar([8], [Late_Stim_short], 'FaceColor', 'r');

line([10.5 10.5], [0 1], 'color', 'k', 'linewidth', 2, 'linestyle', '--')
text(2.5, 1.1, 'Short FP','fontsize', 9)
text(13, 1.1, 'Long FP', 'fontsize', 9)


%%
Premature_Nostim_long = length(find(PR_Nostim_Long<FPsl(2)))/length(PR_Nostim_Long);
Late_Nostim_long = length(find(PR_Nostim_Long>FPsl(2)+600))/length(PR_Nostim_Long);
Correct_Nostim_long = 1-Premature_Nostim_long-Late_Nostim_long;

plotshaded([16 20], [0 0; 1 1], [0 170 255]/255)

hbar1 = bar([12], [Correct_Nostim_long],'FaceColor', [55 255 0]/255);
hbar2 = bar([13], [Premature_Nostim_long], 'FaceColor',  [153 51 0]/255);
hbar3 = bar([14], [Late_Nostim_long], 'FaceColor', 'r');

Premature_Stim_long = length(find(PR_Stim_Long<FPsl(2)))/length(PR_Stim_Long);
Late_Stim_long = length(find(PR_Stim_Long>FPsl(2)+600))/length(PR_Stim_Long);
Correct_Stim_long = 1-Premature_Stim_long-Late_Stim_long;

hbar1 = bar([17], [Correct_Stim_long],'FaceColor', [55 255 0]/255);
hbar2 = bar([18], [Premature_Stim_long], 'FaceColor',  [153 51 0]/255);
hbar3 = bar([19], [Late_Stim_long], 'FaceColor', 'r');

ylabel('Proportion')

%% plot culmulative probability, reaction time
ha5= axes('unit', 'centimeters', 'position', [1.5 11 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 1], 'ytick', [0:.2:1],  'tickdir', 'out', 'ticklength', [0.015 0.1]);

% P_RT_Short_Nostim = histcounts(RTall_Nostim_Short, bins)/length(RTall_Nostim_Short);
% P_RT_Short_Stim = histcounts(RTall_Stim_Short, bins)/length(RTall_Stim_Short);
% 
% P_RT_Long_Nostim = histcounts(RTall_Nostim_Long, bins)/length(RTall_Nostim_Long);
% P_RT_Long_Stim = histcounts(RTall_Stim_Long, bins)/length(RTall_Stim_Long);


xlabel('Reaction time (ms)');
ylabel('Culmulative release probability') 

[frt_Nostim_Short, xrt_Nostim_Short] = ecdf(RTall_Nostim_Short);
[frt_Stim_Short, xrt_Stim_Short] = ecdf(RTall_Stim_Short);

plot(xrt_Nostim_Short, frt_Nostim_Short, 'k', 'linewidth', 1)
plot(xrt_Stim_Short, frt_Stim_Short, 'color', stimcolor, 'linewidth', 1.5)

title('Short')

ha6= axes('unit', 'centimeters', 'position', [4.5 11 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 1], 'ytick', [0:.2:1],  'tickdir', 'out', 'ticklength', [0.015 0.1]);

[frt_Nostim_Long, xrt_Nostim_Long] = ecdf(RTall_Nostim_Long);
[frt_Stim_Long, xrt_Stim_Long] = ecdf(RTall_Stim_Long);

plot(xrt_Nostim_Long, frt_Nostim_Long, 'k', 'linewidth', 1)
plot(xrt_Stim_Long, frt_Stim_Long, 'color', stimcolor,'linewidth', 1.5)

title('Long')

%% plot culmulative probability, Press duration
ha3= axes('unit', 'centimeters', 'position', [9 11 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'xlim', [0 3000],'xtick', [0:1000:3000], 'ylim', [0 1], 'ytick', [0:.2:1],  'tickdir', 'out', 'ticklength', [0.015 0.1]);

xlabel('Press duration (ms)');
ylabel('Culmulative release probability')
if ~isempty(stimprofile)
    plotshaded([stimprofile(1) stimprofile(1)+stimprofile(2)], [0 0; 1 1], [204 204 255]/255);
end;

plotshaded([FPsl(1) FPsl(1)+600], [0 0; 1 1], [200 186 200]/255);

[f_Nostim_Short, x_Nostim_Short] = ecdf(PR_Nostim_Short);
[f_Stim_Short, x_Stim_Short] = ecdf(PR_Stim_Short);
plot(x_Nostim_Short, f_Nostim_Short, 'k', 'linewidth', 1)
plot(x_Stim_Short, f_Stim_Short, 'color', stimcolor, 'linewidth', 1.5)
title('Short')

ha3= axes('unit', 'centimeters', 'position', [12 11 2.5 3], 'fontsize', 8, 'nextplot', 'add', ...
    'xlim', [0 3000],'xtick', [0:1000:3000], 'ylim', [0 1], 'ytick', [0:.2:1],  'tickdir', 'out', 'ticklength', [0.015 0.1]);

if ~isempty(stimprofile)
    plotshaded([stimprofile(1) stimprofile(1)+stimprofile(2)], [0 0; 1 1], [204 204 255]/255);
end;
plotshaded([FPsl(2) FPsl(2)+600], [0 0; 1 1], [200 186 200]/255);

[f_Nostim_Long, x_Nostim_Long] = ecdf(PR_Nostim_Long);
[f_Stim_Long, x_Stim_Long] = ecdf(PR_Stim_Long);
plot(x_Nostim_Long, f_Nostim_Long, 'k', 'linewidth', 1)
plot(x_Stim_Long, f_Stim_Long,'color', stimcolor, 'linewidth', 1.5)

title('Long')

if ~isempty(note)
       uicontrol('Parent', gcf, 'Style', 'text','String', note, 'unit', 'centimeters', 'position', [1 14.5 7 1], 'fontsize', 8);
end;


savename = ['OptoEffectSum_'  name figname]; 

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])



function [tbl,chi2stat,pval]=chi2test_twogroups(n1, N1, n2, N2)

x1 = [repmat('a',N1,1); repmat('b',N2,1)];
x2 = [repmat(1,n1,1); repmat(2,N1-n1,1); repmat(1,n2,1); repmat(2,N2-n2,1)];

[tbl,chi2stat,pval] = crosstab(x1,x2)