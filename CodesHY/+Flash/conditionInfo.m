function info = conditionInfo(r)

rb = r.Behavior;
triggerLabels = cellstr(string(rb.TriggerTypeLabels(:)))';
triggerLabels = triggerLabels(~cellfun(@isempty, triggerLabels));
if isempty(triggerLabels)
    error('Flash:MissingTriggerLabels', ...
        'Expected Behavior.TriggerTypeLabels to contain at least one valid trigger label.');
end

triggerCodesAll = 1:numel(triggerLabels);
triggerCodes = triggerCodesAll;

standardForeperiods = [750, 1500];
mixedFP = [];
if isfield(r, 'BehaviorClass') && isfield(r.BehaviorClass, 'MixedFP') && ~isempty(r.BehaviorClass.MixedFP)
    mixedFP = round(r.BehaviorClass.MixedFP(:)');
end
mixedFP = mixedFP(~isnan(mixedFP) & mixedFP > 0);
foreperiods = intersect(standardForeperiods, mixedFP, 'stable');

if isempty(foreperiods)
    foreperiods = standardForeperiods;
end
stimNames = triggerLabels(triggerCodes);

flashCode = find(strcmpi(triggerLabels, 'Flash'), 1, 'first');
toneCode = find(strcmpi(triggerLabels, 'Tone'), 1, 'first');
isOldFlashTone2x2 = numel(triggerCodes) == 2 && ...
    isequal(sort(triggerCodes), sort([flashCode, toneCode])) && ...
    isequal(foreperiods, [750, 1500]);

if isOldFlashTone2x2
    info.TriggerLabels = triggerLabels;
    info.StimNames = {'Flash', 'Tone'};
    info.StimCodes = [flashCode, toneCode];
    info.Foreperiods = [750, 1500];
    info.Labels = {'Tone750', 'Flash750', 'Tone1500', 'Flash1500'};
    info.ShortLabels = {'Tone | FP=0.75 s', 'Flash | FP=0.75 s', ...
        'Tone | FP=1.5 s', 'Flash | FP=1.5 s'};
    info.Codes = 1:4;
    info.TriggerCodes = [toneCode, flashCode, toneCode, flashCode];
    info.ConditionFPs = [750, 750, 1500, 1500];
    info.Colors = [
        0.25 0.25 0.25
        0.16 0.52 0.78
        0.95 0.58 0.22
        0.45 0.33 0.75];
else
    labels = {};
    shortLabels = {};
    conditionFPs = [];
    conditionTriggerCodes = [];
    for iFP = 1:numel(foreperiods)
        for iStim = 1:numel(stimNames)
            labels{end + 1} = sprintf('%s%d', stimNames{iStim}, foreperiods(iFP)); %#ok<AGROW>
            shortLabels{end + 1} = sprintf('%s | FP=%.3g s', stimNames{iStim}, foreperiods(iFP)/1000); %#ok<AGROW>
            conditionFPs(end + 1) = foreperiods(iFP); %#ok<AGROW>
            conditionTriggerCodes(end + 1) = triggerCodes(iStim); %#ok<AGROW>
        end
    end

    baseColors = [
        0.25 0.25 0.25
        0.16 0.52 0.78
        0.95 0.58 0.22
        0.45 0.33 0.75
        0.35 0.70 0.30
        0.80 0.35 0.35
        0.20 0.65 0.65
        0.65 0.45 0.20];
    if numel(labels) <= size(baseColors, 1)
        conditionColors = baseColors(1:numel(labels), :);
    else
        conditionColors = lines(numel(labels));
    end

    info.TriggerLabels = triggerLabels;
    info.StimNames = stimNames;
    info.StimCodes = triggerCodes;
    info.Foreperiods = foreperiods;
    info.Labels = labels;
    info.ShortLabels = shortLabels;
    info.Codes = 1:numel(labels);
    info.TriggerCodes = conditionTriggerCodes;
    info.ConditionFPs = conditionFPs;
    info.Colors = conditionColors;
end

info.OutcomeNames = {'Correct', 'Premature', 'Late'};
info.OutcomeColors = [
    0.32 0.84 0.04
    0.92 0.14 0.12
    0.60 0.60 0.60];
end
