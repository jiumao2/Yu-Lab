function events = Bpod_Events_MedOptoRecMix(sd);
% 2/20/2021
% extract events from bpod's SessionData structure
% Applies to MedOptoRecMix type of files
% e.g., Russo_MedOptoRecMix_20210819_210907.mat

% revised on 12/23/2021.
% Jianing Yu

Ntrials = sd.nTrials;
% 
%                  TrialStart: [0 0.5000]
%             WaitForApproach: [0.5000 1.2005]
%              WaitForTrigger: [1.2005 4.2005]
%                   Premature: [4.2005 4.3005]
%                  WaitForDLC: [NaN NaN]
%                     Masking: [NaN NaN]
%                WaitForPress: [NaN NaN]
%            WaitForPressStim: [NaN NaN]
%                BadPortEntry: [NaN NaN]
%          WaitForTriggerStim: [NaN NaN]
%               WaitForMedTTL: [NaN NaN]
%           WaitForMedTTLStim: [NaN NaN]
%                     Release: [NaN NaN]
%                 ReleaseStim: [NaN NaN]
%     CheckForAdditionalPulse: [NaN NaN]
%                        Late: [NaN NaN]
%                InvalidEntry: [NaN NaN]
%                   BriefExit: [NaN NaN]
%          WaitForPokedInHigh: [NaN NaN]
%              WaterDelayHigh: [NaN NaN]
%          RewardDeliveryHigh: [NaN NaN]
%           WaitForPokedInLow: [NaN NaN]
%               WaterDelayLow: [NaN NaN]
%           RewardDeliveryLow: [NaN NaN]
%                    Drinking: [NaN NaN]
%               DrinkingGrace: [NaN NaN]
%             WaitForPortExit: [NaN NaN]
 
%% List of event codes
PokeCode                =           'Port1In';
ApproachCode       =            findApproachCode(sd.RawEvents.Trial); % in the old version, this is BNC2Low
PressCode               =            'AnalogIn1_1';
TriggerCode            =            'AnalogIn1_2';
LaserCode               =            'WavePlayer1_1';

all_events = fieldnames(sd.RawEvents.Trial{1}.States);

events.Poke = [];
events.Approach = [];                           % time of approach
events.Press = [];                                    % time of Press
events.Trigger = [];                                 % time of trigger
events.OptoStimOn = [];                            % time of Optostim (it should match one of the above events) 
events.OptoStimOff = [];                            % time of Optostim (it should match one of the above events) 
 
events.GoodRelease = [];    % time of a successful lever release
events.GoodPokeIn = [];      % time of port poke after a succesful lever release (reward delivered immediately)
events.Reward = [];             % two-row matrix, first row valve open, second row valve close
events.RewardAmp = [];     % 1. low amount 2. high amout
events.BadPokeIn = [];
events.BadPokeOut = [];
events.BadPokeInFirst = [];
events.BadPokeOutFirst = [];
events.BadPress = [];
if isfield(sd, 'TrialSettings') && isfield(sd.TrialSettings, 'GUI')
    events.OptoStimDur = sd.TrialSettings(1).GUI.StimDur;
else
    events.OptoStimDur = sd.SettingsFile.GUI.StimDur;
