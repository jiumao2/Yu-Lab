function PSTHOut = FlashSpikesWithPassive(r, ind, varargin)

takeAll = false;
if isempty(ind)
    ind = 1:numel(r.Units.SpikeTimes);
    takeAll = true;
elseif numel(ind) == 2
    ind = find(r.Units.SpikeNotes(:, 1) == ind(1) & r.Units.SpikeNotes(:, 2) == ind(2), 1, 'first');
    if isempty(ind)
        error('Flash:UnitNotFound', 'Could not find unit [%d %d] in SpikeNotes.', ind(1), ind(2));
    end
end

PressTimeDomain = [2500 2500];
ReleaseTimeDomain = [1500 1000];
RewardTimeDomain = [2000 2000];
TriggerTimeDomain = [1000 2000];
PassiveTimeDomain = [300 700];
ComputeRange = [];
ToSave = 'on';

for i = 1:2:numel(varargin)
    switch varargin{i}
        case 'PressTimeDomain'
            PressTimeDomain = varargin{i + 1};
        case 'ReleaseTimeDomain'
            ReleaseTimeDomain = varargin{i + 1};
        case 'RewardTimeDomain'
            RewardTimeDomain = varargin{i + 1};
        case 'TriggerTimeDomain'
            TriggerTimeDomain = varargin{i + 1};
        case 'PassiveTimeDomain'
            PassiveTimeDomain = varargin{i + 1};
        case 'ComputeRange'
            ComputeRange = varargin{i + 1} * 1000;
        case 'ToSave'
            ToSave = varargin{i + 1};
        otherwise
            error('Flash:UnknownArgument', 'Unknown argument %s.', varargin{i});
    end
end

if isfield(r, 'BehaviorClass') && numel(r.BehaviorClass) > 1
    r.BehaviorClass = r.BehaviorClass(1);
end

rb = r.Behavior;
info = Flash.conditionInfo(r);
labels = cellstr(string(rb.Labels(:)));
pressMarker = find(strcmp(labels, 'LeverPress'), 1, 'first');
releaseMarker = find(strcmp(labels, 'LeverRelease'), 1, 'first');
triggerMarker = find(strcmp(labels, 'Trigger'), 1, 'first');
valveMarker = find(strcmp(labels, 'ValveOnset'), 1, 'first');
pokesMarker = find(strcmp(labels, 'PokeOnset'), 1, 'first');

tPresses = rb.EventTimings(rb.EventMarkers == pressMarker);
tReleases = rb.EventTimings(rb.EventMarkers == releaseMarker);
tTriggersRecorded = rb.EventTimings(rb.EventMarkers == triggerMarker);
tRewardsAll = rb.EventTimings(rb.EventMarkers == valveMarker);
if isempty(pokesMarker)
    tPokes = tRewardsAll;
else
    tPokes = rb.EventTimings(rb.EventMarkers == pokesMarker);
end

outcomes = cellstr(string(rb.Outcome(:)));
triggerTypes = rb.TriggerTypes(:);
foreperiods = rb.Foreperiods(:);
nTrials = min([numel(tPresses), numel(tReleases), numel(outcomes), numel(triggerTypes), numel(foreperiods)]);
tPresses = tPresses(1:nTrials);
tReleases = tReleases(1:nTrials);
outcomes = outcomes(1:nTrials);
triggerTypes = triggerTypes(1:nTrials);
foreperiods = foreperiods(1:nTrials);
tTriggers = tPresses + foreperiods;

conditionIndex = nan(nTrials, 1);
for iCond = 1:numel(info.Labels)
    conditionIndex(triggerTypes == info.TriggerCodes(iCond) & foreperiods == info.ConditionFPs(iCond)) = iCond;
end
validConditions = ~isnan(conditionIndex);
validOutcomes = ismember(outcomes, info.OutcomeNames);
included = validConditions & validOutcomes;

