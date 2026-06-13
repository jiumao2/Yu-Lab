function fig = behaviorSummaryLearning(r)

rb = r.Behavior;
eventMarkers = rb.EventMarkers(:);
eventTimings = rb.EventTimings(:);
labelNames = cellstr(string(rb.Labels(:)));
outcomeNames = cellstr(string(rb.Outcome(:)));
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

nTrials = min([numel(pressTimes), numel(releaseTimes), numel(outcomeNames), numel(foreperiodMs)]);
pressTimes = pressTimes(1:nTrials);
releaseTimes = releaseTimes(1:nTrials);
outcomeNames = outcomeNames(1:nTrials);
foreperiodMs = foreperiodMs(1:nTrials);

extraToneVolumes = nan(nTrials, 1);
if isfield(rb, 'ExtraToneVolumes')
    n = min(nTrials, numel(rb.ExtraToneVolumes));
    extraToneVolumes(1:n) = rb.ExtraToneVolumes(1:n);
end
isTestTrials = false(nTrials, 1);
if isfield(rb, 'IsTestTrials')
    n = min(nTrials, numel(rb.IsTestTrials));
    isTestTrials(1:n) = logical(rb.IsTestTrials(1:n));
end
postLearningTrials = false(nTrials, 1);
if isfield(rb, 'PostLearningPhaseTrials')
    n = min(nTrials, numel(rb.PostLearningPhaseTrials));
    postLearningTrials(1:n) = logical(rb.PostLearningPhaseTrials(1:n));
end

holdDurationMs = releaseTimes - pressTimes;
reactionTimeMs = holdDurationMs - foreperiodMs;
sessionTimeSec = pressTimes ./ 1000;
uniqueForeperiods = unique(foreperiodMs(~isnan(foreperiodMs)));
uniqueForeperiods = uniqueForeperiods(:)';
if isempty(uniqueForeperiods)
    uniqueForeperiods = 1500;
end

outcomeOrder = {'Correct', 'Premature', 'Late'};
outcomeColors = [
    0.32 0.84 0.04
    0.92 0.14 0.12
    0.60 0.60 0.60];
outcomeMarkers = {'o', 'o', 'o'};

conditionLabels = {'Learning', 'Test', 'Post on', 'Post off'};
conditionColors = [
    0.25 0.25 0.25
    0.45 0.33 0.75
    0.10 0.45 0.80
    0.65 0.65 0.65];
conditionIndex = nan(nTrials, 1);
conditionIndex(~postLearningTrials & ~isTestTrials) = 1;
conditionIndex(isTestTrials) = 2;
conditionIndex(postLearningTrials & ~isTestTrials & extraToneVolumes > 0) = 3;
conditionIndex(postLearningTrials & ~isTestTrials & extraToneVolumes <= 0) = 4;

validOutcome = ismember(outcomeNames, outcomeOrder);
isDark = strcmp(outcomeNames, 'Dark');
isShortHold = holdDurationMs < 750;
validFP = ~isnan(foreperiodMs);
validCondition = ~isnan(conditionIndex);
isIncluded = validOutcome & ~isShortHold & validFP & validCondition;
excludedOther = sum(~isIncluded & ~isDark & ~isShortHold);

fprintf(['DoubleTone.behaviorSummary included %d/%d trials. Excluded: Dark=%d, ', ...
    'holdDuration<750ms=%d, invalid condition/FP/outcome=%d.\n'], ...
    sum(isIncluded), nTrials, sum(isDark), sum(isShortHold), ...
    excludedOther);

activeConditionCodes = find(arrayfun(@(x) any(isIncluded & conditionIndex == x), 1:numel(conditionLabels)));
if isempty(activeConditionCodes)
    activeConditionCodes = 1:numel(conditionLabels);
end
activeConditionLabels = conditionLabels(activeConditionCodes);
activeConditionColors = conditionColors(activeConditionCodes, :);

fig = EasyPlot.figure('Visible', 'on');

axTop = EasyPlot.createGridAxes(fig, 1, 2, ...
    'Width', 5.8, ...
    'Height', 4, ...
    'MarginLeft', 1.0, ...
    'MarginRight', 0.55, ...
    'MarginTop', 1.15, ...
    'MarginBottom', 0.95, ...
    'Box', 'on');

