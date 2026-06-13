function r = buildRStandard(KilosortOutput, varargin)
% buildRStandard Build RTarray r for DoubleTone standard Neuropixels sessions.
%
% Usage:
%   r = DoubleTone.buildRStandard(KilosortOutput, 'Subject', 'Lamine', ...
%       'Experimenter', 'HY');
%
% The MED file is the source of behavioral outcomes, foreperiods, and probes.
% Bpod contributes poke timing updates and the extra-tone on/off condition.

Subject = 'Lamine';
Experimenter = 'HY';
b = [];
BehaviorClass = [];
MEDFile = [];
BpodFile = [];
SaveR = true;

if nargin >= 2
    for i = 1:2:numel(varargin)
        switch varargin{i}
            case 'Subject'
                Subject = varargin{i+1};
            case 'Experimenter'
                Experimenter = varargin{i+1};
            case 'b'
                b = varargin{i+1};
            case 'BehaviorClass'
                BehaviorClass = varargin{i+1};
            case 'MEDFile'
                MEDFile = varargin{i+1};
            case 'BpodFile'
                BpodFile = varargin{i+1};
            case 'Save'
                SaveR = varargin{i+1};
            otherwise
                error('DoubleTone:buildRStandard:UnknownArgument', ...
                    'Unknown argument: %s', varargin{i});
        end
    end
end

obj = KilosortOutput;

% Check spks. This follows KilosortOutputClass.buildRNeuropixels.
units = {};
k = 1;
while k <= height(obj.SpikeTable)
    channel = obj.SpikeTable(k, :).ch{1};
    j = k + 1;
    while j <= height(obj.SpikeTable) && obj.SpikeTable(j, :).ch{1} == channel
        j = j + 1;
    end
    IndNew = size(units, 1) + 1;
    type = '';
    for i = k:j-1
        if strcmp(obj.SpikeTable(i, :).group{1}, 'good')
            type = [type, 's']; %#ok<AGROW>
        else
            type = [type, 'm']; %#ok<AGROW>
        end
    end
    units{IndNew, 1} = channel; %#ok<AGROW>
    units{IndNew, 2} = type; %#ok<AGROW>
    units{IndNew, 3} = []; %#ok<AGROW>
    k = j;
end

if isempty(b) || isempty(BehaviorClass)
    if isempty(MEDFile)
        medFiles = dir('*Subject*.txt');
        if isempty(medFiles)
            medFiles = dir('*.txt');
        end
        if isempty(medFiles)
            error('DoubleTone:buildRStandard:MissingMED', ...
                'Could not find a MED txt file in the current folder.');
        end
        MEDFile = medFiles(1).name;
    end

    [medPath, medName, medExt] = fileparts(MEDFile);
    if ~isempty(medPath)
        oldDir = pwd;
        cleanupObj = onCleanup(@() cd(oldDir));
        cd(medPath);
        MEDFile = [medName, medExt];
    end

    [b, BehaviorClass] = Behavior.MED.track_training_progress_advanced(MEDFile);
end

try
    if isempty(BehaviorClass.Protocol)
        BehaviorClass.Protocol = 'DoubleTone_02_Standard';
    end
catch
end
try
    BehaviorClass.Experimenter = Experimenter;
catch
end

if all(isnan(BehaviorClass.FP))
    fpPressTimes = [];
    fpValues = [];
    txt = fileread(MEDFile);
    startIdx = regexp(txt, '(?m)^W:\s*$', 'once');
    if ~isempty(startIdx)
        tailText = txt(startIdx:end);
        nextArrayIdx = regexp(tailText, '(?m)^[A-Z]:\s*$', 'start');
        if numel(nextArrayIdx) >= 2
            wText = tailText(1:nextArrayIdx(2)-1);
        else
            wText = tailText;
        end

        values = [];
        wLines = regexp(wText, '\r\n|\n|\r', 'split');
        for iLine = 1:numel(wLines)
            tokens = regexp(wLines{iLine}, '^\s*\d+:\s*(.*)$', 'tokens', 'once');
            if isempty(tokens)
                continue
            end
            lineValues = sscanf(tokens{1}, '%f');
            values = [values; lineValues(:)]; %#ok<AGROW>
        end

        values = values(values > 0);
        if ~isempty(values)
            fpCode = round((values - floor(values))*1000);
            isFPValue = fpCode == 150 | fpCode == 175;
            values = values(isFPValue);
            fpCode = fpCode(isFPValue);
            fpPressTimes = floor(values)/100;
            fpValues = fpCode*10;
        end
    end

    if ~isempty(fpPressTimes)
        fpOut = nan(size(BehaviorClass.PressTime));
        indMatchedFP = findseqmatch(BehaviorClass.PressTime, fpPressTimes);
        for iFP = 1:numel(fpValues)
            if indMatchedFP(iFP) > 0 && indMatchedFP(iFP) <= numel(fpOut)
                fpOut(indMatchedFP(iFP)) = fpValues(iFP);
            end
        end
        BehaviorClass.FP = fpOut;
        BehaviorClass.MixedFP = unique(fpOut(~isnan(fpOut)));
    end