if ~isempty(tTriggersRecorded)
    fprintf('Flash.FlashSpikes uses trial-derived trigger time = LeverPress + Foreperiod. Recorded Trigger markers found: %d.\n', ...
        numel(tTriggersRecorded));
end
fprintf('Flash.FlashSpikes included %d/%d trials. Excluded total=%d. Notes: NaN trigger=%d, other FP=%d, Dark outcome=%d.\n', ...
    sum(included), nTrials, nTrials - sum(included), sum(isnan(triggerTypes)), ...
    sum(ismember(triggerTypes, info.StimCodes(:)) & ~ismember(foreperiods, info.Foreperiods(:))), ...
    sum(strcmp(outcomes, 'Dark')));

if ~isempty(ComputeRange)
    inRange = tPresses >= ComputeRange(1) & tPresses <= ComputeRange(2);
    included = included & inRange;
end

correctMask = included & strcmp(outcomes, 'Correct');
prematureMask = included & strcmp(outcomes, 'Premature');
lateMask = included & strcmp(outcomes, 'Late');

tCorrectPresses = cell(1, numel(info.Labels));
tCorrectReleases = cell(1, numel(info.Labels));
tCorrectTriggers = cell(1, numel(info.Labels));
rtCorrect = cell(1, numel(info.Labels));
rewardTimes = cell(1, numel(info.Labels));
moveTimes = cell(1, numel(info.Labels));

for iCond = 1:numel(info.Labels)
    idx = find(correctMask & conditionIndex == iCond);
    rt = tReleases(idx) - tTriggers(idx);
    [rt, order] = sort(rt);
    idx = idx(order);
    tCorrectPresses{iCond} = tPresses(idx);
    tCorrectReleases{iCond} = tReleases(idx);
    tCorrectTriggers{iCond} = tTriggers(idx);
    rtCorrect{iCond} = rt;

    rewardsThis = nan(numel(idx), 1);
    moveThis = nan(numel(idx), 1);
    for j = 1:numel(idx)
        rewardIdx = find(tRewardsAll > tReleases(idx(j)) & tRewardsAll < tReleases(idx(j)) + 10000, 1, 'first');
        if ~isempty(rewardIdx)
            rewardsThis(j) = tRewardsAll(rewardIdx);
            moveThis(j) = rewardsThis(j) - tReleases(idx(j));
        end
    end
    validReward = ~isnan(rewardsThis);
    [moveTimes{iCond}, rewardOrder] = sort(moveThis(validReward));
    rewardList = rewardsThis(validReward);
    rewardTimes{iCond} = rewardList(rewardOrder);
end

[tPrematurePresses, prematureDurationPresses, prematureConds] = Flash.sortErrorEvents( ...
    tPresses, tReleases, conditionIndex, prematureMask);
tPrematureReleases = tReleases(prematureMask);
[prematureDurationReleases, orderPremRel] = sort(tPrematureReleases - tPresses(prematureMask));
tPrematureReleases = tPrematureReleases(orderPremRel);
prematureCondsRelease = conditionIndex(prematureMask);
prematureCondsRelease = prematureCondsRelease(orderPremRel);

[tLatePresses, lateDurationPresses, lateConds] = Flash.sortErrorEvents( ...
    tPresses, tReleases, conditionIndex, lateMask);
tLateReleases = tReleases(lateMask);
[lateDurationReleases, orderLateRel] = sort(tLateReleases - tPresses(lateMask));
tLateReleases = tLateReleases(orderLateRel);
lateCondsRelease = conditionIndex(lateMask);
lateCondsRelease = lateCondsRelease(orderLateRel);

tLateTriggers = tTriggers(lateMask);
lateTriggerRT = tReleases(lateMask) - tLateTriggers;
lateTriggerConds = conditionIndex(lateMask);
[lateTriggerRT, orderLateTrig] = sort(lateTriggerRT);
tLateTriggers = tLateTriggers(orderLateTrig);
lateTriggerConds = lateTriggerConds(orderLateTrig);