axDist = EasyPlot.createGridAxes(fig, 1, max(2, numel(uniqueForeperiods) * 2), ...
    'Width', 3.4, ...
    'Height', 3, ...
    'MarginLeft', 1.0, ...
    'MarginRight', 0.80, ...
    'MarginTop', 0.9, ...
    'MarginBottom', 0.95, ...
    'Box', 'on');

axBottom = EasyPlot.createGridAxes(fig, 1, 3, ...
    'Width', 4.4, ...
    'Height', 3, ...
    'MarginLeft', 1.0, ...
    'MarginRight', 1.0, ...
    'MarginTop', 0.8, ...
    'MarginBottom', 1.9, ...
    'Box', 'on');

EasyPlot.place(axDist, axTop, 'bottom');
EasyPlot.align(axDist, axTop, 'left');
EasyPlot.move(axDist, 'dy', -0.2);
EasyPlot.place(axBottom, axDist, 'bottom');
EasyPlot.align(axBottom, axTop, 'left');
EasyPlot.move(axBottom, 'dy', -0.25);

maxSessionSec = ceil(max(sessionTimeSec) / 100) * 100;
if maxSessionSec <= 0
    maxSessionSec = 500;
end

plotTimelinePanel(axTop{1}, isIncluded & ~isTestTrials, 'Learning and post-learning phase', true, true);
plotTimelinePanel(axTop{2}, isIncluded & conditionIndex == 2, 'Test trials', false, false);
EasyPlot.setYLim(axTop, [0, 3000]);
EasyPlot.setGeneralTitle(axTop, sprintf('%s | %s', subjectName, dateTitle), ...
    'FontWeight', 'bold', 'FontSize', 12, 'Height', 0.45, 'yShift', 0.5);

colormap(axTop{1}, parula);
caxis(axTop{1}, [0 1]);
colormap(axTop{2}, parula);
caxis(axTop{2}, [0 1]);
EasyPlot.colorbar(axTop{2}, ...
    'Ticks', [0 0.5 1], ...
    'label', 'Extra tone volume', ...
    'FontSize', 7, ...
    'MarginRight', 0.8);

holdGridMs = 0:10:3000;
legendHandles = gobjects(numel(activeConditionCodes), 1);
for iFP = 1:numel(uniqueForeperiods)
    fp = uniqueForeperiods(iFP);
    axCdf = axDist{(iFP - 1) * 2 + 1};
    axPdf = axDist{(iFP - 1) * 2 + 2};
    for iCond = 1:numel(activeConditionCodes)
        thisCondition = activeConditionCodes(iCond);
        mask = isIncluded & foreperiodMs == fp & conditionIndex == thisCondition;
        if sum(mask) >= 2
            cdfValues = ksdensity(holdDurationMs(mask), holdGridMs, 'Function', 'cdf');
            pdfValues = ksdensity(holdDurationMs(mask), holdGridMs, 'Function', 'pdf');
            plot(axCdf, holdGridMs, cdfValues, '-', 'Color', activeConditionColors(iCond, :), 'LineWidth', 1.2);
            plot(axPdf, holdGridMs, pdfValues, '-', 'Color', activeConditionColors(iCond, :), 'LineWidth', 1.2);
        else
            plot(axPdf, nan, nan, '-', 'Color', activeConditionColors(iCond, :), 'LineWidth', 1.2);
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
for iCond = 1:numel(activeConditionCodes)
    legendHandles(iCond) = plot(axDist{min(numel(axDist), 2)}, nan, nan, '-', ...
        'Color', activeConditionColors(iCond, :), 'LineWidth', 1.2);
end
hLegend = EasyPlot.legend(axDist{min(numel(axDist), 2)}, activeConditionLabels, ...
    'selectedPlots', legendHandles, ...
    'Location', 'northeastoutside', ...
    'lineLength', 0.35, ...
    'Box', 'off');
EasyPlot.move(hLegend, 'dx', -0.4);

winSize = 25;
stepSize = 5;
trialIds = find(isIncluded);
winCenters = [];
ratios = zeros(0, numel(outcomeOrder));
if numel(trialIds) >= winSize
    for startIdx = 1:stepSize:(numel(trialIds) - winSize + 1)
        idxWindow = trialIds(startIdx:(startIdx + winSize - 1));
        winCenters(end + 1, 1) = sessionTimeSec(idxWindow(round(numel(idxWindow) / 2))); %#ok<AGROW>
        row = zeros(1, numel(outcomeOrder));
        for iOutcome = 1:numel(outcomeOrder)
            row(iOutcome) = 100 * sum(strcmp(outcomeNames(idxWindow), outcomeOrder{iOutcome})) / numel(idxWindow);
        end
        ratios(end + 1, :) = row; %#ok<AGROW>
    end
