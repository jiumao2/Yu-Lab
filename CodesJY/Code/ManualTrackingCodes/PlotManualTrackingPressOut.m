function PlotManualTrackingPressOut(PressOut, PrefPaw, IndPost, IndPreLesion, IndPostLesion)
Paw = [];
switch PrefPaw
    case 1
        Paw = 'Left';
    case 2
         Paw = 'Right';
    case 3
         Paw = 'Both';
end;
%% Plot sessions
hf = figure(26); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 14 18], 'paperpositionmode', 'auto','renderer','Painters' )

%% Flex onset
ha1 =  axes('unit', 'centimeters', 'position', [1.5 2 6 2.5], 'nextplot', 'add', 'xlim', [0 length(PressOut)+1], 'ylim', [0 800],...
    'ytick', [-2000:200:800], 'xtick', [1:length(PressOut)]);
tFlexAll = zeros(1, length(PressOut));
for i = 1:length(PressOut)
    
    tFlex = -PressOut(i).FlexOnset(~isnan(PressOut(i).FlexOnset) & PressOut(i).PressPaw==PrefPaw);
    plot(i+0.25*(rand(1, length(tFlex))-0.5), tFlex, 'k.', 'markersize', 6, 'markerfacecolor',[0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8])
    plot(i, median(tFlex), 'color', 'b', 'linewidth', 1,  'marker', 'o','markerfacecolor', 'w', 'markeredgecolor', 'b')
    
    tFlexAll(i) = median(tFlex);
end;

plot([1:length(PressOut)], tFlexAll, '-', 'color', 'k', 'linewidth', 1)

xlabel('Sessions')
ylabel('Flex onset (ms)')

line([IndPost-0.5 IndPost-0.5], [-800 800], 'color', 'm')

% compare 3 sessions pre vs post lesions
ha1b =  axes('unit', 'centimeters', 'position', [9 2 3 2.5], 'nextplot', 'add', 'xlim', [0 3], 'ylim', [0 800],...
    'ytick', [-2000:200:800], 'xtick', [1 2], 'xticklabel', {'Pre', 'Post'});
 ylabel('Flex onset (ms)')
 

tFlexPre = [];
for i =1:length(IndPreLesion)
        tFlex = -PressOut(IndPreLesion(i)).FlexOnset(~isnan(PressOut(IndPreLesion(i)).FlexOnset) & PressOut(IndPreLesion(i)).PressPaw==PrefPaw);
        tFlexPre = [tFlexPre tFlex];
end;

tFlexPost = [];
for i =1:length(IndPostLesion)
    tFlex = -PressOut(IndPostLesion(i)).FlexOnset(~isnan(PressOut(IndPostLesion(i)).FlexOnset) & PressOut(IndPostLesion(i)).PressPaw==PrefPaw);
    tFlexPost = [tFlexPost tFlex];
end;

data2plot = {tFlexPre, tFlexPost};
catIdx = [zeros(length(tFlexPre), 1);  ones(length(tFlexPost), 1)];
plotSpread(data2plot,'categoryIdx',catIdx,...
    'categoryMarkers',{'.','.'},'categoryColors',{[0.8 0.8 0.8],[0.8 0.8 0.8]}, 'spreadWidth', 0.75)

tFlexPre_mean = median(tFlexPre);
tFlexPost_mean = median(tFlexPost);

tFlexPre_ci = bootci(2000, {@median, tFlexPre}, 'type', 'cper');
tFlexPost_ci = bootci(2000, {@median, tFlexPost}, 'type', 'cper');

