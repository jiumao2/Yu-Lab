function r = buildRLearning(KilosortOutput, varargin)
% buildRLearning Build RTarray r for DoubleTone learning Neuropixels sessions.
%
% Usage:
%   r = DoubleTone.buildRLearning(KilosortOutput, 'Subject', 'Lamine', ...
%       'Experimenter', 'HY');
%
% The MED file is the source of behavioral outcomes. Bpod only contributes
% poke timing updates and the minimal DoubleTone learning fields.

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
                error('DoubleTone:buildRLearning:UnknownArgument', ...
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
            error('DoubleTone:buildRLearning:MissingMED', ...
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
        BehaviorClass.Protocol = 'DoubleTone_01_Learning';
    end
catch
end
try
    BehaviorClass.Experimenter = Experimenter;
catch
end

try
    BehaviorClass.Plot();
    BehaviorClass.Save();
    BehaviorClass.Print();
catch ME
    warning('DoubleTone:buildRLearning:BehaviorClassOutputFailed', ...
        'BehaviorClass Plot/Save/Print failed: %s', ME.message);
end

if isempty(b.FPs) && ...
        ~strcmp(b.Metadata.ProtocolName, 'SRT_Step2_FR1_LeverPressBpodEphys') && ...
        ~strcmp(b.Metadata.ProtocolName, 'SRT_Step3_FR1_LeverReleaseBpodEphys')
    b = UpdateWaitB(b);
    BehaviorClass.FP = round(b.FPs);
    BehaviorClass.MixedFP = unique(BehaviorClass.FP);
end

aGoodName = ['RTarray_', b.Metadata.SubjectName, '_', b.Metadata.Date, '.mat'];

eventFile = load('./EventOut.mat', 'EventOut');
EventOut = eventFile.EventOut;

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
EventOut.Meta.Subject = Subject;
EventOut.Meta.Experimenter = Experimenter;

EventOutCombined = EventOut;
EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');

SessionData = [];
BpodEvents = [];
if isempty(BpodFile)
    bpodFiles = dir([Subject, '_DoubleTone_01_Learning*.mat']);
    if isempty(bpodFiles)
        bpodFiles = dir('*DoubleTone_01_Learning*.mat');
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
    warning('DoubleTone:buildRLearning:MissingBpod', ...
        'No DoubleTone learning Bpod file found. Learning fields will be NaN/false.');
end

EventOutCombined = AlignBehaviorClassToBR(EventOutCombined, BehaviorClass);

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

[extraToneVolumes, isTestTrials, postLearningPhaseTrials] = ...
    mapLearningFieldsToEphys(SessionData, BehaviorClass, EventOutCombined);
r.Behavior.ExtraToneVolumes = extraToneVolumes;
r.Behavior.IsTestTrials = isTestTrials;
r.Behavior.PostLearningPhaseTrials = postLearningPhaseTrials;
r.Behavior.TriggerTypeLabels = {'None', 'Tone500', 'Tone750', 'Tone1000'};
r.Behavior.TriggerTypes = ones(1, numel(r.Behavior.Outcome));
r.Behavior.TriggerTypes(extraToneVolumes > 0) = 3;

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
                r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0]; %#ok<AGROW>
            case 's'
                r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0]; %#ok<AGROW>
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

function [extraToneVolumes, isTestTrials, postLearningPhaseTrials] = ...
    mapLearningFieldsToEphys(SessionData, BehaviorClass, EventOutCombined)

nEphys = numel(EventOutCombined.OutcomeEphys);
extraToneVolumes = nan(1, nEphys);
isTestTrials = false(1, nEphys);
postLearningPhaseTrials = false(1, nEphys);

if isempty(SessionData)
    return
end

pressBehavior = BehaviorClass.PressTime*1000;
pressEphys = EventOutCombined.Onset{strcmp(EventOutCombined.EventsLabels, 'LeverPress')};
if isempty(pressBehavior) || isempty(pressEphys)
    return
end

indEphysToBehavior = findseqmatch(pressBehavior, pressEphys);

[trialPress, trialHasPress] = getBpodTrialPresses(SessionData);
if ~any(trialHasPress)
    return
end
trialPressMs = trialPress(trialHasPress)*1000;
trialNumbers = find(trialHasPress);
indBpodToBehavior = findseqmatch(pressBehavior, trialPressMs);

effectiveExtraToneVolumes = getEffectiveExtraToneVolumes(SessionData);
testTrials = getLogicalTrialField(SessionData, 'IsTestTrials');
postLearningTrials = getLogicalTrialField(SessionData, 'PostLearningPhaseTrials');

for iTrial = 1:numel(trialNumbers)
    bpodTrial = trialNumbers(iTrial);
    if iTrial > numel(indBpodToBehavior)
        continue
    end
    behaviorIndex = indBpodToBehavior(iTrial);
    ephysIndex = find(indEphysToBehavior == behaviorIndex, 1, 'first');
    if isempty(ephysIndex) || ephysIndex > nEphys
        continue
    end
    if bpodTrial <= numel(effectiveExtraToneVolumes)
        extraToneVolumes(ephysIndex) = effectiveExtraToneVolumes(bpodTrial);
    end
    if bpodTrial <= numel(testTrials)
        isTestTrials(ephysIndex) = testTrials(bpodTrial);
    end
    if bpodTrial <= numel(postLearningTrials)
        postLearningPhaseTrials(ephysIndex) = postLearningTrials(bpodTrial);
    end
end

end

function [trialPress, trialHasPress] = getBpodTrialPresses(SessionData)

nTrials = SessionData.nTrials;
trialPress = nan(1, nTrials);
trialHasPress = false(1, nTrials);
t0 = SessionData.TrialStartTimestamp(1);

for iTrial = 1:nTrials
    if iscell(SessionData.RawEvents.Trial)
        trialEvents = SessionData.RawEvents.Trial{iTrial}.Events;
    else
        trialEvents = SessionData.RawEvents.Trial(iTrial).Events;
    end
    if isfield(trialEvents, 'AnalogIn1_1') && ~isempty(trialEvents.AnalogIn1_1)
        trialPress(iTrial) = SessionData.TrialStartTimestamp(iTrial) + ...
            trialEvents.AnalogIn1_1(1) - t0;
        trialHasPress(iTrial) = true;
    end
end

end

function effectiveExtraToneVolumes = getEffectiveExtraToneVolumes(SessionData)

nTrials = SessionData.nTrials;
effectiveExtraToneVolumes = nan(1, nTrials);

if isfield(SessionData, 'ExtraToneVolumes')
    effectiveExtraToneVolumes(1:min(nTrials, numel(SessionData.ExtraToneVolumes))) = ...
        SessionData.ExtraToneVolumes(1:min(nTrials, numel(SessionData.ExtraToneVolumes)));
end

if isfield(SessionData, 'ExtraToneConditions')
    n = min(numel(effectiveExtraToneVolumes), numel(SessionData.ExtraToneConditions));
    extraCondition = logical(SessionData.ExtraToneConditions(1:n));
    effectiveExtraToneVolumes(1:n) = effectiveExtraToneVolumes(1:n) .* double(extraCondition);
    trialVolumes = effectiveExtraToneVolumes(1:n);
    trialVolumes(~extraCondition) = 0;
    effectiveExtraToneVolumes(1:n) = trialVolumes;
end

end

function values = getLogicalTrialField(SessionData, fieldName)

values = false(1, SessionData.nTrials);
if isfield(SessionData, fieldName)
    n = min(SessionData.nTrials, numel(SessionData.(fieldName)));
    values(1:n) = logical(SessionData.(fieldName)(1:n));
end

end

