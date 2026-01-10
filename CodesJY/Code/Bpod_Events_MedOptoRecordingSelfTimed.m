function events = Bpod_Events_MedOptoRecordingSelfTimed(sd)
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording
% 10/4/2022 add AllPokeIns and AllPokesOuts. 
% 5/9/2023 for Self-Timed version
% significant modification on 5/9/2023. only keep pokes.

Ntrials = sd.nTrials;
% 
%                    WaitForPress: [0 1.0000e-04]
%                         Masking: [1.0000e-04 0.0011]
%             WaitForMedTTL_Rapid: [0.0011 1.7011]
%            WaitForMedTTL_Medium: [1.7011 2.1011]
%              WaitForMedTTL_Slow: [2.1011 3.6011]
%                            Late: [3.6011 4.6011]
%                    BadPortEntry: [NaN NaN]
%               WaitForMedTTLStim: [NaN NaN]
%                    InvalidEntry: [NaN NaN]
%                       BriefExit: [NaN NaN]
%      WaitForPokedIn_RapidReward: [NaN NaN]
%      RewardDelivery_RapidReward: [NaN NaN]
%     WaitForPokedIn_MediumReward: [NaN NaN]
%     RewardDelivery_MediumReward: [NaN NaN]
%       WaitForPokedIn_SlowReward: [NaN NaN]
%       RewardDelivery_SlowReward: [NaN NaN]
%                        Drinking: [NaN NaN]
%                   DrinkingGrace: [NaN NaN]
%                 WaitForPortExit: [NaN NaN]
     
events.Reward = [];             % two-row matrix, first row valve open, second row valve close
events.AllPokeIns = [];
events.AllPokeOuts = [];
events.AllPress = [];

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds
    if isfield(sd.RawEvents.Trial{k}.Events, 'AnalogIn1_1')
        events.AllPress = [events.AllPress t_trial + sd.RawEvents.Trial{k}.Events.AnalogIn1_1];
    end

    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1In')
        events.AllPokeIns = [events.AllPokeIns t_trial+sd.RawEvents.Trial{k}.Events.Port1In];
    end
    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1Out')
        events.AllPokeOuts = [events.AllPokeOuts t_trial+sd.RawEvents.Trial{k}.Events.Port1Out];
    end

    if isfield(sd.RawEvents.Trial{k}.States, 'RewardDelivery_RapidReward')
        if ~isnan(sd.RawEvents.Trial{k}.States.RewardDelivery_RapidReward(1))
            events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery_RapidReward'];
        elseif ~isnan(sd.RawEvents.Trial{k}.States.RewardDelivery_MediumReward(1))
            events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery_MediumReward'];
        elseif ~isnan(sd.RawEvents.Trial{k}.States.RewardDelivery_SlowReward(1))
            events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery_SlowReward'];
        end
    else
        events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery'];
    end

end;

% relative timing with respect to the first trial
events.AllPokeIns                    = events.AllPokeIns - t0;
events.AllPokeOuts                 = events.AllPokeOuts - t0;
events.AllPress                        = events.AllPress - t0;
events.Reward                        = events.Reward - t0;