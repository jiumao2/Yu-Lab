function events = BpodEventsLearning(sd)
% BpodEventsLearning Extract Bpod events for DoubleTone learning sessions.
%
% This function mirrors the fields used by UpdatePokeFromBpodEvents, but it
% is tolerant of DoubleTone learning late trials that never enter
% WaitForMedTTL.

Ntrials = sd.nTrials;

events.GoodRelease = [];
events.GoodPokeIn = [];
events.Reward = [];

events.AllPokeIns = [];
events.AllPokeOuts = [];
events.AllPress = [];

events.BadPokeIn = [];
events.BadPokeOut = [];
events.BadPokeInFirst = [];
events.BadPokeOutFirst = [];
events.BadPress = [];
events.TrialPress = nan(1, Ntrials);

t0 = sd.TrialStartTimestamp(1);

for k = 1:Ntrials
    t_trial = sd.TrialStartTimestamp(k);
    if iscell(sd.RawEvents.Trial)
        trial = sd.RawEvents.Trial{k};
    else
        trial = sd.RawEvents.Trial(k);
    end
    states = trial.States;
    trialEvents = trial.Events;

    if isfield(trialEvents, 'AnalogIn1_1') && ~isempty(trialEvents.AnalogIn1_1)
        pressTimes = t_trial + trialEvents.AnalogIn1_1;
        events.AllPress = [events.AllPress pressTimes]; %#ok<AGROW>
        events.TrialPress(k) = pressTimes(1);
    end

    if isfield(trialEvents, 'Port1In')
        events.AllPokeIns = [events.AllPokeIns t_trial + trialEvents.Port1In]; %#ok<AGROW>
    end

    if isfield(trialEvents, 'Port1Out')
        events.AllPokeOuts = [events.AllPokeOuts t_trial + trialEvents.Port1Out]; %#ok<AGROW>
    end

    isCorrect = isfield(states, 'RewardDelivery') && ~all(isnan(states.RewardDelivery(:)));
    if isCorrect
        if isfield(states, 'WaitForMedTTL') && ~all(isnan(states.WaitForMedTTL(:)))
            events.GoodRelease = [events.GoodRelease t_trial + states.WaitForMedTTL(end)]; %#ok<AGROW>
        end
        if isfield(states, 'WaitForPokedIn') && ~all(isnan(states.WaitForPokedIn(:)))
            events.GoodPokeIn = [events.GoodPokeIn t_trial + states.WaitForPokedIn(2)]; %#ok<AGROW>
        end
        events.Reward = [events.Reward t_trial + states.RewardDelivery']; %#ok<AGROW>
    elseif ~isnan(events.TrialPress(k))
        events.BadPress = [events.BadPress events.TrialPress(k)]; %#ok<AGROW>
    end

    if isfield(states, 'BadPortEntry') && ~all(isnan(states.BadPortEntry(:))) && ...
            isfield(states, 'WaitForFirstTone') && ~all(isnan(states.WaitForFirstTone(:)))
        badpokes = states.BadPortEntry;
        ind_prepress = find(badpokes(:, 1) < states.WaitForFirstTone(1));
        if ~isempty(ind_prepress)
            badpokes = badpokes(ind_prepress, :);
            events.BadPokeIn = [events.BadPokeIn; t_trial + badpokes(:, 1)]; %#ok<AGROW>
            events.BadPokeOut = [events.BadPokeOut; t_trial + badpokes(:, 2)]; %#ok<AGROW>
        end
    end
end

events.GoodRelease = events.GoodRelease - t0;
events.GoodPokeIn = events.GoodPokeIn - t0;
events.Reward = events.Reward - t0;
events.BadPokeIn = events.BadPokeIn - t0;
events.BadPokeOut = events.BadPokeOut - t0;
events.BadPress = events.BadPress - t0;
events.AllPokeIns = events.AllPokeIns - t0;
events.AllPokeOuts = events.AllPokeOuts - t0;
events.AllPress = events.AllPress - t0;
events.TrialPress = events.TrialPress - t0;

bad_pokein = [];
bad_pokeout = [];
for i = 1:length(events.BadPress)
    if i < length(events.BadPress)
        t_badpress = events.BadPress(i);
        t_badpressnext = events.BadPress(i+1);

        ind_badpoke = find(events.BadPokeIn > t_badpress, 1, 'first');
        if isempty(ind_badpoke)
            continue
        end
        t_badpoke = events.BadPokeIn(ind_badpoke);
        t_badpokeout = events.BadPokeOut(ind_badpoke);

        if t_badpressnext - t_badpress > t_badpoke - t_badpress
            bad_pokein = [bad_pokein t_badpoke]; %#ok<AGROW>
            bad_pokeout = [bad_pokeout t_badpokeout]; %#ok<AGROW>
        end
    end
end

events.BadPokeInFirst = bad_pokein;
events.BadPokeOutFirst = bad_pokeout;

end

