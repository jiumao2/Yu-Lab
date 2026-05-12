function fig = behaviorSummary(r)

rb = r.Behavior;
info = Flash.conditionInfo(r);

eventMarkers = rb.EventMarkers(:);
eventTimings = rb.EventTimings(:);
labelNames = cellstr(string(rb.Labels(:)));
outcomeNames = cellstr(string(rb.Outcome(:)));
triggerTypes = rb.TriggerTypes(:);
foreperiodMs = rb.Foreperiods(:);

pressMarker = find(strcmp(labelNames, 'LeverPress'), 1, 'first');
releaseMarker = find(strcmp(labelNames, 'LeverRelease'), 1, 'first');
if isempty(pressMarker) || isempty(releaseMarker)
    error('Flash:MissingMarkers', 'Could not locate LeverPress or LeverRelease markers.');
end

pressTimes = eventTimings(eventMarkers == pressMarker);
releaseTimes = eventTimings(eventMarkers == releaseMarker);
nTrials = min([numel(pressTimes), numel(releaseTimes), numel(outcomeNames), ...
    numel(triggerTypes), numel(foreperiodMs)]);
pressTimes = pressTimes(1:nTrials);
releaseTimes = releaseTimes(1:nTrials);
outcomeNames = outcomeNames(1:nTrials);
triggerTypes = triggerTypes(1:nTrials);
foreperiodMs = foreperiodMs(1:nTrials);

holdDurationMs = releaseTimes - pressTimes;
reactionTimeMs = holdDurationMs - foreperiodMs;
sessionTimeSec = pressTimes ./ 1000;

conditionIndex = nan(nTrials, 1);
for iCond = 1:numel(info.Labels)
    conditionIndex(triggerTypes == info.TriggerCodes(iCond) & foreperiodMs == info.ConditionFPs(iCond)) = iCond;
end

validOutcomes = ismember(outcomeNames, info.OutcomeNames);
validConditions = ~isnan(conditionIndex);
isIncluded = validOutcomes & validConditions;
excludedNaNTrigger = sum(isnan(triggerTypes));
excludedOtherType = sum(~isnan(triggerTypes) & ~ismember(triggerTypes, info.StimCodes(:)));
excludedOtherFP = sum(ismember(triggerTypes, info.StimCodes(:)) & ~ismember(foreperiodMs, info.Foreperiods(:)));
excludedDark = sum(strcmp(outcomeNames, 'Dark'));
fprintf('Flash.behaviorSummary included %d/%d trials. Excluded total=%d. Notes: NaN trigger=%d, other type=%d, other FP=%d, Dark outcome=%d.\n', ...
    sum(isIncluded), nTrials, nTrials - sum(isIncluded), excludedNaNTrigger, excludedOtherType, excludedOtherFP, excludedDark);

subjectName = string(r.Meta(1).Subject);
dateTag = datestr(r.Meta(1).DateTime, 'yyyymmdd');
dateTitle = datestr(r.Meta(1).DateTime, 'yyyy-mm-dd');

fig = EasyPlot.figure('Visible', 'on');

axPanels = EasyPlot.createGridAxes(fig, 1, 4, ...
    'Width', 4, 'Height', 4, ...
    'MarginLeft', 1.0, 'MarginRight', 0.25, ...
    'MarginTop', 1.15, 'MarginBottom', 0.95, ...
    'Box', 'on');

axDist = EasyPlot.createGridAxes(fig, 1, 4, ...
    'Width', 3.2, 'Height', 3, ...
    'MarginLeft', 1.0, 'MarginRight', 0.8, ...
    'MarginTop', 0.9, 'MarginBottom', 0.95, ...
    'Box', 'on');

axBottom = EasyPlot.createGridAxes(fig, 1, 3, ...
    'Width', 4, 'Height', 3, ...
    'MarginLeft', 1.0, 'MarginRight', 1.0, ...
    'MarginTop', 0.8, 'MarginBottom', 1.9, ...
    'Box', 'on');

EasyPlot.place(axDist, axPanels, 'bottom');
EasyPlot.align(axDist, axPanels, 'left');
EasyPlot.move(axDist, 'dy', -0.2);
EasyPlot.place(axBottom, axDist, 'bottom');
EasyPlot.align(axBottom, axPanels, 'left');
EasyPlot.move(axBottom, 'dy', -0.25);

maxSessionSec = ceil(max(sessionTimeSec) / 100) * 100;
if maxSessionSec <= 0
    maxSessionSec = 500;
