function info = conditionInfo(r)

rb = r.Behavior;
triggerLabels = cellstr(string(rb.TriggerTypeLabels(:)))';
flashCode = find(strcmpi(triggerLabels, 'Flash'), 1, 'first');
toneCode = find(strcmpi(triggerLabels, 'Tone'), 1, 'first');

if isempty(flashCode) || isempty(toneCode)
    error('Flash:MissingTriggerLabels', ...
        'Expected TriggerTypeLabels to contain Flash and Tone.');
end

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
info.OutcomeNames = {'Correct', 'Premature', 'Late'};
info.OutcomeColors = [
    0.32 0.84 0.04
    0.92 0.14 0.12
    0.60 0.60 0.60];
end