end;

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds
    % check event code
    k_events = sd.RawEvents.Trial{k}.Events;
    if isfield(k_events, PokeCode)
        events.Poke = [events.Poke t_trial + eval(['k_events.' PokeCode])];
    end;
    if isfield(k_events, ApproachCode)
        events.Approach = [events.Approach t_trial + eval(['k_events.' ApproachCode])];
    end;
    if isfield(k_events, PressCode)
        events.Press = [events.Press t_trial + eval(['k_events.' PressCode])];
    end;
    if isfield(k_events, TriggerCode)
        events.Trigger = [events.Trigger t_trial + eval(['k_events.' TriggerCode])];
    end;

    if isfield(k_events, LaserCode)
        LaserTime = eval(['k_events.' LaserCode]);
        events.OptoStimOn = [events.OptoStimOn t_trial + LaserTime(1)];
        events.OptoStimOff = [events.OptoStimOff t_trial + LaserTime(2)];
    end;

    if ~isnan(sd.RawEvents.Trial{k}.States.CheckForAdditionalPulse(1))  % good trials
        events.GoodRelease = [events.GoodRelease t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(end)];
        if ~isnan(sd.RawEvents.Trial{k}.States.WaitForPokedInLow(1))
            events.GoodPokeIn = [events.GoodPokeIn t_trial+sd.RawEvents.Trial{k}.States.WaitForPokedInLow(2)];
            events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDeliveryLow'];
            events.RewardAmp =[events.RewardAmp 1];
        elseif ~isnan(sd.RawEvents.Trial{k}.States.WaitForPokedInHigh(1))
            events.GoodPokeIn = [events.GoodPokeIn t_trial+sd.RawEvents.Trial{k}.States.WaitForPokedInHigh(2)];
            events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDeliveryHigh'];
            events.RewardAmp =[events.RewardAmp 2];
        end;

    end

    if isnan(sd.RawEvents.Trial{k}.States.WaitForPokedInLow(1)) && isnan(sd.RawEvents.Trial{k}.States.WaitForPokedInHigh(1)) && ~isnan(sd.RawEvents.Trial{k}.States.WaitForTrigger(1))
        press_time = t_trial+sd.RawEvents.Trial{k}.States.WaitForTrigger(1);
        events.BadPress = [events.BadPress press_time];
    end;
    
    %Note that in MedOptoRecMix protocol, error release triggers exit of
    %the loop. bad poke here means poke without press.
    if k>1 && ~isnan(sd.RawEvents.Trial{k}.States.WaitForPress(1)) && ~ isnan(sd.RawEvents.Trial{k}.States.BadPortEntry(1))
        badpokes = sd.RawEvents.Trial{k}.States.BadPortEntry; % bad poke entries of current trial
        events.BadPokeIn                    =      [events.BadPokeIn; t_trial+badpokes(:, 1)];
        events.BadPokeOut                 =    [events.BadPokeOut; t_trial+badpokes(:, 2)];
        events.BadPokeInFirst             =      [events.BadPokeInFirst; t_trial+badpokes(1, 1)];
        events.BadPokeOutFirst          =    [events.BadPokeOutFirst; t_trial+badpokes(1, 2)];
    end;
    
end;

% relative timing with respect to the first trial
events.GoodRelease   = events.GoodRelease-t0;
events.GoodPokeIn     = events.GoodPokeIn-t0;
events.Reward            = events.Reward-t0;
events.BadPokeIn        = events.BadPokeIn -t0;
events.BadPokeOut     = events.BadPokeOut - t0; 

events.Poke                  =      events.Poke - t0;
events.Approach         =       events.Approach-t0;                           % time of approach
events.Press                 =      events.Press-t0;                                    % time of Press
events.Trigger               =       events.Trigger -t0;                                 % time of trigger
events.OptoStimOn     =       events.OptoStimOn-t0;                            % time of Optostim (it should match one of the above events) 
events.OptoStimOff    =       events.OptoStimOff-t0;                            % time of Optostim (it should match one of the above events) 


function approach_code = findApproachCode(trials)

t_bnchigh=[];
t_bnclow =[];

for i =1:length(trials)

    if isfield(trials{i}.Events, 'BNC2High') && isfield(trials{i}.Events, 'BNC2Low')
        t_bnchigh = [t_bnchigh trials{i}.Events.BNC2High];
        t_bnclow  = [t_bnclow trials{i}.Events.BNC2Low];
    end;
end;

if median(t_bnchigh)<median(t_bnclow) % new method, High level means approach
    approach_code = 'BNC2High';
else
    approach_code = 'BNC2Low';
end; 