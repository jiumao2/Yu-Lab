function fig = behaviorSummary(r)

rb = r.Behavior;
eventMarkers = rb.EventMarkers(:);
eventTimings = rb.EventTimings(:);
labelNames = cellstr(string(rb.Labels(:)));
triggerTypeLabels = cellstr(string(rb.TriggerTypeLabels(:)));
outcomeNames = cellstr(string(rb.Outcome(:)));
triggerTypeIds = rb.TriggerTypes(:);
foreperiodMs = rb.Foreperiods(:);
subjectName = string(r.Meta(1).Subject);
dateTag = datestr(r.Meta(1).DateTime, 'yyyymmdd');
dateTitle = datestr(r.Meta(1).DateTime, 'yyyy-mm-dd');

pressMarker = find(strcmp(labelNames, 'LeverPress'), 1, 'first');
releaseMarker = find(strcmp(labelNames, 'LeverRelease'), 1, 'first');
if isempty(pressMarker) || isempty(releaseMarker)
    error('Could not locate LeverPress or LeverRelease markers in r.Behavior.Labels.');
end

pressTimes = eventTimings(eventMarkers == pressMarker);
releaseTimes = eventTimings(eventMarkers == releaseMarker);

nTrials = min([numel(pressTimes), numel(releaseTimes), numel(outcomeNames), numel(triggerTypeIds), numel(foreperiodMs)]);
pressTimes = pressTimes(1:nTrials);
releaseTimes = releaseTimes(1:nTrials);
outcomeNames = outcomeNames(1:nTrials);
triggerTypeIds = triggerTypeIds(1:nTrials);
foreperiodMs = foreperiodMs(1:nTrials);
uniqueForeperiods = unique(foreperiodMs(~isnan(foreperiodMs)));
if ~isempty(uniqueForeperiods) && any(abs(uniqueForeperiods - 1500) > eps(1500))
    warning('behaviorSummarySession:ForeperiodMismatch', ...
        'This function assumes a fixed 1500 ms foreperiod, but found values: %s', mat2str(uniqueForeperiods'));
end

triggerNames = repmat({''}, nTrials, 1);
for i = 1:nTrials
    if triggerTypeIds(i) >= 1 && triggerTypeIds(i) <= numel(triggerTypeLabels)
        triggerNames{i} = triggerTypeLabels{triggerTypeIds(i)};
    else
        triggerNames{i} = 'Unknown';
    end
end

holdDurationMs = releaseTimes - pressTimes;
reactionTimeMs = holdDurationMs - 1500;
sessionTimeSec = pressTimes ./ 1000;

eligibleOutcomes = {'Correct', 'Premature', 'Late'};
correctLateOutcomes = {'Correct', 'Late'};
triggerOrder = {'None', 'Tone500', 'Tone750', 'Tone1000'};
triggerPanelMarkerArea = 16;
triggerLineColors = [
    0.25 0.25 0.25
    0.16 0.52 0.78
    0.95 0.58 0.22
    0.45 0.33 0.75];

outcomeOrder = {'Correct', 'Premature', 'Late'};
outcomeColors = [
    0.32 0.84 0.04
    0.92 0.14 0.12
    0.60 0.60 0.60];

isEligible = ismember(outcomeNames, eligibleOutcomes);
isCorrectLate = ismember(outcomeNames, correctLateOutcomes);
holdDurationMsClipped = min(holdDurationMs, 3000);

triggerOrderIndex = nan(nTrials, 1);
for i = 1:numel(triggerOrder)
    triggerOrderIndex(strcmp(triggerNames, triggerOrder{i})) = i;
end

fig = EasyPlot.figure('Visible', 'on');

axTriggerPanels = EasyPlot.createGridAxes(fig, 1, 4, ...
    'Width', 4, ...
    'Height', 4, ...
    'MarginLeft', 1.0, ...
    'MarginRight', 0.20, ...
    'MarginTop', 1.15, ...
    'MarginBottom', 0.95, ...
    'Box', 'on');

axDist = EasyPlot.createGridAxes(fig, 1, 2, ...
    'Width', 4, ...
    'Height', 3, ...
    'MarginLeft', 1, ...
    'MarginRight', 1, ...
    'MarginTop', 1, ...
    'MarginBottom', 1, ...
    'Box', 'on');

axBottom = EasyPlot.createGridAxes(fig, 1, 3, ...
    'Width', 4, ...
    'Height', 3, ...
    'MarginLeft', 1, ...
    'MarginRight', 1, ...
    'MarginTop', 1, ...
    'MarginBottom', 2, ...
    'Box', 'on');

EasyPlot.place(axDist, axTriggerPanels, 'bottom');
EasyPlot.align(axDist, axTriggerPanels, 'left');
EasyPlot.move(axDist, 'dy', -0.2);
EasyPlot.place(axBottom, axDist, 'bottom');
EasyPlot.align(axBottom, axTriggerPanels, 'left');
EasyPlot.move(axBottom, 'dy', -0.25);

maxSessionSec = ceil(max(sessionTimeSec) / 100) * 100;
if maxSessionSec <= 0
    maxSessionSec = 500;
end

triggerPanelTicks = [0, maxSessionSec];
triggerPanelTickLabels = {'0', sprintf('%d', maxSessionSec)};
for iType = 1:numel(triggerOrder)
    axThis = axTriggerPanels{iType};
    plot(axThis, [0, maxSessionSec], [1500, 1500], '--', ...
        'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
    typeMask = strcmp(triggerNames, triggerOrder{iType});
    for iOutcome = 1:numel(outcomeOrder)
        outcomeMask = strcmp(outcomeNames, outcomeOrder{iOutcome});
        thisMask = isEligible & typeMask & outcomeMask;
        if any(thisMask)
            scatter(axThis, ...
                sessionTimeSec(thisMask), ...
                holdDurationMsClipped(thisMask), ...
                triggerPanelMarkerArea, ...
                'Marker', 'o', ...
                'MarkerFaceColor', outcomeColors(iOutcome, :), ...
                'MarkerEdgeColor', outcomeColors(iOutcome, :), ...
                'MarkerFaceAlpha', 0.7, ...
                'LineWidth', 0.5);
        end
    end
    xlim(axThis, [0, maxSessionSec]);
    xlabel(axThis, 'Time in session (s)');

    title(axThis, triggerOrder{iType}, 'FontWeight', 'normal', 'FontSize', 8);
end

EasyPlot.setYLim(axTriggerPanels, [0, 3000]);
EasyPlot.setGeneralTitle(axTriggerPanels, sprintf('%s | %s', subjectName, dateTitle), ...
    'FontWeight', 'bold', 'FontSize', 12, 'Height', 0.45, 'yShift', 0.5);

holdGridMs = 0:10:3000;
lineHandlesDist = gobjects(numel(triggerOrder), 1);
for iType = 1:numel(triggerOrder)
    typeMask = isEligible & strcmp(triggerNames, triggerOrder{iType});
    if any(typeMask)
        cdfValues = ksdensity(holdDurationMs(typeMask), holdGridMs, 'Function', 'cdf');
        pdfValues = ksdensity(holdDurationMs(typeMask), holdGridMs, 'Function', 'pdf');
        plot(axDist{1}, holdGridMs, cdfValues, '-', 'Color', triggerLineColors(iType, :), 'LineWidth', 1.2);
        lineHandlesDist(iType) = plot(axDist{2}, holdGridMs, pdfValues, '-', 'Color', triggerLineColors(iType, :), 'LineWidth', 1.2);
    else
        lineHandlesDist(iType) = plot(axDist{2}, nan, nan, '-', 'Color', triggerLineColors(iType, :), 'LineWidth', 1.2);
    end
end
plot(axDist{1}, [1500, 1500], [0, 1], '--', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
xlim(axDist{1}, [0, 3000]);
ylim(axDist{1}, [0, 1]);
xlim(axDist{2}, [0, 3000]);
yMaxPdf = axDist{2}.YLim(2);
plot(axDist{2}, [1500, 1500], [0, yMaxPdf], '--', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
xlim(axDist{2}, [0, 3000]);
ylabel(axDist{1}, 'CDF');
xlabel(axDist{1}, 'Hold duration (ms)');
ylabel(axDist{2}, 'PDF (1/ms)');
xlabel(axDist{2}, 'Hold duration (ms)');
title(axDist{1}, 'Hold-duration CDF', 'FontWeight', 'normal');
title(axDist{2}, 'Hold-duration PDF', 'FontWeight', 'normal');
hTypeLegend = EasyPlot.legend(axDist{2}, triggerOrder, ...
    'selectedPlots', lineHandlesDist, ...
    'Location', 'northeastoutside', ...
    'lineLength', 0.35, ...
    'Box', 'off');
EasyPlot.move(hTypeLegend, 'dx', -0.6);

winSize = 25;
stepSize = 5;
winCenters = [];
correctRatio = [];
prematureRatio = [];
lateRatio = [];
for startIdx = 1:stepSize:(nTrials - winSize + 1)
    idxWindow = startIdx:(startIdx + winSize - 1);
    outcomeWindow = outcomeNames(idxWindow);
    eligibleWindowMask = ismember(outcomeWindow, eligibleOutcomes);
    eligibleCount = sum(eligibleWindowMask);
    if eligibleCount > 0
        winCenters(end + 1, 1) = sessionTimeSec(round(median(idxWindow))); %#ok<AGROW>
        correctRatio(end + 1, 1) = 100 * sum(strcmp(outcomeWindow, 'Correct')) / eligibleCount; %#ok<AGROW>
        prematureRatio(end + 1, 1) = 100 * sum(strcmp(outcomeWindow, 'Premature')) / eligibleCount; %#ok<AGROW>
        lateRatio(end + 1, 1) = 100 * sum(strcmp(outcomeWindow, 'Late')) / eligibleCount; %#ok<AGROW>
    end
end

plot(axBottom{1}, winCenters, correctRatio, '-o', 'Color', outcomeColors(1, :), 'MarkerFaceColor', outcomeColors(1, :), 'MarkerSize', 3.5, 'LineWidth', 1.0);
plot(axBottom{1}, winCenters, prematureRatio, '-o', 'Color', outcomeColors(2, :), 'MarkerFaceColor', outcomeColors(2, :), 'MarkerSize', 3.5, 'LineWidth', 1.0);
plot(axBottom{1}, winCenters, lateRatio, '-o', 'Color', outcomeColors(3, :), 'MarkerFaceColor', outcomeColors(3, :), 'MarkerSize', 3.5, 'LineWidth', 1.0);
xlim(axBottom{1}, [0, maxSessionSec]);
ylim(axBottom{1}, [0, 100]);
EasyPlot.setXTicksAndLabels(axBottom{1}, 0:500:maxSessionSec, string(0:500:maxSessionSec));
xlabel(axBottom{1}, 'Time in session (s)');
ylabel(axBottom{1}, 'Performance (%)');
title(axBottom{1}, 'Performance over time', 'FontWeight', 'normal');

rtMask = isCorrectLate & ~isnan(triggerOrderIndex);
rtValues = reactionTimeMs(rtMask);
rtCategories = triggerOrderIndex(rtMask);
violins = EasyPlot.violinplot(axBottom{2}, rtValues, rtCategories, ...
    'ViolinColor', triggerLineColors, ...
    'ViolinAlpha', 0.25, ...
    'MarkerSize', 8, ...
    'ShowMean', false, ...
    'ShowBox', true, ...
    'ShowMedian', true, ...
    'ShowWhiskers', false, ...
    'Width', 0.35);
% for iType = 1:numel(violins)
%     violins(iType).EdgeColor = [0.25, 0.25, 0.25];
%     violins(iType).BoxColor = [0.25, 0.25, 0.25];
%     violins(iType).MedianColor = [1, 1, 1];
% end
xlim(axBottom{2}, [0.5, 4.5]);
ylim(axBottom{2}, [0, 1500]);
EasyPlot.setXTicksAndLabels(axBottom{2}, 1:4, triggerOrder);
xlabel(axBottom{2}, 'Trigger type');
ylabel(axBottom{2}, 'Reaction time (ms)');
title(axBottom{2}, 'RT (Correct + Late)', 'FontWeight', 'normal');

groupedCounts = zeros(numel(triggerOrder), numel(outcomeOrder));
for iType = 1:numel(triggerOrder)
    typeMask = strcmp(triggerNames, triggerOrder{iType});
    for iOutcome = 1:numel(outcomeOrder)
        groupedCounts(iType, iOutcome) = sum(typeMask & strcmp(outcomeNames, outcomeOrder{iOutcome}));
    end
end
groupTotals = sum(groupedCounts, 2);
basePositions = 1:numel(triggerOrder);
barWidth = 0.25;
barOffsets = [-barWidth, 0, barWidth];
for iOutcome = 1:numel(outcomeOrder)
    for iType = 1:numel(triggerOrder)
        xBar = basePositions(iType) + barOffsets(iOutcome);
        thisCount = groupedCounts(iType, iOutcome);
        bar(axBottom{3}, xBar, thisCount, barWidth, 'FaceColor', outcomeColors(iOutcome, :), 'EdgeColor', 'none');
        if groupTotals(iType) > 0
            thisPct = 100 * thisCount / groupTotals(iType);
        else
            thisPct = NaN;
        end
        text(axBottom{3}, xBar, thisCount + 0.9, sprintf('%.1f%%', thisPct), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom',...
            'FontSize', 7);
    end
end
xlim(axBottom{3}, [0.5, 4.5]);
ylim(axBottom{3}, [0, max(groupedCounts(:)) + 8]);
EasyPlot.setXTicksAndLabels(axBottom{3}, 1:4, triggerOrder);
xlabel(axBottom{3}, 'Trigger type');
ylabel(axBottom{3}, 'Trial count');
title(axBottom{3}, 'Performance by trigger type', 'FontWeight', 'normal');
EasyPlot.set(axBottom{3}, 'Width', 10);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile('.', sprintf('BehaviorSummary_GAVI_%s.png', dateTag)), 'type', 'png');
EasyPlot.exportFigure(fig, fullfile('.', sprintf('BehaviorSummary_GAVI_%s.pdf', dateTag)), 'type', 'pdf');
end