else
    BehaviorClass.MixedFP = unique(BehaviorClass.FP(~isnan(BehaviorClass.FP)));
end
if any(~isnan(BehaviorClass.FP))
    b.FPs = BehaviorClass.FP;
end

if isempty(b.FPs) && ...
        ~strcmp(b.Metadata.ProtocolName, 'SRT_Step2_FR1_LeverPressBpodEphys') && ...
        ~strcmp(b.Metadata.ProtocolName, 'SRT_Step3_FR1_LeverReleaseBpodEphys')
    b = UpdateWaitB(b);
    BehaviorClass.FP = round(b.FPs);
    BehaviorClass.MixedFP = unique(BehaviorClass.FP);
end

try
    BehaviorClass.Plot();
    BehaviorClass.Save();
    BehaviorClass.Print();
catch ME
    warning('DoubleTone:buildRStandard:BehaviorClassOutputFailed', ...
        'BehaviorClass Plot/Save/Print failed: %s', ME.message);
end

aGoodName = ['RTarray_', b.Metadata.SubjectName, '_', b.Metadata.Date, '.mat'];

eventFile = load('./EventOut.mat', 'EventOut');
EventOut = eventFile.EventOut;
minLeverHoldMs = 10;
indLeverPressEventOut = find(strcmp(EventOut.EventsLabels, 'LeverPress'), 1, 'first');
if isempty(indLeverPressEventOut)
    error('DoubleTone:buildRStandard:MissingLeverPress', ...
        'LeverPress label was not found in EventOut.EventsLabels.');
end
leverPressOnset = EventOut.Onset{indLeverPressEventOut}(:);
leverPressOffset = EventOut.Offset{indLeverPressEventOut}(:);
assert(numel(leverPressOnset) == numel(leverPressOffset), ...
    sprintf('LeverPress onset/offset count mismatch in EventOut.mat: %d onsets, %d offsets.', ...
    numel(leverPressOnset), numel(leverPressOffset)));
leverHoldDurations = leverPressOffset - leverPressOnset;
indShortLeverPress = find(leverHoldDurations < minLeverHoldMs);
if ~isempty(indShortLeverPress)
    error('DoubleTone:buildRStandard:ShortLeverPress', ...
        ['EventOut.mat contains %d LeverPress events shorter than %.1f ms. ', ...
        'For K:/Lamine/20260520, run FixEventOutShortLeverPress_20260520.m before building r. ', ...
        'First short event index %d: press %.3f ms, release %.3f ms, hold %.6f ms.'], ...
        numel(indShortLeverPress), minLeverHoldMs, indShortLeverPress(1), ...
        leverPressOnset(indShortLeverPress(1)), leverPressOffset(indShortLeverPress(1)), ...
        leverHoldDurations(indShortLeverPress(1)));
end

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
EventOut.Meta.Subject = Subject;
EventOut.Meta.Experimenter = Experimenter;

EventOutCombined = EventOut;
EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');

SessionData = [];
BpodEvents = [];
if isempty(BpodFile)
    bpodFiles = dir([Subject, '_DoubleTone_02_Standard*.mat']);
    if isempty(bpodFiles)
        bpodFiles = dir('*DoubleTone_02_Standard*.mat');
    end
    if ~isempty(bpodFiles)
        BpodFile = bpodFiles(1).name;
    end
end

if ~isempty(BpodFile)
    load(BpodFile, 'SessionData');
    BpodEvents = DoubleTone.BpodEventsLearning(SessionData);
    EventOutCombined = UpdatePokeFromBpodEvents(EventOutCombined, BpodEvents);
else
    warning('DoubleTone:buildRStandard:MissingBpod', ...
        'No DoubleTone standard Bpod file found. Extra-tone fields will be false.');
end

EventOutCombined = AlignBehaviorClassToBR(EventOutCombined, BehaviorClass);