end

holdDurationClipped = min(holdDurationMs, 3000);
for iCond = 1:numel(info.Labels)
    ax = axPanels{iCond};
    fp = info.ConditionFPs(iCond);
    plot(ax, [0, maxSessionSec], [fp, fp], '--', ...
        'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
    condMask = isIncluded & conditionIndex == iCond;
    for iOutcome = 1:numel(info.OutcomeNames)
        mask = condMask & strcmp(outcomeNames, info.OutcomeNames{iOutcome});
        if any(mask)
            scatter(ax, sessionTimeSec(mask), holdDurationClipped(mask), 16, ...
                'Marker', 'o', ...
                'MarkerFaceColor', info.OutcomeColors(iOutcome, :), ...
                'MarkerEdgeColor', info.OutcomeColors(iOutcome, :), ...
                'MarkerFaceAlpha', 0.7, ...
                'LineWidth', 0.5);
        end
    end
    xlim(ax, [0, maxSessionSec]);
    xlabel(ax, 'Time in session (s)');
    title(ax, info.Labels{iCond}, 'FontWeight', 'normal', 'FontSize', 8);
end
EasyPlot.setYLim(axPanels, [0, 3000]);
EasyPlot.setGeneralTitle(axPanels, sprintf('%s | %s', subjectName, dateTitle), ...
    'FontWeight', 'bold', 'FontSize', 12, 'Height', 0.45, 'yShift', 0.5);

holdGridMs = 0:10:3000;
distColors = [
    0.16 0.52 0.78
    0.95 0.58 0.22];
for iFP = 1:numel(info.Foreperiods)
    fp = info.Foreperiods(iFP);
    axCdf = axDist{(iFP - 1) * 2 + 1};
    axPdf = axDist{(iFP - 1) * 2 + 2};
    for iStim = 1:numel(info.StimNames)
        condIdx = find(info.TriggerCodes == info.StimCodes(iStim) & info.ConditionFPs == fp, 1, 'first');
        mask = isIncluded & conditionIndex == condIdx;
        if sum(mask) >= 2
            cdfValues = ksdensity(holdDurationMs(mask), holdGridMs, 'Function', 'cdf');
            pdfValues = ksdensity(holdDurationMs(mask), holdGridMs, 'Function', 'pdf');
            plot(axCdf, holdGridMs, cdfValues, '-', 'Color', distColors(iStim, :), 'LineWidth', 1.2);
            plot(axPdf, holdGridMs, pdfValues, '-', 'Color', distColors(iStim, :), 'LineWidth', 1.2);
        else
            plot(axPdf, nan, nan, '-', 'Color', distColors(iStim, :), 'LineWidth', 1.2);
        end
    end
    plot(axCdf, [fp, fp], [0, 1], '--', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
    xlim(axCdf, [0, 3000]);
    ylim(axCdf, [0, 1]);
    xlim(axPdf, [0, 3000]);
    yMaxPdf = axPdf.YLim(2);
    plot(axPdf, [fp, fp], [0, yMaxPdf], '--', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
    xlim(axPdf, [0, 3000]);
    ylabel(axCdf, 'CDF');
    xlabel(axCdf, 'Hold duration (ms)');
    ylabel(axPdf, 'PDF (1/ms)');
    xlabel(axPdf, 'Hold duration (ms)');
    axPdf.YAxis.Exponent = 0;
    title(axCdf, sprintf('FP=%d CDF', fp), 'FontWeight', 'normal', 'FontSize', 8);
    title(axPdf, sprintf('FP=%d PDF', fp), 'FontWeight', 'normal', 'FontSize', 8);
end
legendHandles = gobjects(numel(info.StimNames), 1);
for iStim = 1:numel(info.StimNames)
    legendHandles(iStim) = plot(axDist{4}, nan, nan, '-', ...
        'Color', distColors(iStim, :), 'LineWidth', 1.2);
end
hLegend = EasyPlot.legend(axDist{4}, info.StimNames, ...
    'selectedPlots', legendHandles, ...
    'Location', 'northeastoutside', ...
    'lineLength', 0.35, ...
    'Box', 'off');
EasyPlot.move(hLegend, 'dx', -0.4);

winSize = 25;
stepSize = 5;
trialIds = find(isIncluded);
winCenters = [];
ratios = zeros(0, 3);
if numel(trialIds) >= winSize
    for startIdx = 1:stepSize:(numel(trialIds) - winSize + 1)
        idxWindow = trialIds(startIdx:(startIdx + winSize - 1));
        winCenters(end + 1, 1) = sessionTimeSec(idxWindow(round(numel(idxWindow) / 2))); %#ok<AGROW>
        row = zeros(1, 3);
        for iOutcome = 1:numel(info.OutcomeNames)
            row(iOutcome) = 100 * sum(strcmp(outcomeNames(idxWindow), info.OutcomeNames{iOutcome})) / numel(idxWindow);
        end
        ratios(end + 1, :) = row; %#ok<AGROW>
    end
end
for iOutcome = 1:numel(info.OutcomeNames)
    plot(axBottom{1}, winCenters, ratios(:, iOutcome), '-o', ...
        'Color', info.OutcomeColors(iOutcome, :), ...
        'MarkerFaceColor', info.OutcomeColors(iOutcome, :), ...
        'MarkerSize', 3.5, 'LineWidth', 1.0);
end
xlim(axBottom{1}, [0, maxSessionSec]);
ylim(axBottom{1}, [0, 100]);
EasyPlot.setXTicksAndLabels(axBottom{1}, 0:500:maxSessionSec, string(0:500:maxSessionSec));
xlabel(axBottom{1}, 'Time in session (s)');
ylabel(axBottom{1}, 'Performance (%)');
title(axBottom{1}, 'Performance over time', 'FontWeight', 'normal');

rtMask = isIncluded & ismember(outcomeNames, {'Correct', 'Late'});
rtValues = reactionTimeMs(rtMask);
rtCategories = conditionIndex(rtMask);
EasyPlot.violinplot(axBottom{2}, rtValues, rtCategories, ...
    'ViolinColor', info.Colors, ...
    'ViolinAlpha', 0.25, ...
    'MarkerSize', 8, ...
    'ShowMean', false, ...
    'ShowBox', true, ...
    'ShowMedian', true, ...
    'ShowWhiskers', false, ...
    'Width', 0.35);
xlim(axBottom{2}, [0.5, 4.5]);
ylim(axBottom{2}, [0, 1500]);
EasyPlot.setXTicksAndLabels(axBottom{2}, 1:4, info.Labels);
xlabel(axBottom{2}, 'Condition');
ylabel(axBottom{2}, 'Reaction time (ms)');
title(axBottom{2}, 'RT (Correct + Late)', 'FontWeight', 'normal');

groupedCounts = zeros(numel(info.Labels), numel(info.OutcomeNames));
for iCond = 1:numel(info.Labels)
    for iOutcome = 1:numel(info.OutcomeNames)
        groupedCounts(iCond, iOutcome) = sum(isIncluded & conditionIndex == iCond & ...
            strcmp(outcomeNames, info.OutcomeNames{iOutcome}));
    end
end
basePositions = 1:numel(info.Labels);
barWidth = 0.22;
barOffsets = [-barWidth, 0, barWidth];
groupTotals = sum(groupedCounts, 2);
for iOutcome = 1:numel(info.OutcomeNames)
    for iCond = 1:numel(info.Labels)
        xBar = basePositions(iCond) + barOffsets(iOutcome);
        thisCount = groupedCounts(iCond, iOutcome);
        bar(axBottom{3}, xBar, thisCount, barWidth, ...
            'FaceColor', info.OutcomeColors(iOutcome, :), ...
            'EdgeColor', 'none');
        if groupTotals(iCond) > 0
            thisPct = 100 * thisCount / groupTotals(iCond);
        else
            thisPct = NaN;
        end
        text(axBottom{3}, xBar, thisCount + 0.9, sprintf('%.1f%%', thisPct), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 7);
    end
end
xlim(axBottom{3}, [0.5, 4.5]);
ylim(axBottom{3}, [0, max(groupedCounts(:)) + 10]);
EasyPlot.setXTicksAndLabels(axBottom{3}, 1:4, info.Labels);
xlabel(axBottom{3}, 'Condition');
ylabel(axBottom{3}, 'Trial count');
title(axBottom{3}, 'Performance by condition', 'FontWeight', 'normal');
EasyPlot.set(axBottom{3}, 'Width', 10);

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile(pwd, sprintf('BehaviorSummary_Flash_%s_%s.png', subjectName, dateTag)), 'type', 'png');
EasyPlot.exportFigure(fig, fullfile(pwd, sprintf('BehaviorSummary_Flash_%s_%s.pdf', subjectName, dateTag)), 'type', 'pdf');
end
