function PlotPressStimOptoPerformance(bmix, manipulation, printname)

% 7/11/2021 animal performance under a mixed schedule 
% these opto phases are (possibly) included: approach, press, trigger
% these behavioral parameters are analyzed: correct rate, premature rate
% (approach and press), and late rate
% reaction time and press duration are also analyzed. 

% revised based on PlotMixedOptoPerformance
% only deal with single condition:
% stim triggered by press

set(0,'defaultAxesFontSize', 8)
if nargin<3
    printname = [];
    if nargin<2
        manipulation = [];
    end;
end;

FPUnique = bmix(1).FPUnique;

% Extract useful information
App2PressLatency_Nostim = [];
App2PressLatency_Stim = [];

Performance_Nostim =  zeros(2, 4);
Performance_ApproachStim = zeros(2, 4);
Performance_PressStim = zeros(2, 4);
Performance_TriggerStim = zeros(2, 4);

RT_NoStim = cell(1, 2);
PrDur_NoStim = cell(1, 2);

RT_PressStim = cell(1, 2);
PrDur_PressStim = cell(1, 2);

RT_TriggerStim = cell(1, 2);
PrDur_TriggerStim = cell(1, 2);

PrDur_ApproachStim = cell(1, 2);
PrDur_ApproachStimLatency = cell(1, 2);

CorrectSessions =cell2mat(arrayfun(@(x)x.TrialsNoStim(:, 2)./x.TrialsNoStim(:, 1), bmix, 'uniformoutput', 0));
PrematureSessions =cell2mat(arrayfun(@(x)x.TrialsNoStim(:, 3)./x.TrialsNoStim(:, 1), bmix, 'uniformoutput', 0));
LateSessions =cell2mat(arrayfun(@(x)x.TrialsNoStim(:, 4)./x.TrialsNoStim(:, 1), bmix, 'uniformoutput', 0));
SessionNames = arrayfun(@(x)x.Metadata.Date(5:end), bmix, 'uniformoutput', 0);

StimDelay = [];
StimDur = [];

for i = 1:length(bmix)
    
    %     ind_appstim = bmix(i).StimTypeMarkers(strcmp(bmix(6).StimTypeLabels, 'Approach'));
    %     App2PressLatency_Nostim  = [App2PressLatency_Nostim bmix(i).Approach2Press(bmix(i).StimTypes == 0)];
    %     App2PressLatency_Stim  = [App2PressLatency_Stim bmix(i).Approach2Press(bmix(i).StimTypes == ind_appstim)];
    %
    Performance_Nostim = Performance_Nostim + bmix(i).TrialsNoStim(:, 1:4);
    %     Performance_ApproachStim = Performance_ApproachStim + bmix(i).TrialsApproachStim(:, 1:4);
    Performance_PressStim = Performance_PressStim + bmix(i).TrialsPressStim(:, 1:4);
    %     Performance_TriggerStim = Performance_TriggerStim + bmix(i).TrialsTriggerStim(:, 1:4);
    
    ind_stim = find(bmix(i).StimTypes == 2);
    
    StimDur = [StimDur; bmix(i).StimPattern(ind_stim, 1)];
    StimDelay = [StimDelay; bmix(i).StimPattern(ind_stim, 4)];
    
    
    for j = 1:length(bmix(i).RTNoStim)
        
        RT_NoStim{j} =  [RT_NoStim{j} bmix(i).RTNoStim{j}]; %
        PrDur_NoStim{j} = [PrDur_NoStim{j}  bmix(i).PrTNoStim{j}];
        
        RT_PressStim{j} = [RT_PressStim{j} bmix(i).RTPressStim{j}];
        PrDur_PressStim{j} = [PrDur_PressStim{j}  bmix(i).PrTPressStim{j}];
        %
        %         RT_TriggerStim{j} = [RT_TriggerStim{j} bmix(i).RTTriggerStim{j}];
        %         PrDur_TriggerStim{j} = [PrDur_TriggerStim{j}  bmix(i).PrTTriggerStim{j}];
        %
        %         PrDur_ApproachStim{j} = [PrDur_ApproachStim{j} bmix(i).PrTApproachStim{j}];
        %         PrDur_ApproachStimLatency{j} = [PrDur_ApproachStimLatency{j} bmix(i).PrTApproachStimLatency{j}];
        
    end;