indLeverPressAssert = strcmp(EventOutCombined.EventsLabels, 'LeverPress');
pressTimeAssert = EventOutCombined.Onset{indLeverPressAssert}(:);
releaseTimeAssert = EventOutCombined.Offset{indLeverPressAssert}(:);
assert(numel(pressTimeAssert) == numel(releaseTimeAssert), ...
    sprintf('LeverPress onset/offset count mismatch: %d press events, %d release events.', ...
    numel(pressTimeAssert), numel(releaseTimeAssert)));
indBadRelease = find(releaseTimeAssert < pressTimeAssert, 1, 'first');
assert(isempty(indBadRelease), ...
    sprintf('LeverRelease precedes LeverPress at trial %d: press %.3f ms, release %.3f ms.', ...
    indBadRelease, pressTimeAssert(indBadRelease), releaseTimeAssert(indBadRelease)));

%% Construct r with aligned behavior and spikes.
r = [];
r.BehaviorClass = BehaviorClass;

r.Meta = EventOutCombined.Meta;
d = datetime(r.Meta.fileCreateTime);
r.Meta.DateTime = datestr(d);
r.Meta.DateTimeRaw = [d.Year, d.Month, 0, d.Day, d.Hour, d.Minute, d.Second, 0];

r.Behavior.Labels = { ...
    'FrameOn', ...
    'FrameOff', ...
    'LeverPress', ...
    'Trigger', ...
    'LeverRelease', ...
    'ValveOnset', ...
    'ValveOffset', ...
    'PokeOnset', ...
    'OptoStimOn', ...
    'OptoStimOff'};
r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);

r.Behavior.Outcome = EventOutCombined.OutcomeEphys;
r.Behavior.CorrectIndex = find(strcmp(r.Behavior.Outcome, 'Correct'));
r.Behavior.PrematureIndex = find(strcmp(r.Behavior.Outcome, 'Premature'));
r.Behavior.LateIndex = find(strcmp(r.Behavior.Outcome, 'Late'));
r.Behavior.DarkIndex = find(strcmp(r.Behavior.Outcome, 'Dark'));
r.Behavior.Foreperiods = EventOutCombined.FP_Ephys;
r.Behavior.CueIndex = EventOutCombined.CueEphys;

nEphysExtraTone = numel(EventOutCombined.OutcomeEphys);
extraTonePlayed = nan(1, nEphysExtraTone);
extraToneMapStats.NUnmatchedBpod = 0;
extraToneMapStats.NUnmatchedEphys = nEphysExtraTone;

if ~isempty(SessionData)
    pressBehaviorExtraTone = BehaviorClass.PressTime*1000;
    pressEphysExtraTone = EventOutCombined.Onset{strcmp(EventOutCombined.EventsLabels, 'LeverPress')};
    if ~isempty(pressBehaviorExtraTone) && ~isempty(pressEphysExtraTone)
        indEphysToBehavior = findseqmatch(pressBehaviorExtraTone, pressEphysExtraTone);
        extraToneMapStats.NUnmatchedEphys = sum(indEphysToBehavior <= 0 | isnan(indEphysToBehavior));

        nBpodTrials = SessionData.nTrials;
        trialPress = nan(1, nBpodTrials);
        trialHasPress = false(1, nBpodTrials);
        t0Bpod = SessionData.TrialStartTimestamp(1);
        for iBpodTrial = 1:nBpodTrials
            if iscell(SessionData.RawEvents.Trial)
                trialEvents = SessionData.RawEvents.Trial{iBpodTrial}.Events;
            else
                trialEvents = SessionData.RawEvents.Trial(iBpodTrial).Events;
            end
            if isfield(trialEvents, 'AnalogIn1_1') && ~isempty(trialEvents.AnalogIn1_1)
                trialPress(iBpodTrial) = SessionData.TrialStartTimestamp(iBpodTrial) + ...
                    trialEvents.AnalogIn1_1(1) - t0Bpod;
                trialHasPress(iBpodTrial) = true;
            end
        end

        if any(trialHasPress)
            trialPressMs = trialPress(trialHasPress)*1000;
            trialNumbers = find(trialHasPress);
            indBpodToBehavior = findseqmatch(pressBehaviorExtraTone, trialPressMs);
            matchedBpod = false(1, numel(trialNumbers));

            for iBpodPress = 1:numel(trialNumbers)
                bpodTrial = trialNumbers(iBpodPress);
                if iBpodPress > numel(indBpodToBehavior)
                    continue
                end
                behaviorIndex = indBpodToBehavior(iBpodPress);
                if behaviorIndex <= 0 || isnan(behaviorIndex)
                    continue
                end
                ephysIndex = find(indEphysToBehavior == behaviorIndex, 1, 'first');
                if isempty(ephysIndex) || ephysIndex > nEphysExtraTone
                    continue
                end
                if isfield(SessionData, 'ExtraTonePlayed') && bpodTrial <= numel(SessionData.ExtraTonePlayed)
                    extraTonePlayed(ephysIndex) = double(logical(SessionData.ExtraTonePlayed(bpodTrial)));
                    matchedBpod(iBpodPress) = true;
                end
            end
            extraToneMapStats.NUnmatchedBpod = sum(~matchedBpod);
            extraToneMapStats.NUnmatchedEphys = sum(isnan(extraTonePlayed));
        end
    end