line([1 1], tFlexPre_ci, 'linewidth', 2, 'color', 'k')
plot(1, tFlexPre_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')

line([2 2], tFlexPost_ci, 'linewidth', 2, 'color', 'k')
plot(2, tFlexPost_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')

line([1.1 1.9], [tFlexPre_mean tFlexPost_mean], 'color', 'k', 'linewidth', 1)


[P_Flex] = ranksum(tFlexPre, tFlexPost) ;

ha1c =  axes('unit', 'centimeters', 'position', [12 2 1 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);
axis off

 text(1, 8, sprintf('p=%2.5g', P_Flex), 'fontsize', 8)
 text(1, 5, sprintf('Pre: %2.0f ms', tFlexPre_mean), 'fontsize', 8)
 text(1, 2, sprintf('Post: %2.0f ms', tFlexPost_mean), 'fontsize', 8)
 
%% Touch to press
ha2 =  axes('unit', 'centimeters', 'position', [1.5 5.5 6 2.5], 'nextplot', 'add', 'xlim', [0 length(PressOut)+1], 'ylim', [0 400],...
    'ytick', [-2000:200:800], 'xtick', [1:length(PressOut)]);
tTouchAll = zeros(1, length(PressOut));
for i = 1:length(PressOut)
    tTouch= -PressOut(i).TouchOnset(~isnan(PressOut(i).TouchOnset) & PressOut(i).PressPaw==PrefPaw);
    plot(i+0.25*(rand(1, length(tTouch))-0.5), tTouch, '.', 'markersize', 6, 'markerfacecolor',[0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8])
    plot(i, median(tTouch), 'color', 'b', 'linewidth', 1, 'marker', 'o','markerfacecolor', 'w', 'markeredgecolor', 'b')
    tTouchAll(i) = median(tTouch);
end;

plot([1:length(PressOut)], tTouchAll, '-', 'color', 'k', 'linewidth', 1)

xlabel('Sessions')
ylabel('Touch onset (ms)')
 
line([IndPost-0.5 IndPost-0.5], [-800 800], 'color', 'm')


% compare 3 sessions pre vs post lesions
ha2b =  axes('unit', 'centimeters', 'position', [9 5.5 3 2.5], 'nextplot', 'add', 'xlim', [0 3], 'ylim', [0 400],...
    'ytick', [-2000:200:800], 'xtick', [1 2], 'xticklabel', {'Pre', 'Post'});
 ylabel('Touch onset (ms)')
 
tTouchPre = [];
for i =1:length(IndPreLesion)
        tTouch = -PressOut(IndPreLesion(i)).TouchOnset(~isnan(PressOut(IndPreLesion(i)).TouchOnset) & PressOut(IndPreLesion(i)).PressPaw==PrefPaw);
        tTouchPre = [tTouchPre tTouch];
end;

tTouchPost= [];
for i =1:length(IndPostLesion)
        tTouch = -PressOut(IndPostLesion(i)).TouchOnset(~isnan(PressOut(IndPostLesion(i)).TouchOnset) & PressOut(IndPostLesion(i)).PressPaw==PrefPaw);
        tTouchPost = [tTouchPost tTouch];
end;
 

data2plot = {tTouchPre, tTouchPost};
catIdx = [zeros(length(tTouchPre), 1);  ones(length(tTouchPost), 1)];
plotSpread(data2plot,'categoryIdx',catIdx,...
    'categoryMarkers',{'.','.'},'categoryColors',{[0.8 0.8 0.8],[0.8 0.8 0.8]}, 'spreadWidth', 0.75)

tTouchPre_mean = median(tTouchPre);
tTouchPost_mean = median(tTouchPost);

 tTouchPre_ci = bootci(2000, {@median, tTouchPre}, 'type', 'cper');
 tTouchPost_ci = bootci(2000, {@median, tTouchPost}, 'type', 'cper');
 
 line([1 1], tTouchPre_ci, 'linewidth', 2, 'color', 'k')
 plot(1, tTouchPre_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')
 
  line([2 2], tTouchPost_ci, 'linewidth', 2, 'color', 'k')
 plot(2, tTouchPost_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')
 
 line([1.1 1.9], [tTouchPre_mean tTouchPost_mean], 'color', 'k', 'linewidth', 1)

 
[P_Touch] = ranksum(tTouchPre, tTouchPost) ;
 
 sprintf('Touch to press time %2.2f ms and %2.2f ms, p =%2.5f', tTouchPre_mean, tTouchPost_mean, P_Touch)
 
 ha1c =  axes('unit', 'centimeters', 'position', [12 5.5 1 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);
axis off

text(1, 8, sprintf('p=%2.5g', P_Touch), 'fontsize', 8)
text(1, 5, sprintf('Pre: %2.0f ms', tTouchPre_mean), 'fontsize', 8)
text(1, 2, sprintf('Post: %2.0f ms', tTouchPost_mean), 'fontsize', 8)


%% Release time
ha3 =  axes('unit', 'centimeters', 'position', [1.5 9 6 2.5], 'nextplot', 'add', 'xlim', [0 length(PressOut)+1], 'ylim', [0 600],...
    'ytick', [-2000:200:800], 'xtick', [1:length(PressOut)]);
tReleaseAll = zeros(1, length(PressOut));
for i = 1:length(PressOut)
    tRelease= PressOut(i).ReleaseOnset(~isnan(PressOut(i).ReleaseOnset) & PressOut(i).PressPaw==PrefPaw & PressOut(i).Outcome>=0);
    plot(i+0.25*(rand(1, length(tRelease))-0.5), tRelease, '.', 'markersize', 6, 'markerfacecolor',[0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8])
    plot(i, median(tRelease), 'color', 'b', 'linewidth', 1, 'marker', 'o','markerfacecolor', 'w', 'markeredgecolor', 'b')
    tReleaseAll(i) = median(tRelease);
end;

plot([1:length(PressOut)], tReleaseAll, '-', 'color', 'k', 'linewidth', 1)

% plot reaction time
tRTAll = zeros(1, length(PressOut));
for i = 1:length(PressOut)
    tRT= PressOut(i).RTs(~isnan(PressOut(i).RTs) & PressOut(i).PressPaw==PrefPaw & PressOut(i).Outcome==1);
    plot(i+0.25*(rand(1, length(tRT))-0.5), tRT, '.', 'markersize', 6, 'markerfacecolor',[0 1 0], 'markeredgecolor', [0 0.8 0])
    plot(i, median(tRT), 'color', [0 0.5 0], 'linewidth', 1, 'marker', 'o','markerfacecolor', 'w', 'markeredgecolor', [0 0.5 0])
    tRTAll(i) = median(tRT);
end;

plot([1:length(PressOut)], tRTAll, '-', 'color', 'k', 'linewidth', 1)


xlabel('Sessions')
ylabel('Release onset & RT (ms)')
 
line([IndPost-0.5 IndPost-0.5], [-800 800], 'color', 'm')

% compare 3 sessions pre vs post lesions
ha3b =  axes('unit', 'centimeters', 'position', [9 9 3 2.5], 'nextplot', 'add', 'xlim', [0 3], 'ylim', [0 600],...
    'ytick', [-2000:200:800], 'xtick', [1 2], 'xticklabel', {'Pre', 'Post'});
ylabel('Release time (ms)')
tReleasePre = [];
for i =1:length(IndPreLesion)
        tReleasePre = [tReleasePre PressOut(IndPreLesion(i)).ReleaseOnset(~isnan(PressOut(IndPreLesion(i)).ReleaseOnset) & PressOut(IndPreLesion(i)).PressPaw==PrefPaw & PressOut(IndPreLesion(i)).Outcome>=0)];
end;

tReleasePost = [];
for i =1:length(IndPostLesion)
        tReleasePost = [tReleasePost PressOut(IndPostLesion(i)).ReleaseOnset(~isnan(PressOut(IndPostLesion(i)).ReleaseOnset) & PressOut(IndPostLesion(i)).PressPaw==PrefPaw & PressOut(IndPostLesion(i)).Outcome>=0)];
end;

data2plot = {tReleasePre, tReleasePost};
catIdx = [zeros(length(tReleasePre), 1);  ones(length(tReleasePost), 1)];
plotSpread(data2plot,'categoryIdx',catIdx,...
    'categoryMarkers',{'.','.'},'categoryColors',{[0.8 0.8 0.8],[0.8 0.8 0.8]}, 'spreadWidth', 0.75)

tReleasePre_mean = median(tReleasePre);
tReleasePost_mean = median(tReleasePost);

tReleasePre_ci = bootci(2000, {@median, tReleasePre}, 'type', 'cper');
tReleasePost_ci = bootci(2000, {@median, tReleasePost}, 'type', 'cper');


[P_Release] = ranksum(tReleasePre, tReleasePost) ;

% cal reation time
tRTPre = [];
for i =1:length(IndPreLesion)
        tRTPre = [tRTPre PressOut(IndPreLesion(i)).RTs(~isnan(PressOut(IndPreLesion(i)).RTs) & PressOut(IndPreLesion(i)).PressPaw==PrefPaw & PressOut(IndPreLesion(i)).Outcome==1)];
end;

tRTPost = [];
for i =1:length(IndPostLesion)
        tRTPost = [tRTPost PressOut(IndPostLesion(i)).RTs(~isnan(PressOut(IndPostLesion(i)).RTs) & PressOut(IndPostLesion(i)).PressPaw==PrefPaw & PressOut(IndPostLesion(i)).Outcome==1)];
end;

data2plot = {tRTPre, tRTPost};
catIdx = [zeros(length(tRTPre), 1);  ones(length(tRTPost), 1)];
plotSpread(data2plot,'categoryIdx',catIdx,...
    'categoryMarkers',{'.','.'},'categoryColors',{'g', 'g'}, 'spreadWidth', 0.75)

tRTPre_mean = median(tRTPre);
tRTPost_mean = median(tRTPost);

tRTPre_ci = bootci(2000, {@median, tRTPre}, 'type', 'cper');
tRTPost_ci = bootci(2000, {@median, tRTPost}, 'type', 'cper');

line([1 1], tReleasePre_ci, 'linewidth', 2, 'color', 'k')
plot(1, tReleasePre_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')

line([2 2], tReleasePost_ci, 'linewidth', 2, 'color', 'k')
plot(2, tReleasePost_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', 'b', 'markeredgecolor', 'w')
 line([1.1 1.9], [tReleasePre_mean tReleasePost_mean], 'color', 'k', 'linewidth', 1)

 
line([1 1], tRTPre_ci, 'linewidth', 2, 'color', 'k')
plot(1, tRTPre_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', [0 0.8 0], 'markeredgecolor', 'w')

line([2 2], tRTPost_ci, 'linewidth', 2, 'color', 'k')
plot(2, tRTPost_mean, 'marker', 'o', 'markersize', 6, 'markerfacecolor', [0 0.8 0], 'markeredgecolor', 'w')
 line([1.1 1.9], [tRTPre_mean tRTPost_mean], 'color', 'k', 'linewidth', 1)

 
ha1c =  axes('unit', 'centimeters', 'position', [12 9 1 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);
axis off

text(1, 9, sprintf('p=%2.5g', P_Release), 'fontsize', 8)
text(1, 7.5, sprintf('Pre: %2.0f ms', tReleasePre_mean), 'fontsize', 8)
text(1, 6, sprintf('Post: %2.0f ms', tReleasePost_mean), 'fontsize', 8)
 
 
[P_RT] = ranksum(tRTPre, tRTPost) ;

text(1, 5-1, sprintf('p=%2.5g', P_RT), 'fontsize', 8)
text(1, 3.5-1, sprintf('Pre: %2.0f ms', tRTPre_mean), 'fontsize', 8)
text(1, 2-1, sprintf('Post: %2.0f ms', tRTPost_mean), 'fontsize', 8)

%% Paw preference
ha4 =  axes('unit', 'centimeters', 'position', [1.5 12.5 6 2], 'nextplot', 'add', 'xlim', [0 length(PressOut)+1], 'ylim', [0 100],...
    'ytick', [0:50:100], 'xtick', [1:length(PressOut)]);

% ha2 =  axes('unit', 'centimeters', 'position', [9.5 2 4 3], 'nextplot', 'add', 'xlim', [0 12], 'ylim', [0 100],...
%     'ytick', [0:50:100], 'xtick', [1 2 3 5 6 7 9 10 11], 'xticklabel', {'L', 'R', 'B'});

% plot press paw

PressPaw_L_All = zeros(1, length(PressOut));
PressPaw_R_All = zeros(1, length(PressOut));
PressPaw_B_All = zeros(1, length(PressOut));

for i = 1:length(PressOut)
    
    PressPaw_L_All(i) = 100*length(find(PressOut(i).PressPaw ==1))/length(PressOut(i).PressPaw);
    PressPaw_R_All(i) = 100*length(find(PressOut(i).PressPaw  ==2))/length(PressOut(i).PressPaw );
    PressPaw_B_All(i) = 100*length(find(PressOut(i).PressPaw  ==3))/length(PressOut(i).PressPaw );
    
end;

plot([1:length(PressOut)], PressPaw_L_All, '-', 'color', 'k', 'linewidth',  1, 'marker', 'o', 'markerfacecolor', 'w', 'markeredgecolor', 'b')
plot([1:length(PressOut)], PressPaw_R_All, '-', 'color', 'k', 'linewidth', 1, 'marker', '^', 'markerfacecolor', 'w', 'markeredgecolor', 'b')
plot([1:length(PressOut)], PressPaw_B_All, '-', 'color', 'k', 'linewidth',  1, 'marker', 's', 'markerfacecolor', 'w', 'markeredgecolor', 'b')

ylabel('Paw preference (press)')
line([IndPost-0.5 IndPost-0.5], [0 800], 'color', 'm')

ha5b =  axes('unit', 'centimeters', 'position', [8 12 2 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);
plot(1, 9,  'marker', 'o', 'markerfacecolor', 'w', 'markeredgecolor', 'b');
text(2, 9, 'Left', 'fontsize', 10)

plot(1, 7,  'marker', '^', 'markerfacecolor', 'w', 'markeredgecolor', 'b');
text(2, 7, 'Right', 'fontsize', 10)

plot(1, 5,  'marker', 's', 'markerfacecolor', 'w', 'markeredgecolor', 'b');
text(2, 5, 'Both', 'fontsize', 10);

axis off

%% plot premature vs late response
ha6 = axes('unit', 'centimeters', 'position', [1.5 15.5 6 2], 'nextplot', 'add', 'xlim', [0 length(PressOut)+1], 'ylim', [0 100],...
    'ytick', [0:50:100], 'xtick', [1:length(PressOut)]);

PrematureAll = zeros(1, length(PressOut));
CorrectAll = zeros(1, length(PressOut));
LateAll = zeros(1, length(PressOut));

for i = 1:length(PressOut)
    CorrectAll(i) = 100*length(find(PressOut(i).Outcome == 1 & PressOut(i).ReleasePaw == PrefPaw))/length(find(PressOut(i).ReleasePaw == PrefPaw));
    PrematureAll(i) = 100*length(find(PressOut(i).Outcome == -1 & PressOut(i).ReleasePaw == PrefPaw))/length(find(PressOut(i).ReleasePaw == PrefPaw));
    LateAll(i) = 100*length(find(PressOut(i).Outcome == 0 & PressOut(i).ReleasePaw == PrefPaw))/length(find(PressOut(i).ReleasePaw == PrefPaw));
end;
col_perf = [85 225 0; 255 0 0; 140 140 140]/255;

plot([1:length(PressOut)], CorrectAll,  '-', 'color', 'k', 'linewidth',  1, 'marker', 'o', 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w')
plot([1:length(PressOut)], PrematureAll,  '-', 'color', 'k', 'linewidth',  1, 'marker', 'o', 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w')
plot([1:length(PressOut)], LateAll,  '-', 'color', 'k', 'linewidth',  1, 'marker', 'o', 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w')

line([IndPost-0.5 IndPost-0.5], [0 100], 'color', 'm')

ylabel('Performance')

ha6b =  axes('unit', 'centimeters', 'position', [8 15.5 2 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [2 12]);
plot(1, 9,  'marker', 'o', 'markeredgecolor', 'w', 'markerfacecolor', col_perf(1, :));
plot(1, 7,  'marker', 'o', 'markeredgecolor', 'w', 'markerfacecolor', col_perf(2, :));
plot(1, 5,  'marker', 'o', 'markeredgecolor', 'w', 'markerfacecolor', col_perf(3, :));

text(2, 9, ['Correct: ' Paw], 'fontsize', 10)
text(2, 7, ['Premature: ' Paw], 'fontsize', 10)
text(2, 5, ['Late: ' Paw], 'fontsize', 10)


axis off

ha5 =  axes('unit', 'centimeters', 'position', [10 12.5 2 2.5], 'nextplot', 'add', 'xlim', [0 10], 'ylim', [2 12]);
text(2, 9, PressOut(1).RatName, 'fontsize', 10)

text(2, 6, sprintf(['Paw usage: ' Paw]), 'fontsize', 10)
axis off

tosavename=  ['ManualTrackingPeriFirstLesion' '_' PressOut(1).RatName '_Paw_' Paw];

print (hf,'-dpng', tosavename);
print (hf,'-depsc2', tosavename);