end
for iOutcome = 1:numel(outcomeOrder)
    plot(axBottom{1}, winCenters, ratios(:, iOutcome), '-o', ...
        'Color', outcomeColors(iOutcome, :), ...
        'MarkerFaceColor', outcomeColors(iOutcome, :), ...
        'MarkerSize', 3.5, 'LineWidth', 1.0);
end
xlim(axBottom{1}, [0, maxSessionSec]);
ylim(axBottom{1}, [0, 100]);
EasyPlot.setXTicksAndLabels(axBottom{1}, 0:500:maxSessionSec, string(0:500:maxSessionSec));
xlabel(axBottom{1}, 'Time in session (s)');
ylabel(axBottom{1}, 'Performance (%)');
title(axBottom{1}, 'Performance over time', 'FontWeight', 'normal');

[groupLabels, groupFPs, groupConditions] = makeGroupLabels(uniqueForeperiods, activeConditionLabels, activeConditionCodes);
rtMask = isIncluded & ismember(outcomeNames, {'Correct', 'Late'});
rtCategories = nan(nTrials, 1);
for iGroup = 1:numel(groupLabels)
    rtCategories(foreperiodMs == groupFPs(iGroup) & conditionIndex == groupConditions(iGroup)) = iGroup;
end
rtValues = reactionTimeMs(rtMask & ~isnan(rtCategories));
rtGroupValues = rtCategories(rtMask & ~isnan(rtCategories));
if ~isempty(rtValues)
    violinColors = conditionColors(groupConditions, :);
    EasyPlot.violinplot(axBottom{2}, rtValues, rtGroupValues, ...
        'ViolinColor', violinColors, ...
        'ViolinAlpha', 0.25, ...
        'MarkerSize', 8, ...
        'ShowMean', false, ...
        'ShowBox', true, ...
        'ShowMedian', true, ...
        'ShowWhiskers', false, ...
        'Width', 0.35);
end
xlim(axBottom{2}, [0.5, numel(groupLabels) + 0.5]);
ylim(axBottom{2}, [0, 1500]);
EasyPlot.setXTicksAndLabels(axBottom{2}, 1:numel(groupLabels), groupLabels);
xtickangle(axBottom{2}, 35);
xlabel(axBottom{2}, 'FP x condition');
ylabel(axBottom{2}, 'Reaction time (ms)');
title(axBottom{2}, 'RT (Correct + Late)', 'FontWeight', 'normal');

groupedCounts = zeros(numel(groupLabels), numel(outcomeOrder));
for iGroup = 1:numel(groupLabels)
    groupMask = isIncluded & foreperiodMs == groupFPs(iGroup) & conditionIndex == groupConditions(iGroup);
    for iOutcome = 1:numel(outcomeOrder)
        groupedCounts(iGroup, iOutcome) = sum(groupMask & strcmp(outcomeNames, outcomeOrder{iOutcome}));
    end
end
basePositions = 1:numel(groupLabels);
barWidth = 0.22;
barOffsets = [-barWidth, 0, barWidth];
groupTotals = sum(groupedCounts, 2);
for iOutcome = 1:numel(outcomeOrder)
    for iGroup = 1:numel(groupLabels)
        xBar = basePositions(iGroup) + barOffsets(iOutcome);
        thisCount = groupedCounts(iGroup, iOutcome);
        bar(axBottom{3}, xBar, thisCount, barWidth, ...
            'FaceColor', outcomeColors(iOutcome, :), ...
            'EdgeColor', 'none');
        if groupTotals(iGroup) > 0
            thisPct = 100 * thisCount / groupTotals(iGroup);
            textString = sprintf('%.1f%%', thisPct);
        else
            textString = '';
        end
        text(axBottom{3}, xBar, thisCount + 0.9, textString, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 7);
    end