end

r.Behavior.ExtraTonePlayed = extraTonePlayed;
r.Behavior.IsProbeTrials = strcmp(r.Behavior.Outcome, 'NAN');
r.Behavior.ProbeIndex = find(r.Behavior.IsProbeTrials);
r.Behavior.TriggerTypeLabels = {'None', 'Tone500', 'Tone750', 'Tone1000'};
r.Behavior.TriggerTypes = ones(1, numel(r.Behavior.Outcome));
r.Behavior.TriggerTypes(isnan(extraTonePlayed) & ~r.Behavior.IsProbeTrials) = NaN;
r.Behavior.TriggerTypes(extraTonePlayed == 1) = 3;

if extraToneMapStats.NUnmatchedBpod > 0 || extraToneMapStats.NUnmatchedEphys > 0
    warning('DoubleTone:buildRStandard:ExtraToneMappingIncomplete', ...
        ['Bpod extra-tone mapping incomplete: %d Bpod press trials and %d ephys press trials were unmatched. ', ...
        'Unmatched ephys trials are saved as ExtraTonePlayed=NaN and TriggerTypes=NaN.'], ...
        extraToneMapStats.NUnmatchedBpod, extraToneMapStats.NUnmatchedEphys);
end

pressTimesForCheck = EventOutCombined.Onset{strcmp(EventOutCombined.EventsLabels, 'LeverPress')};
releaseTimesForCheck = EventOutCombined.Offset{strcmp(EventOutCombined.EventsLabels, 'LeverPress')};
nTimingCheck = min([numel(pressTimesForCheck), numel(releaseTimesForCheck), ...
    numel(r.Behavior.Outcome), numel(r.Behavior.Foreperiods), numel(extraTonePlayed)]);
holdDurationForCheck = releaseTimesForCheck(1:nTimingCheck) - pressTimesForCheck(1:nTimingCheck);
rtForCheck = holdDurationForCheck(:)' - r.Behavior.Foreperiods(1:nTimingCheck);
outcomeForCheck = r.Behavior.Outcome(1:nTimingCheck);
extraToneForCheck = extraTonePlayed(1:nTimingCheck);
badCorrectRT = find(strcmp(outcomeForCheck, 'Correct') & rtForCheck < 0);
if ~isempty(badCorrectRT)
    warning('DoubleTone:buildRStandard:NegativeCorrectRT', ...
        'Found %d Correct trials with negative RT. First bad trial: %d, RT %.1f ms.', ...
        numel(badCorrectRT), badCorrectRT(1), rtForCheck(badCorrectRT(1)));
end
badTone750Timing = find(extraToneForCheck == 1 & ismember(outcomeForCheck, {'Correct', 'Late'}) & holdDurationForCheck(:)' < 750);
if ~isempty(badTone750Timing)
    warning('DoubleTone:buildRStandard:BadTone750Timing', ...
        'Found %d Tone750 Correct/Late trials with release before extra tone. First bad trial: %d, hold %.1f ms.', ...
        numel(badTone750Timing), badTone750Timing(1), holdDurationForCheck(badTone750Timing(1)));
end

r.Behavior.EventTimings = [];
r.Behavior.EventMarkers = [];

indframe = find(strcmp(EventOutCombined.EventsLabels, 'Frame'));
eventonset = EventOutCombined.Onset{indframe};
eventoffset = EventOutCombined.Offset{indframe};
eventmix = [eventonset; eventoffset];
indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2];
r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

indleverpress = find(strcmp(EventOutCombined.EventsLabels, 'LeverPress'));
eventonset = EventOutCombined.Onset{indleverpress};
eventoffset = EventOutCombined.Offset{indleverpress};
eventmix = [eventonset; eventoffset];
indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset), 1)*5];
r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

