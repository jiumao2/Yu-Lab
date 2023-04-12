function MakeBehaviorTableFromRKornblum(r)

% 10/23/2022 Jianing Yu
% make a table from r, depicting critical events and aligning timing of
% these events with behavoral parameters, such as foreperiod, cue/uncue,
% etc. 

% We need the following data:
% 1. ANM, Session, Protocol
% 2. PressIndex, tPress, tRelease, tTrigger, Outcome, RT, FP, Cue
% time is in ephys domain so one can use this to make video clips 

Protocol = 'NaN';
rb = r.Behavior;
npress = length(r.Behavior.Foreperiods); % number of presses (also number of rows)
% index of Cued and Uncued trials

CueIndex = nan*ones(npress, 1);
if isfield(rb, 'CueIndex')
    Protocol = 'Kornblum';
    CueIndex(rb.CueIndex(:, 2) == 1) = 1; % cued trials
    CueIndex(rb.CueIndex(:, 2) == 0) = 0; % uncued trials
end;

Session             =         repmat(extractBefore(r.Meta(1).DateTime, ' '), npress, 1);
Protocol             =         repmat(Protocol, npress, 1);
PressIndex        =         [1:npress]';
FP                      =         r.Behavior.Foreperiods;
ANM                   =        repmat(r.Meta(1).Subject, npress, 1);
ind_press           =         find(strcmp(rb.Labels, 'LeverPress'));
tPress                =         rb.EventTimings(rb.EventMarkers == ind_press);

% release
ind_release        =         find(strcmp(rb.Labels, 'LeverRelease'));
tRelease            =         rb.EventTimings(rb.EventMarkers == ind_release);

% time of all triggers
ind_triggers        =         find(strcmp(rb.Labels, 'Trigger'));
t_triggers            =         rb.EventTimings(rb.EventMarkers == ind_triggers);

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

tTrigger            =          nan*ones(npress, 1);
Outcome          =          cell(npress, 1);
RT                    =          nan*ones(npress, 1);
PressDuration  =          nan*ones(npress, 1);
tReward           =           nan*ones(npress, 1);

PressDuration  =          tRelease - tPress;

for i =1:npress
    if any(r.Behavior.CorrectIndex == i)
        Outcome{i}      =       'Correct';
        RT(i)                =        tRelease(i) -  tPress(i) - FP(i);

        if ~isnan(CueIndex(i)) && CueIndex(i)
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

    elseif any(r.Behavior.LateIndex == i)
        Outcome{i}      =       'Late';
        RT(i)                =        tRelease(i) -  tPress(i) - FP(i);
        if ~isnan(CueIndex(i)) && CueIndex(i)
            tTrigger(i)        =        t_triggers(t_triggers>=tPress(i) & t_triggers<=tRelease(i));
        end
    elseif any(r.Behavior.PrematureIndex == i)
        Outcome{i}       =      'Premature';
    else
        Outcome{i}       =       'Dark';
    end;
end;

btable        =     table(ANM, Session, Protocol, PressIndex, tPress, tRelease, tTrigger, tReward, Outcome, PressDuration, RT, FP, CueIndex);
aGoodName       =     ['RArrayTable' '.csv'];
writetable(btable, aGoodName)