end
xlim(axBottom{3}, [0.5, numel(groupLabels) + 0.5]);
ylim(axBottom{3}, [0, max([groupedCounts(:); 1]) + 10]);
EasyPlot.setXTicksAndLabels(axBottom{3}, 1:numel(groupLabels), groupLabels);
xtickangle(axBottom{3}, 35);
xlabel(axBottom{3}, 'FP x condition');
ylabel(axBottom{3}, 'Trial count');
title(axBottom{3}, 'Performance by condition', 'FontWeight', 'normal');
EasyPlot.set(axBottom{3}, 'Width', max(10, numel(groupLabels) * 1.7));

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile(pwd, sprintf('BehaviorSummary_DoubleToneLearning_%s_%s.png', subjectName, dateTag)), 'type', 'png');
EasyPlot.exportFigure(fig, fullfile(pwd, sprintf('BehaviorSummary_DoubleToneLearning_%s_%s.pdf', subjectName, dateTag)), 'type', 'pdf');

    function plotTimelinePanel(ax, mask, panelTitle, colorCodeVolume, shadePostLearning)
        if shadePostLearning
            postMask = postLearningTrials & ~isTestTrials & ~isnan(sessionTimeSec);
            if any(postMask)
                postX = sessionTimeSec(postMask);
                patch(ax, [min(postX) max(postX) max(postX) min(postX)], [0 0 3000 3000], ...
                    [0.80 0.87 1.00], 'FaceAlpha', 0.18, 'EdgeColor', 'none');
            end
        end
        for iFPLine = 1:numel(uniqueForeperiods)
            yline(ax, uniqueForeperiods(iFPLine), '--', ...
                'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
        end
        if any(mask & extraToneVolumes > 0)
            yline(ax, 750, '--', ...
                'Color', [0.45, 0.45, 0.45], 'LineWidth', 0.8);
        end
        if any(mask)
            for iOutcomePanel = 1:numel(outcomeOrder)
                outcomeMask = mask & strcmp(outcomeNames, outcomeOrder{iOutcomePanel});
                if ~any(outcomeMask)
                    continue
                end
                if colorCodeVolume
                    volumeThis = extraToneVolumes(outcomeMask);
                    validVolume = ~isnan(volumeThis);
                    xThis = sessionTimeSec(outcomeMask);
                    yThis = min(holdDurationMs(outcomeMask), 3000);
                    scatter(ax, xThis(validVolume), yThis(validVolume), 18, volumeThis(validVolume), ...
                        'Marker', outcomeMarkers{iOutcomePanel}, ...
                        'MarkerFaceColor', 'flat', ...
                        'MarkerEdgeColor', 'none', ...
                        'MarkerFaceAlpha', 0.75, ...
                        'LineWidth', 0.6);
                    if any(~validVolume)
                        scatter(ax, xThis(~validVolume), yThis(~validVolume), 18, ...
                            'Marker', outcomeMarkers{iOutcomePanel}, ...
                            'MarkerFaceColor', [0.75 0.75 0.75], ...
                            'MarkerEdgeColor', 'none', ...
                            'MarkerFaceAlpha', 0.75, ...
                            'LineWidth', 0.6);
                    end
                else
                    xThis = sessionTimeSec(outcomeMask);
                    yThis = min(holdDurationMs(outcomeMask), 3000);
                    scatter(ax, xThis, yThis, 18, ...
                        'Marker', outcomeMarkers{iOutcomePanel}, ...
                        'MarkerFaceColor', outcomeColors(iOutcomePanel, :), ...
                        'MarkerEdgeColor', 'none', ...
                        'MarkerFaceAlpha', 0.70, ...
                        'LineWidth', 0.5);
                end
            end
        else
            text(ax, maxSessionSec * 0.5, 1500, 'No trials', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 8, ...
                'Color', [0.45 0.45 0.45]);
        end
        xlim(ax, [0, maxSessionSec]);
        ylim(ax, [0, 3000]);
        xlabel(ax, 'Time in session (s)');
        ylabel(ax, 'Hold duration (ms)');
        title(ax, panelTitle, 'FontWeight', 'normal', 'FontSize', 8);
    end

    function [labels, fps, conds] = makeGroupLabels(fpsIn, condLabels, condCodes)
        labels = strings(1, numel(fpsIn) * numel(condLabels));
        fps = nan(1, numel(labels));
        conds = nan(1, numel(labels));
        idx = 0;
        for iFPGroup = 1:numel(fpsIn)
            for iCondGroup = 1:numel(condLabels)
                idx = idx + 1;
                labels(idx) = sprintf('FP%d %s', fpsIn(iFPGroup), condLabels{iCondGroup});
                fps(idx) = fpsIn(iFPGroup);
                conds(idx) = condCodes(iCondGroup);
            end
        end
    end
end