indtriggers = find(strcmp(EventOutCombined.EventsLabels, 'Trigger'));
eventonset = EventOutCombined.Onset{indtriggers};
triggeronset = EventOutCombined.Onset{indtriggers};
if size(eventonset, 1) < size(eventonset, 2)
    eventonset = eventonset';
end
indevent = ones(length(eventonset), 1)*4;
r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];

figure(11); clf
axes('nextplot', 'add', 'ylim', [0 10])
if ~isempty(triggeronset)
    plot(triggeronset, 4, 'go')
    text(triggeronset(1), 4.2, 'trigger')
end

indvalve = find(strcmp(EventOutCombined.EventsLabels, 'Valve'));
eventonset = EventOutCombined.Onset{indvalve};
eventoffset = EventOutCombined.Offset{indvalve};
eventmix = [eventonset; eventoffset];
indeventmix = [ones(length(eventonset), 1)*6; ones(length(eventoffset), 1)*7];
r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

if ~isempty(eventoffset)
    plot(eventoffset, 8, 'm^')
    text(eventoffset(1), 8.2, 'valve')
end

indpoke = strcmp(EventOutCombined.EventsLabels, 'Poke');
eventonset = EventOutCombined.Onset{indpoke};
eventmix = eventonset;
indeventmix = ones(length(eventonset), 1)*8;
r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

indopto = find(strcmp(EventOutCombined.EventsLabels, 'OptoStim'));
if ~isempty(indopto) && ~isempty(BpodEvents) && isfield(BpodEvents, 'OptoStimDur')
    eventonset = EventOutCombined.Onset{indopto};
    eventoffset = EventOutCombined.Offset{indopto} + BpodEvents.OptoStimDur;
    eventmix = [eventonset; eventoffset];
    indeventmix = [9*ones(length(eventonset), 1); 10*ones(length(eventoffset), 1)];
    r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
    r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
end

[r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);

%% Add spikes.
field_names = {'chanMap', 'chanMap0ind', 'xcoords', 'ycoords', 'kcoords'};
chanMap = obj.ChanMap;
for i = 1:length(field_names)
    if isfield(chanMap, field_names{i})
        chanMap.(field_names{i}) = chanMap.(field_names{i})(chanMap.connected);
    end
end
chanMap.connected = chanMap.connected(chanMap.connected);

r.Units.ChanMap = chanMap;
r.Units.Profile = units;
r.Units.Definition = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
r.Units.SpikeNotes = [];
for i = 1:size(units, 1)
    sorting_code = units{i, 2};
    for k = 1:length(sorting_code)
        switch sorting_code(k)
            case 'm'
                r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0];
            case 's'
                r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0];
        end
    end
end

for i = 1:size(r.Units.SpikeNotes, 1)
    r.Units.SpikeTimes(i) = struct('timings', [], 'wave', [], 'wave_mean', [], 'spk_id', []);
    r.Units.SpikeTimes(i).wave_mean = obj.SpikeTable(i, :).waveforms_mean{1};
    r.Units.SpikeTimes(i).timings = reshape(obj.SpikeTable(i, :).spike_times_r{1}, 1, []);
    r.Units.SpikeTimes(i).wave = obj.SpikeTable(i, :).waveforms{1};

    if any(strcmpi(obj.SpikeTable.Properties.VariableNames, 'spike_ID'))
        disp('spike_ID found! Escape reducing waveforms step!');
        r.Units.SpikeTimes(i).spk_id = obj.SpikeTable(i, :).spike_ID{1};
    else
        r.Units.SpikeTimes(i).spk_id = 1:length(r.Units.SpikeTimes(i).timings);
        if length(r.Units.SpikeTimes(i).timings) > 10000
            remove_percentage = 0.9;
        else
            remove_percentage = 1 - 1000/length(r.Units.SpikeTimes(i).timings);
        end

        if remove_percentage > 0
            ind_to_remove = randperm(length(r.Units.SpikeTimes(i).timings), ...
                round(length(r.Units.SpikeTimes(i).timings)*remove_percentage));
            r.Units.SpikeTimes(i).spk_id(ind_to_remove) = [];
            r.Units.SpikeTimes(i).wave(ind_to_remove, :) = [];
        end
    end
end

if SaveR
    tic
    save(aGoodName, 'r', '-v7.3');
    toc
end

clc
disp('~~~~~~~~~~~~~~~~~~')
disp('~~~~~R is ready~~~~~')
disp('~~~~~~~~~~~~~~~~~~')

end