end

%% Plot the results

hf19 = figure(19); clf,
set(gcf, 'name', 'OptoStimMix', 'units', 'centimeters', 'position', [0 0 30 19], 'paperpositionmode', 'auto');

% plot performance
col_perf = [85 225 0; 255 0 0; 140 140 140]/255;


% plot performance over sessions
% short FP
ha0 = axes('units', 'centimeters', 'position', [11 3 5 3], 'nextplot', 'add','xlim', [0 length(bmix)+1], 'ylim', [0-5 100], 'ytick', [20:20:100],'ygrid', 'on', 'xtick', [1:length(bmix)], 'xticklabel', SessionNames, 'XTickLabelRotation', 90, 'fontsize', 8);
plot([1:length(bmix)], 100*CorrectSessions(1, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')
plot([1:length(bmix)], 100*PrematureSessions(1, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')
plot([1:length(bmix)], 100*LateSessions(1, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')


xlabel('Sessions')
ylabel('Performance')
title('Short FP')

ha0note = axes('units', 'centimeters', 'position', [16.2 3 1 3], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 10], 'xtick', [ ], 'xticklabel', [], 'XTickLabelRotation', 90, 'fontsize', 8);
plot(3, 9,  'o',  'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w', 'linewidth', 1);
text(0, 8, 'Correct')
plot(3, 6,  'o',  'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w', 'linewidth', 1)
text(0, 5, 'Premature')
plot(3, 3,  'o', 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w', 'linewidth', 1)
text(0, 2, 'Late')
axis off
% long FP

ha00 = axes('units', 'centimeters', 'position', [20.5 3 5 3], 'nextplot', 'add','xlim', [0 length(bmix)+1], 'ylim', [0-5 100], 'ytick', [20:20:100],'ygrid', 'on',  'xtick', [1:length(bmix)], 'xticklabel', SessionNames, 'XTickLabelRotation', 90, 'fontsize', 8);
plot([1:length(bmix)], 100*CorrectSessions(2, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')
plot([1:length(bmix)], 100*PrematureSessions(2, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')
plot([1:length(bmix)], 100*LateSessions(2, :), 'o', 'linestyle', '-', 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w', 'linewidth', 1, 'color', 'k')


xlabel('Sessions')
ylabel('Performance')
title('Long FP')

ha1 = axes('units', 'centimeters', 'position', [2 8 3 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 100], 'xtick', [2:5:(size(Performance_Nostim, 1)-1)*5+2.5], 'xticklabel', {'short', 'long'});

for ifp = 1:size(Performance_Nostim, 1)
    for k =1:3
        hbar(k) =  bar(k+(ifp-1)*5, 100*Performance_Nostim(ifp, k+1)/Performance_Nostim(ifp, 1));
        set(hbar(k), 'facecolor',col_perf(k, :), 'edgecolor', 'w', 'BarWidth', 0.9);
    end;
end;

title('Control')
ylabel('Performance')

% %% Approach
% ha2 = axes('units', 'centimeters', 'position', [6 8 3 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 100], 'xtick', [2:5:(size(Performance_Nostim, 1)-1)*5+2.5], 'xticklabel', {'short', 'long'});
% 
% for ifp = 1:size(Performance_ApproachStim, 1)
%     for k =1:3
%         hbar(k) =  bar(k+(ifp-1)*5, 100*Performance_ApproachStim(ifp, k+1)/Performance_ApproachStim(ifp, 1));
%         set(hbar(k), 'facecolor',col_perf(k, :), 'edgecolor', 'w', 'BarWidth', 0.9);
%     end;
% end;
% 
% title('Opto(Approach)','color', 'b')
% ylabel('Performance')


%% Press
ha3 = axes('units', 'centimeters', 'position', [6 8 3 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 100], 'xtick', [2:5:(size(Performance_Nostim, 1)-1)*5+2.5], 'xticklabel', {'short', 'long'});

for ifp = 1:size(Performance_PressStim, 1)
    for k =1:3
        hbar(k) =  bar(k+(ifp-1)*5, 100*Performance_PressStim(ifp, k+1)/Performance_PressStim(ifp, 1));
        set(hbar(k), 'facecolor',col_perf(k, :), 'edgecolor', 'w', 'BarWidth', 0.9);
    end;
end;

title('Opto(Press)','color', 'b')
ylabel('Performance')


% %%  Trigger related
% 
% col_perf2 = [85 225 0; 140 140 140]/255;
% 
% ha1b = axes('units', 'centimeters', 'position', [2 2 3 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 100], 'xtick', [2:5:(size(Performance_Nostim, 1)-1)*5+2.5], 'xticklabel', {'short', 'long'});
% Performance_NostimTrig = Performance_Nostim(:, [2 4]);
% Performance_TriggerStim = Performance_TriggerStim(:, [2 4]);
% 
% for ifp = 1:size(Performance_NostimTrig, 1)
%     for k =1:2
%         hbar(k) =  bar(k+(ifp-1)*5, 100*Performance_NostimTrig(ifp, k)/sum(Performance_NostimTrig(ifp, :)));
%         set(hbar(k), 'facecolor',col_perf2(k, :), 'edgecolor', 'w', 'BarWidth', 0.9);
%     end;
% end;
% 
% title('Control')
% ylabel('Performance after trigger')
% %% Trigger stim
% ha2b = axes('units', 'centimeters', 'position', [6 2 3 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 100], 'xtick', [2:5:(size(Performance_Nostim, 1)-1)*5+2.5], 'xticklabel', {'short', 'long'});
% 
% for ifp = 1:size(Performance_TriggerStim, 1)
%     for k =1:2
%         hbar(k) =  bar(k+(ifp-1)*5, 100*Performance_TriggerStim(ifp, k)/sum(Performance_TriggerStim(ifp, :)));
%         set(hbar(k), 'facecolor',col_perf2(k, :), 'edgecolor', 'w', 'BarWidth', 0.9);
%     end;
% end;
% 
% title('Opto(Trigger)','color', 'b')
% ylabel('Performance')

%% plot approach to press latency 
% App2PressLatency_Nostim
% App2PressLatency_Stim
% ha4 = axes('units', 'centimeters', 'position', [2 14 3 4], 'nextplot', 'add','xlim', [0 3], 'ylim', [50 100], 'xtick', [1 2], 'xticklabel', {'Control', 'Stim'});
% 
% Pressed_NoStim = [length(find(~isnan(App2PressLatency_Nostim(App2PressLatency_Nostim~=0)))) length(App2PressLatency_Nostim(App2PressLatency_Nostim~=0)) ];
% Pressed_AppStim = [length(find(~isnan(App2PressLatency_Stim(App2PressLatency_Stim~=0)))) length(App2PressLatency_Stim(App2PressLatency_Stim~=0))];
% PressedRatio_Nostim = length(find(~isnan(App2PressLatency_Nostim(App2PressLatency_Nostim~=0))))/length(App2PressLatency_Nostim(App2PressLatency_Nostim~=0));
% PressedRatio_AppStim = length(find(~isnan(App2PressLatency_Stim(App2PressLatency_Stim~=0))))/length(App2PressLatency_Stim(App2PressLatency_Stim~=0));
% 
% hbar_nostim = bar(1, 100*PressedRatio_Nostim);
% set(hbar_nostim,  'facecolor',[0.8 0.8 0.8], 'edgecolor', 'w', 'BarWidth', 0.9)
% 
% hbar_appstim = bar(2, 100*PressedRatio_AppStim);
% set(hbar_appstim,  'facecolor',[0 184 255]/255, 'edgecolor', 'w', 'BarWidth', 0.9)
% 
% title('Pressed after approach')
% ylabel('Pressed/Approach')
% chi_out = chi_square_test(Pressed_NoStim, Pressed_AppStim)
% text(.5, 98, sprintf('p=%2.5f', chi_out.p));
% 
% ha5 = axes('units', 'centimeters', 'position', [6 14 3 4], 'nextplot', 'add','xlim', [0 3], 'ylim', [0.1 10],'yscale', 'log', 'xtick', [1 2], 'xticklabel', {'Control', 'Stim'})
% Latency_NoStim = App2PressLatency_Nostim(~isnan(App2PressLatency_Nostim) & App2PressLatency_Nostim>0);
% Latency_Stim = App2PressLatency_Stim(~isnan(App2PressLatency_Stim) & App2PressLatency_Stim>0);
% 
% latdata = {Latency_NoStim, Latency_Stim};
% latdataCat = [zeros(1, length(Latency_NoStim)), ones(1, length(Latency_Stim))];
%  
% plotSpread(latdata, 'categoryIdx', latdataCat,  'categoryMarkers',{'.','.'},...
%     'categoryColors',{[0.8 0.8 0.8],[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim'},'spreadWidth', 0.8, 'binWidth', 0.2)
% 
% LatencyNoStimCI95 = prctile(bootstrp(2000, @median, Latency_NoStim), [2.5 97.5]);
% line([1 1], LatencyNoStimCI95, 'color', 'k', 'linewidth', 1)
% plot(1, median(Latency_NoStim), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')
% 
% LatencyStimCI95 = prctile(bootstrp(2000, @median, Latency_Stim), [2.5 97.5]);
% line([2, 2], LatencyStimCI95, 'color', 'k', 'linewidth', 1)
% plot(2, median(Latency_Stim), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')
% 
% p_app = ranksum(Latency_NoStim, Latency_Stim);
% 
% text(0.5, 0.2, sprintf('p=%2.5f', p_app))
% ylabel('Approach-to-press latency (s)')

%% plot reaction time
ha6 = axes('units', 'centimeters', 'position', [11 14 5 4], 'nextplot', 'add','xlim', [0 3.5], 'ylim', [100 850],'yscale', 'linear','ytick', [200:200:600], 'xtick', [1 2], 'xticklabel', {'Control', 'Press'});
title(sprintf('Short FP (%2.0d ms)', bmix(1).FPUnique(1)))
% plot short

RT_NoStim_Short = RT_NoStim{1}; 
RT_NoStim_Short = RT_NoStim_Short(RT_NoStim_Short>100);

RT_PressStim_Short = RT_PressStim{1};
RT_PressStim_Short = RT_PressStim_Short(RT_PressStim_Short>100);

% RT_TriggerStim_Short = RT_TriggerStim{1};
% RT_TriggerStim_Short = RT_TriggerStim_Short(RT_TriggerStim_Short>100);

RTNoStimCI95_ShortFP            =       prctile(bootstrp(2000, @median, RT_NoStim_Short), [2.5 97.5]);
RT_PressStimCI95_ShortFP     =       prctile(bootstrp(2000, @median, RT_PressStim_Short), [2.5 97.5]);
% RT_TriggerStimCI95_ShortFP     =       prctile(bootstrp(2000, @median, RT_TriggerStim_Short), [2.5 97.5]);

sprintf('RT short FP control %2.2f ms, press-stim %2.2f ms', median(RT_NoStim_Short), median(RT_PressStim_Short))

RTShortdata = {RT_NoStim_Short, RT_PressStim_Short};
RTShortdataCat = [zeros(1, length(RT_NoStim_Short)), ones(1, length(RT_PressStim_Short))];
 
plotSpread(RTShortdata, 'categoryIdx', RTShortdataCat,  'categoryMarkers',{'.','.'},...
    'categoryColors',{[0.8 0.8 0.8],[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim(press)'},'spreadWidth', 0.8, 'binWidth', 0.2)

line([1 1], RTNoStimCI95_ShortFP, 'color', 'k', 'linewidth', 1)
plot(1, median(RT_NoStim_Short), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')

line([2 2], RT_PressStimCI95_ShortFP, 'color', 'k', 'linewidth', 1)
plot(2, median(RT_PressStim_Short), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')

% line([3 3], RT_TriggerStimCI95_ShortFP, 'color', 'k', 'linewidth', 1)
% plot(3, median(RT_TriggerStim_Short), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')

% p_RTshort= ranksum(RT_NoStim_Short, RT_PressStim_Short);

% text(0.5, 800, sprintf('p=%2.5f', p_RTshort))
set(gca, 'xlim', [0 3])
ylabel(' Reaction time (ms)')

% p = kruskalwallis(x)
% p = kruskalwallis(x,group)
% p = kruskalwallis(x,group,displayopt)
% [p,tbl,stats] = kruskalwallis(___)

% construct data for Kruskal Wallis test

RT_Short = [RT_NoStim_Short RT_PressStim_Short];
Group_Short = [repmat({'nostim'}, 1, length(RT_NoStim_Short)) repmat({'press'}, 1, length(RT_PressStim_Short))];
[p_ShortFP, tbl, stats_ShortFP] =  kruskalwallis(RT_Short, Group_Short, 'off');
figure(20);
% c_short = multcompare(stats_ShortFP);
% close(20);
% 
% figure(hf19)
axes(ha6)
 line([1 2], [800 800], 'color', 'm', 'linewidth', 1)
% line([2 3], [750 750], 'color', 'm', 'linewidth', 1)
% line([1 3], [700 700], 'color', 'm', 'linewidth', 1)

ha6stat = axes('units', 'centimeters', 'position', [16.1 14 2 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 11],'xtick', [], 'ytick', []);
% text(1, 11,  sprintf('multcompare'), 'fontsize', 10)
% text(1, 10, sprintf('p=%2.4f', c_short(1, 6)), 'fontsize', 10)
% text(1, 9, sprintf('p=%2.4f', c_short(3, 6)), 'fontsize', 10)
% text(1, 8, sprintf('p=%2.4f', c_short(2, 6)), 'fontsize', 10)
text(1, 6, sprintf('KW test '), 'fontsize', 10)
text(1, 5, sprintf('p=%2.5f', p_ShortFP), 'fontsize', 10)
axis off

%% plot data of long FP
ha6 = axes('units', 'centimeters', 'position', [20.5 14 5 4], 'nextplot', 'add','xlim', [0 3.5], 'ylim', [100 850],'yscale', 'linear','ytick', [200:200:600], 'xtick', [1 2], 'xticklabel', {'Control', 'Press'});
title(sprintf('Long FP (%2.0d ms)', bmix(1).FPUnique(2)))
% plot short

RT_NoStim_Long = RT_NoStim{2}; 
RT_NoStim_Long = RT_NoStim_Long(RT_NoStim_Long>100);

RT_PressStim_Long = RT_PressStim{2};
RT_PressStim_Long = RT_PressStim_Long(RT_PressStim_Long>100);

% RT_TriggerStim_Long = RT_TriggerStim{2};
% RT_TriggerStim_Long = RT_TriggerStim_Long(RT_TriggerStim_Long>100);

RTNoStimCI95_LongFP            =       prctile(bootstrp(2000, @median, RT_NoStim_Long), [2.5 97.5]);
RT_PressStimCI95_LongFP     =       prctile(bootstrp(2000, @median, RT_PressStim_Long), [2.5 97.5]);
% RT_TriggerStimCI95_LongFP     =       prctile(bootstrp(2000, @median, RT_TriggerStim_Long), [2.5 97.5]);

RTLongdata = {RT_NoStim_Long, RT_PressStim_Long};
RTLongdataCat = [zeros(1, length(RT_NoStim_Long)), ones(1, length(RT_PressStim_Long))];

sprintf('RT long FP control %2.2f ms, press-stim %2.2f ms', median(RT_NoStim_Long), median(RT_PressStim_Long))

plotSpread(RTLongdata, 'categoryIdx', RTLongdataCat,  'categoryMarkers',{'.','.'},...
    'categoryColors',{[0.8 0.8 0.8],[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim(press)'},'spreadWidth', 0.8, 'binWidth', 0.2)

line([1 1], RTNoStimCI95_LongFP, 'color', 'k', 'linewidth', 1)
plot(1, median(RT_NoStim_Long), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')

line([2 2], RT_PressStimCI95_LongFP, 'color', 'k', 'linewidth', 1)
plot(2, median(RT_PressStim_Long), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')
% 
% line([3 3], RT_TriggerStimCI95_LongFP, 'color', 'k', 'linewidth', 1)
% plot(3, median(RT_TriggerStim_Long), 'o', 'markersize', 4, 'linewidth', 1, 'color', 'k')

% p_RTshort= ranksum(RT_NoStim_Long, RT_PressStim_Long);

% text(0.5, 800, sprintf('p=%2.5f', p_RTshort))
set(gca, 'xlim', [0 3])
ylabel(' Reaction time (ms)')

% p = kruskalwallis(x)
% p = kruskalwallis(x,group)
% p = kruskalwallis(x,group,displayopt)
% [p,tbl,stats] = kruskalwallis(___)

% construct data for Kruskal Wallis test

RT_Long = [RT_NoStim_Long RT_PressStim_Long];
Group_Long = [repmat({'nostim'}, 1, length(RT_NoStim_Long)) repmat({'press'}, 1, length(RT_PressStim_Long))];
[p_LongFP, tbl, stats_LongFP] =  kruskalwallis(RT_Long, Group_Long, 'off');
% figure(20);
% c_short = multcompare(stats_LongFP);
% close(20);
% 
% figure(hf19)

axes(ha6)
line([1 2], [800 800], 'color', 'm', 'linewidth', 1)
% line([2 3], [750 750], 'color', 'm', 'linewidth', 1)
% line([1 3], [700 700], 'color', 'm', 'linewidth', 1)

ha6stat = axes('units', 'centimeters', 'position', [25.6 14 2 4], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 11],'xtick', [], 'ytick', []);

% text(1, 11,  sprintf('multcompare'), 'fontsize', 10)
% text(1, 10, sprintf('p=%2.4f', c_short(1, 6)), 'fontsize', 10)
% text(1, 9, sprintf('p=%2.4f', c_short(3, 6)), 'fontsize', 10)
% text(1, 8, sprintf('p=%2.4f', c_short(2, 6)), 'fontsize', 10)
text(1, 6, sprintf('KW test '), 'fontsize', 10)
text(1, 5, sprintf('p=%2.5f', p_LongFP), 'fontsize', 10)

axis off
hainfo = axes('units', 'centimeters', 'position', [2.5 4 4 2], 'nextplot', 'add','xlim', [0 10], 'ylim', [0 10],'xtick', [], 'ytick', []);
axis off
text(0, 3, ['ANM:'  bmix(1).Metadata.SubjectName])
text(0, 0, ['Opto:' manipulation])


%% plot press duration
ha7 = axes('units', 'centimeters', 'position', [11 8 5 4], 'nextplot', 'add','xlim', [0 3], 'ylim', [0 3000],'yscale', 'linear','ytick', [0:500:3000], 'xtick', [1 2 3 4], 'xticklabel', {'Control', 'Press'});
% plot short

plotshaded([0.5 2.5], [FPUnique(1) FPUnique(1); FPUnique(1)+600 FPUnique(1)+600],[175 255 175]/255)

PrDur_NoStim_Short = PrDur_NoStim{1}; 
PrDur_PressStim_Short = PrDur_PressStim{1};
% PrDur_TriggerStim_Short = PrDur_TriggerStim{1};

% PrDur_AppStim_Short = PrDur_ApproachStim{1}(PrDur_ApproachStimLatency{1}>0 & PrDur_ApproachStimLatency{1}<1.2 & ~isnan(PrDur_ApproachStimLatency{1}));

PrDurShortdata = {PrDur_NoStim_Short, PrDur_PressStim_Short};
PrDurShortdataCat = [zeros(1, length(PrDur_NoStim_Short)), ones(1, length(PrDur_PressStim_Short))];
 
plotSpread(PrDurShortdata, 'categoryIdx', PrDurShortdataCat,  'categoryMarkers',{'.','.'},...
    'categoryColors',{[0.8 0.8 0.8],[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim(press)'},'spreadWidth', 0.8, 'binWidth', 0.2)

ylabel('Press duration (ms)')

set(gca, 'xlim', [0 3])

% add stimulus timing
plotshaded([0 0.2], [mean(StimDelay) mean(StimDelay);mean(StimDelay)+mean(StimDur) mean(StimDelay)+mean(StimDur)], 'b')

% CDF plot
% ha7dist = axes('units', 'centimeters', 'position', [20.5 8 2.5 4], 'nextplot', 'add','xlim', [0 3000], 'ylim', [0 0.25],'xtick', [0:1000:3000], 'xticklabel', {'0', '1', '2', '3'},'ytick', [0:0.25:1])
% 
% plotshaded([750 750+600 ], [0 0; 1 1], [175 255 175]/255)
% 
% timebins = [0:250:3000];
% timecents = (timebins(1:end-1)+ timebins(2:end))/2;
% 
% [f_Nostim_Short, x_Nostim_Short] = ecdf(PrDur_NoStim_Short);
% [f_AppAndPressStim_Short, x_AppAndPressStim_Short] = ecdf([PrDur_AppStim_Short PrDur_PressStim_Short]);
% 
% 
% plot(x_Nostim_Short,f_Nostim_Short,  'k', 'linewidth', 1)
% plot(x_AppAndPressStim_Short,f_AppAndPressStim_Short, 'color', [0 184 255]/255, 'linewidth', 1.5)
% 
% 

% density
ha7ksd = axes('units', 'centimeters', 'position', [16.5 8 2.5 4], 'nextplot', 'add','xlim', [0 3000], 'ylim', [-0.02 0.25],'xtick', [0:1000:3000], 'xticklabel', {'0', '1', '2', '3'},'ytick', [0:0.25:1]);
timebins = [0:50:3000];
plotshaded([FPUnique(1) FPUnique(1)+600], [0 0; 1 1], [175 255 175]/255)
plotshaded([mean(StimDelay) mean(StimDelay)+mean(StimDur)], [0 0; -0.01 -0.01], 'b')

[f_ksNoStim] = ksdensity(PrDur_NoStim_Short, timebins,'Support','positive',...
	'Function','cdf','Bandwidth',0.025); 
[f_ksStim] = ksdensity([ PrDur_PressStim_Short], timebins,'Support','positive',...
	'Function','cdf','Bandwidth',0.025); 
plot(timebins, f_ksNoStim, 'color',  'k', 'linewidth', 1)
plot(timebins, f_ksStim, 'color',  [0 184 255]/255, 'linewidth', 1)
xlabel('Press duration (s)')

% add stimulus timing

ha8 = axes('units', 'centimeters', 'position', [20.5 8 5 4], 'nextplot', 'add','xlim', [0 3], 'ylim', [0 3000],'yscale', 'linear','ytick', [0:500:3000], 'xtick', [1 2], 'xticklabel', {'Control', 'Press'});
% plot long
plotshaded([0.5 2.5], [FPUnique(2) FPUnique(2); FPUnique(2)+600 FPUnique(2)+600],[175 255 175]/255)

PrDur_NoStim_Long = PrDur_NoStim{2}; 
PrDur_PressStim_Long = PrDur_PressStim{2};
% PrDur_TriggerStim_Long = PrDur_TriggerStim{2};
% PrDur_AppStim_Long= PrDur_ApproachStim{2}(PrDur_ApproachStimLatency{2}>0 & PrDur_ApproachStimLatency{2}<1.2 & ~isnan(PrDur_ApproachStimLatency{2}));


PrDurLongdata = {PrDur_NoStim_Long,  PrDur_PressStim_Long};
PrDurLongdataCat = [zeros(1, length(PrDur_NoStim_Long)), ones(1, length(PrDur_PressStim_Long))];
 
plotSpread(PrDurLongdata, 'categoryIdx', PrDurLongdataCat,  'categoryMarkers',{'.','.'},...
    'categoryColors',{[0.8 0.8 0.8],[0 184 255]/255}, 'categoryLabels', {'NoStim', 'Stim(press)'},'spreadWidth', 0.8, 'binWidth', 0.2)

plotshaded([0 0.2], [mean(StimDelay) mean(StimDelay);mean(StimDelay)+mean(StimDur) mean(StimDelay)+mean(StimDur)], 'b')

ylabel('Press duration (ms)')

set(gca, 'xlim', [0 3])

% ha8dist = axes('units', 'centimeters', 'position', [30 8 2.5 4], 'nextplot', 'add','xlim', [0 3000], 'ylim', [0 .25],'xtick', [0:1000:3000], 'xticklabel', {'0', '1', '2', '3'},'ytick', [0:0.25:1])
% plotshaded([1500 1500+600 ], [0 0; 1 1], [175 255 175]/255)
% 
% [f_Nostim_Long, x_Nostim_Long] = ecdf(PrDur_NoStim_Long);
% [f_AppAndPressStim_Long, x_AppAndPressStim_Long] = ecdf([PrDur_AppStim_Long PrDur_PressStim_Long]);
% 
% plot(x_Nostim_Long,f_Nostim_Long,  'k', 'linewidth', 1)
% plot(x_AppAndPressStim_Long,f_AppAndPressStim_Long, 'color', [0 184 255]/255, 'linewidth', 1.5)
% 
% density
ha8ksd = axes('units', 'centimeters', 'position', [26 8 2.5 4], 'nextplot', 'add','xlim', [0 3000], 'ylim', [-0.020 0.25],'xtick', [0:1000:3000], 'xticklabel', {'0', '1', '2', '3'},'ytick', [0:0.25:1]);
timebins = [0:50:3000];
plotshaded([FPUnique(2) FPUnique(2)+600 ], [0 0; 1 1], [175 255 175]/255)

[f_ksNoStim] = ksdensity(PrDur_NoStim_Long, timebins,'Support','positive',...
	'Function','cdf','Bandwidth',0.025); 
[f_ksStim] = ksdensity([PrDur_PressStim_Long], timebins,'Support','positive',...
	'Function','cdf','Bandwidth',0.025); 
plot(timebins, f_ksNoStim, 'color',  'k', 'linewidth', 1)
plot(timebins, f_ksStim, 'color',  [0 184 255]/255, 'linewidth', 1)

plotshaded([mean(StimDelay) mean(StimDelay)+mean(StimDur)], [0 0; -0.01 -0.01], 'b')

xlabel('Press duration (s)')

%% 
Dataout.ANM = bmix(1).Metadata.SubjectName;
Dataout.MixedOptoData = bmix;

Dataout.App2PressLatency.Nostim = App2PressLatency_Nostim;
Dataout.App2PressLatency.Stim = App2PressLatency_Stim;

Dataout.Performance.NoStim = Performance_Nostim;
% Dataout.Performance.ApproachStim = Performance_ApproachStim;
Dataout.Performance.PressStim = Performance_PressStim;
% Dataout.Performance.TriggerStim = Performance_TriggerStim;

Dataout.RT.NoStim = RT_NoStim;
Dataout.RT.PressStim = RT_PressStim;
% Dataout.RT.TriggerStim = RT_TriggerStim;

Dataout.PressDur.NoStim = PrDur_NoStim;
% Dataout.PressDur.AppStim = PrDur_ApproachStim;
% Dataout.PressDur.AppStimLatency = PrDur_ApproachStimLatency;
Dataout.PressDur.PressStim = PrDur_PressStim;
% Dataout.PressDur.TriggerStim = PrDur_TriggerStim;

savename = ['OptoPressStim_' Dataout.ANM printname];
save (savename, 'Dataout')

savename = ['OptoPressStim_'  Dataout.ANM printname]; 

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])


