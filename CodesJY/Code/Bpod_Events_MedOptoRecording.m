function events = Bpod_Events_MedOptoRecording(sd);
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording

Ntrials = sd.nTrials;
% 
%          WaitForPress: [0 0.1342]
%         WaitForMedTTL: [0.1342 4.1342]
%                  Late: [4.1342 5.1342]
%          BadPortEntry: [NaN NaN]
%     WaitForMedTTLStim: [NaN NaN]
%          InvalidEntry: [NaN NaN]
%             BriefExit: [NaN NaN]
%        WaitForPokedIn: [NaN NaN]
%        RewardDelivery: [NaN NaN]
%              Drinking: [NaN NaN]
%         DrinkingGrace: [NaN NaN]
%       WaitForPortExit: [NaN NaN]
 
    
all_events = fieldnames(sd.RawEvents.Trial{1}.States);

events.GoodRelease = [];    % time of a successful lever release
events.GoodPokeIn = [];      % time of port poke after a succesful lever release (reward delivered immediately)
events.Reward = [];             % two-row matrix, first row valve open, second row valve close
events.BadPokeIn = [];
events.BadPokeOut = [];
events.BadPokeInFirst = [];
events.BadPokeOutFirst = [];
events.BadPress = [];

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds
    
    if ~isnan(sd.RawEvents.Trial{k}.States.WaitForPokedIn(1))  % failed attempt
        events.GoodRelease = [events.GoodRelease t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(end)];
        events.GoodPokeIn = [events.GoodPokeIn t_trial+sd.RawEvents.Trial{k}.States.WaitForPokedIn(2)];
        events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery'];
    end
    
    if   isnan(sd.RawEvents.Trial{k}.States.WaitForPokedIn(1))
        press_time = t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(1);
        events.BadPress = [events.BadPress press_time];
    end;
    
    
    % poke following a bad press
    if k>1 && isnan(sd.RawEvents.Trial{k-1}.States.WaitForPokedIn(1))
        badpokes = sd.RawEvents.Trial{k}.States.BadPortEntry; % bad poke entries of current trial
        ind_prepress = find(badpokes(:, 1)< sd.RawEvents.Trial{k}.States.WaitForMedTTL(1));
        if ~isempty(ind_prepress)
            badpokes = badpokes(ind_prepress, :);
            events.BadPokeIn =      [events.BadPokeIn; t_trial+badpokes(:, 1)];
            events.BadPokeOut =    [events.BadPokeIn; t_trial+badpokes(:, 2)];
        end;
    end;
end;

% relative timing with respect to the first trial
events.GoodRelease   = events.GoodRelease-t0;
events.GoodPokeIn     = events.GoodPokeIn-t0;
events.Reward            = events.Reward-t0;
events.BadPokeIn        = events.BadPokeIn -t0;
events.BadPokeOut     = events.BadPokeOut - t0;
events.BadPress          = events.BadPress -t0;

figure;
plot(events.GoodRelease,1, 'go'); hold on
plot(events.GoodPokeIn, 2, 'b*')
plot(events.BadPokeIn, 3, 'r*')
plot(events.BadPress, 3, 'k^')
set(gca, 'ylim', [0 4])
xlabel('sec')


% extract the first poke after each bad release
bad_pokein=[];
bad_pokeout=[];
for i=1:length(events.BadPress)
    
    if i<length(events.BadPress)-1
        t_badpress = events.BadPress(i);
        t_badpressnext = events.BadPress(i+1);
        
        t_badpoke =         events.BadPokeIn(find(events.BadPokeIn>t_badpress, 1, 'first'));
        t_badpokeout =     events.BadPokeOut(find(events.BadPokeIn>t_badpress, 1, 'first'));
        
        if t_badpressnext-t_badpress > t_badpoke-t_badpress
            bad_pokein=[bad_pokein t_badpoke];
            bad_pokeout=[bad_pokeout t_badpokeout];
        end;
    end;
    
end;

events.BadPokeInFirst = bad_pokein;
events.BadPokeOutFirst = bad_pokeout;

plot(events.BadPokeInFirst, 3, 'ro')
     