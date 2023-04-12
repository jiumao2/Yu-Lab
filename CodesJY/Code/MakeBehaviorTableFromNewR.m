function MakeBehaviorTableFromNewR(r)

% 10/23/2022 Jianing Yu
% 12/21/2022 revised. use r.Behavior.ReMapped to construct this table. 
% make a table from r, depicting critical events and aligning timing of
% these events with behavoral parameters, such as foreperiod, cue/uncue,
% etc. 

% We need the following data:
% 1. ANM, Session, Protocol
% 2. PressIndex, tPress, tRelease, tTrigger, Outcome, RT, FP, Cue
% time is in ephys domain so one can use this to make video clips 

Protocol = 'NaN';
rb = r.Behavior;

rbm = r.Behavior.ReMapped;
%          r.Behavior.ReMapped
%          PressIndex: [1 2 3 4 5 6 7 8 9 10 11 12 13 … ]
%          Outcome: {1×108 cell}
%          FP: [700 800 800 900 1000 1000 1000 … ]
%          CueIndex: [1 1 NaN 1 0 0 0 0 1 1 0 0 0 0 … ]
%          DateOfRemapping: '21-Dec-2022'

npress = length(rbm.FP); % number of presses (also number of rows)
% index of Cued and Uncued trials
Protocol = 'Kornblum';
CueIndex = rbm.CueIndex';
Session             =         repmat(extractBefore(r.Meta(1).DateTime, ' '), npress, 1);
Protocol             =         repmat(Protocol, npress, 1);
PressIndex        =         rbm.PressIndex';
FP                      =         rbm.FP';
ANM                   =        repmat(r.Meta(1).Subject, npress, 1);

ind_press           =         find(strcmp(rb.Labels, 'LeverPress'));
tPress                =         rb.EventTimings(rb.EventMarkers == ind_press);
tPress                =         tPress(PressIndex);

% release
ind_release        =         find(strcmp(rb.Labels, 'LeverRelease'));
tRelease            =         rb.EventTimings(rb.EventMarkers == ind_release);
tRelease            =         tRelease(PressIndex);

% time of all triggers
ind_triggers        =         find(strcmp(rb.Labels, 'Trigger'));
t_triggers            =         rb.EventTimings(rb.EventMarkers == ind_triggers);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

tTrigger            =          nan*ones(npress, 1);
Outcome          =          rbm.Outcome';

RT                    =          nan*ones(npress, 1);
tReward           =           nan*ones(npress, 1);
PressDuration  =          tRelease - tPress;

for i =1:npress
    switch Outcome{i}
        
        case 'Correct'
            RT(i)                =        tRelease(i) -  tPress(i) - FP(i);
            if ~isnan(CueIndex(i)) && CueIndex(i) && ~isempty(find(t_triggers>=tPress(i) & t_triggers<=tRelease(i)))
                tTrigger(i)        =        t_triggers(t_triggers>=tPress(i) & t_triggers<=tRelease(i));
            end
            if ~isempty(find(t_rewards > tRelease(i)))
                if i<npress
                    if t_rewards(find(t_rewards > tRelease(i), 1, 'first')) < tPress(i+1)
                        tReward(i) = t_rewards(find(t_rewards > tRelease(i), 1, 'first'));
                    end
                else
                    tReward(i) = t_rewards(find(t_rewards > tRelease(i), 1, 'first'));
                end;
            end;

        case 'Late'
            RT(i)                =        tRelease(i) -  tPress(i) - FP(i);
            if ~isnan(CueIndex(i)) && CueIndex(i)
                tTrigger(i)        =        t_triggers(t_triggers>=tPress(i) & t_triggers<=tRelease(i));
            end
    end;
end;

btable        =     table(ANM, Session, Protocol, PressIndex, tPress, tRelease, tTrigger, tReward, Outcome, PressDuration, RT, FP, CueIndex);
aGoodName       =     ['RArrayTable' '.csv'];
writetable(btable, aGoodName)