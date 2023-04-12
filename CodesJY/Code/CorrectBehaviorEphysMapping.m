function r=CorrectBehaviorEphysMapping(r, kb)

% Jianing Yu 12/21/2022
% double check behavior data in r to make sure index is in order 

% get kornblum class or calculate it
if nargin<2
    kb =  KornblumClass;
end;

PressTimeR              =           r.Behavior.EventTimings(r.Behavior.EventMarkers == find(strcmp(r.Behavior.Labels, 'LeverPress')));
IndexPressR             =          [1:length(PressTimeR)];
PressTimeMED         =          kb.PressTime*1000;
IndexPressMED        =          kb.PressIndex;

% function Indout = findseqmatchrev(seqmom, seqson, man, toprint, toprintname, threshold)
IndMatched              =               findseqmatch(PressTimeMED, PressTimeR);
IndNotNan                =               find(~isnan(IndMatched));

if sum(isnan(IndMatched))>0
    disp('Found unmatched press event')
end

IndexPressR            =             IndexPressR(IndNotNan);
IndexPressR2MED  =             IndexPressMED(IndMatched(IndNotNan));

r.Behavior.ReMapped.PressIndex =         IndexPressR; % this marks the press index 
r.Behavior.ReMapped.Outcome    =         kb.Outcome(IndexPressR2MED);
r.Behavior.ReMapped.FP              =         kb.FP(IndexPressR2MED);
r.Behavior.ReMapped.CueIndex   =         kb.Cue(IndexPressR2MED);
r.Behavior.ReMapped.DateOfRemapping = date;