tNonrewardPokes = [];
moveTimeNonreward = [];
badReleaseTimes = [tPrematureReleases(:); tLateReleases(:)];
for i = 1:numel(badReleaseTimes)
    pokeIdx = find(tPokes > badReleaseTimes(i), 1, 'first');
    nextPressIdx = find(tPresses > badReleaseTimes(i), 1, 'first');
    if ~isempty(pokeIdx) && ~isempty(nextPressIdx) && tPokes(pokeIdx) < tPresses(nextPressIdx)
        tNonrewardPokes(end + 1, 1) = tPokes(pokeIdx); %#ok<AGROW>
        moveTimeNonreward(end + 1, 1) = tPokes(pokeIdx) - badReleaseTimes(i); %#ok<AGROW>
    end
end
[moveTimeNonreward, orderBadPoke] = sort(moveTimeNonreward);
tNonrewardPokes = tNonrewardPokes(orderBadPoke);

PSTHOut.ANM_Session = {r.Meta(1).Subject, datestr(r.Meta(1).DateTime, 'yyyymmdd')};
PSTHOut.TaskTypes.Codes = info.Codes;
PSTHOut.TaskTypes.Labels = info.Labels;
PSTHOut.TaskTypes.ShortLabels = info.ShortLabels;
PSTHOut.TaskTypes.TriggerCodes = info.TriggerCodes;
PSTHOut.TaskTypes.ConditionFPs = info.ConditionFPs;
PSTHOut.TaskTypes.ToneTimes = nan(1, numel(info.Labels));
PSTHOut.TaskTypes.FixedFP = info.ConditionFPs;
PSTHOut.TaskTypes.StimNames = info.StimNames;
PSTHOut.TaskTypes.Foreperiods = info.Foreperiods;
PSTHOut.TaskTypes.Colors = info.Colors;
PSTHOut.TaskTypes.Excluded.NaNTrigger = sum(isnan(triggerTypes));
PSTHOut.TaskTypes.Excluded.OtherFP = sum(ismember(triggerTypes, info.StimCodes(:)) & ~ismember(foreperiods, info.Foreperiods(:)));
PSTHOut.TaskTypes.Excluded.Dark = sum(strcmp(outcomes, 'Dark'));

PSTHOut.Presses.Labels = [info.Labels, {'Premature', 'Late', 'All'}];
PSTHOut.Presses.Time = [tCorrectPresses, {tPrematurePresses, tLatePresses, tPresses(included)}];
PSTHOut.Presses.FP = {info.Codes, prematureConds, lateConds};
PSTHOut.Presses.RT_Correct = rtCorrect;
PSTHOut.Presses.PressDur.Premature = prematureDurationPresses;
PSTHOut.Presses.PressDur.Late = lateDurationPresses;

PSTHOut.Releases.Labels = [info.Labels, {'Premature', 'Late'}];
PSTHOut.Releases.Time = [tCorrectReleases, {tPrematureReleases, tLateReleases}];
PSTHOut.Releases.FP = {info.Codes, prematureCondsRelease, lateCondsRelease};
PSTHOut.Releases.RT_Correct = rtCorrect;
PSTHOut.Releases.PressDur.Premature = prematureDurationReleases;
PSTHOut.Releases.PressDur.Late = lateDurationReleases;

PSTHOut.Pokes.Time = tPokes;
PSTHOut.Pokes.RewardPoke.Time = rewardTimes;
PSTHOut.Pokes.RewardPoke.Move_Time = moveTimes;
PSTHOut.Pokes.NonrewardPoke.Time = tNonrewardPokes;
PSTHOut.Pokes.NonrewardPoke.Move_Time = moveTimeNonreward;

PSTHOut.Triggers.Labels = {'TriggerTime_Flash2x2', 'TriggerTime_Late'};
PSTHOut.Triggers.Time = [tCorrectTriggers, {tLateTriggers}];
PSTHOut.Triggers.RT = [rtCorrect, {lateTriggerRT}];
PSTHOut.Triggers.FP = {info.Codes, lateTriggerConds};

