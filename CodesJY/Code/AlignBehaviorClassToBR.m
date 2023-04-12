function EventOut = AlignBehaviorClassToBR(EventOut, myclass)

% 3/3/2021 Jianing Yu
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press
% onset

% 4/2/2023 revised from AlignMED2BR but use behavior class instead 
% the goal of this function is to find the behavioral meaning of each blackrock's press 
% Lever presses and releases recorded in blackrock

% these are times for lever press and release recorded in blackrock
PressEphys        =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
ReleaseEphys     =     EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')};

% Lever presses, FP, releases, and correct index recorded in MED
PressBehavior             =     myclass.PressTime*1000;          % press time recorded in MED
ReleaseBehavior         =     myclass.ReleaseTime*1000;      % lever releases recorded in MED
TriggerBehavior           =     myclass.ToneTime*1000;            % trigger time recorded in MED. For uncued trials, tone occured after good release but was not recorded. 
PerformanceBehavior  =     myclass.Outcome;
PressIndex                   =     myclass.PressIndex;
FP                                =     myclass.FP;
if isprop(myclass, 'Cue')
    CueBehavior                 =    myclass.Cue;
else
    CueBehavior = ones(1, myclass.TrialNum);
end

% Start to map
IndMatched                                                       =             findseqmatch(PressBehavior, PressEphys);
PressEphysIndex2Behavior                              =            PressIndex(IndMatched); %

EventOut.OutcomeEphys                                  =           PerformanceBehavior(IndMatched);
EventOut.CueEphys                                          =           [1:length(PressEphys);  CueBehavior(IndMatched)]';
EventOut.FP_Ephys                                          =           FP(IndMatched)';

% if for some reasons, there is no trigger events in EventOut, we can fill
% it in
TriggerTimeMapped = [];
for i =1: length(PressEphys)
    iPressTimeEphys             =           PressEphys(i);
    iPressTimeBehavior         =           PressBehavior(PressEphysIndex2Behavior(i));
    if i<length(PressEphys)
        if TriggerBehavior(PressEphysIndex2Behavior(i))>0
            TriggerTimeMapped = [TriggerTimeMapped TriggerBehavior(PressEphysIndex2Behavior(i))-iPressTimeBehavior+iPressTimeEphys];
        end
    end
end

ReleaseTimeMapped = [];
for i =1: length(PressEphys)
    iPressTimeEphys             =           PressEphys(i);
    iPressTimeBehavior         =           PressBehavior(PressEphysIndex2Behavior(i));
    iReleaseTimeBehavior         =       ReleaseBehavior(PressEphysIndex2Behavior(i));
    if ~isnan(iPressTimeBehavior)
        ReleaseTimeMapped(i) =  iReleaseTimeBehavior-iPressTimeBehavior+iPressTimeEphys;
    end
end

if isempty(find(strcmp(EventOut.EventsLabels, 'Trigger'), 1))
    EventOut.EventsLabels{end+1}='Trigger';
    EventOut.Onset{end+1}=TriggerTimeMapped;
    return
end

TriggerEphys     =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')};

% find out the min distance between triggertimemapped and the ones recorded
% in blackrock
figure;
subplot(2, 1, 1)
plot(ReleaseEphys, 5, 'ko');
hold on
line([ReleaseTimeMapped' ReleaseTimeMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Release')

subplot(2, 1, 2)
plot(TriggerEphys, 5, 'ko');
hold on
line([TriggerTimeMapped' TriggerTimeMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Trigger')

IndTrigger2Keep = []; % this is to get rid of trigger events that are not really trigger events (e.g., correct release)
minD= ones(1, length(TriggerTimeMapped));
for k =1:length(TriggerTimeMapped)
    [~, ind_min]= min(abs(TriggerTimeMapped(k) - TriggerEphys));
    IndTrigger2Keep = [IndTrigger2Keep ind_min];
    minD(k) = TriggerTimeMapped(k) - TriggerEphys(ind_min);
    sprintf('Distance is %2.2f ms', minD(k))
end
TriggerEphys = TriggerEphys(IndTrigger2Keep);

minDRelease = ones(1, length(ReleaseTimeMapped));
for k =1:length(ReleaseTimeMapped)
    minDRelease(k) = min(abs(ReleaseTimeMapped(k) - ReleaseEphys));
    sprintf('Distance is %2.2f ms', minDRelease(k))
end

figure; 
subplot(2, 1, 1)
histogram(minD)
xlabel('Time difference between Blackrock trigger and MED trigger');
ylabel('Count')
subplot(2, 1, 2)
histogram(minDRelease)
xlabel('Time difference between Blackrock release and MED release');
ylabel('Count')

TriggerDur = 250; % 250 ms trigger events
EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys+TriggerDur;