PSTHOut.OptoEpochs.Begs = [];
PSTHOut.OptoEpochs.Ends = [];
PSTHOut.SpikeNotes = r.Units.SpikeNotes;

PassiveEvents.Labels = {};
PassiveEvents.Time = {};
PassiveEvents.PassiveTimeDomain = PassiveTimeDomain;

if ~isempty(tReleases)
    passiveStartTime = max(tReleases);
elseif ~isempty(tPresses)
    passiveStartTime = max(tPresses);
else
    passiveStartTime = -Inf;
end

passiveEventFields = {'ToneTimes', 'SmallToneTimes', 'FlashTimes', 'BothTimes'};
passiveEventLabels = {'Tone', 'SmallTone', 'Flash', 'Both'};
for iEvent = 1:numel(passiveEventFields)
    if ~isfield(rb, passiveEventFields{iEvent}) || isempty(rb.(passiveEventFields{iEvent}))
        continue
    end
    tPassiveEvents = rb.(passiveEventFields{iEvent})(:);
    tPassiveEvents = sort(tPassiveEvents(tPassiveEvents > passiveStartTime));
    if ~isempty(ComputeRange)
        tPassiveEvents(tPassiveEvents < ComputeRange(1) | tPassiveEvents > ComputeRange(2)) = [];
    end
    if ~isempty(tPassiveEvents)
        PassiveEvents.Labels{end + 1} = passiveEventLabels{iEvent};
        PassiveEvents.Time{end + 1} = tPassiveEvents;
    end
end
PSTHOut.PassiveEvents = PassiveEvents;

for iUnit = 1:numel(ind)
    ku = ind(iUnit);
    fprintf('Flash.FlashSpikesWithPassive computing unit %d (%d/%d).\n', ku, iUnit, numel(ind));
    PSTHOut.PSTH(iUnit) = Flash.ComputePlotPSTHWithPassive(r, PSTHOut, ku, ...
        'PressTimeDomain', PressTimeDomain, ...
        'ReleaseTimeDomain', ReleaseTimeDomain, ...
        'RewardTimeDomain', RewardTimeDomain, ...
        'TriggerTimeDomain', TriggerTimeDomain, ...
        'PassiveEvents', PassiveEvents, ...
        'PassiveTimeDomain', PassiveTimeDomain, ...
        'ToSave', ToSave);
    if numel(ind) > 1
        close all;
    end
end

if takeAll
    session = PSTHOut.ANM_Session{2};
    subject = PSTHOut.ANM_Session{1};

    r.PSTH.Events = struct();
    r.PSTH.Events.ANM_Session = PSTHOut.ANM_Session;
    r.PSTH.Events.TaskTypes = PSTHOut.TaskTypes;
    r.PSTH.Events.Presses = PSTHOut.Presses;
    r.PSTH.Events.Releases = PSTHOut.Releases;
    r.PSTH.Events.Pokes = PSTHOut.Pokes;
    r.PSTH.Events.Triggers = PSTHOut.Triggers;
    r.PSTH.Events.OptoEpochs = PSTHOut.OptoEpochs;
    r.PSTH.Events.SpikeNotes = PSTHOut.SpikeNotes;
    r.PSTH.Events.PassiveEvents = PSTHOut.PassiveEvents;
    r.PSTH.PSTHs = PSTHOut.PSTH;
    r.FlashPSTHWithPassive = r.PSTH;

    r_name = Spikes.r_name;
    if isempty(r_name)
        r_name = sprintf('RTarray_%s_%s.mat', subject, strrep(session, '_', ''));
    end
    save(r_name, 'r', '-v7.3');
    save(sprintf('PSTHOut_FlashWithPassive_%s_%s.mat', subject, session), 'PSTHOut', '-v7.3');
end
end
