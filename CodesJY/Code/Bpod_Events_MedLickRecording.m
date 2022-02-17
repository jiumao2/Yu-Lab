function events = Bpod_Events_MedLickRecording(sd);
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording

Ntrials = sd.nTrials;


%          WaitForMedTTL: [0 9.6813]
%     WaitForRewardEntry: [9.6813 10.9494]
%         RewardDelivery: [10.9494 11.1094]
%               Drinking: [20×2 double]
%          DrinkingGrace: [20×2 double]
%           InvalidEntry: [NaN NaN]
%              BriefExit: [NaN NaN]
%        WaitForPortExit: [NaN NaN]
% 
%     {'WaitForMedTTL'     }
%     {'InvalidEntry'      }
%     {'BriefExit'         }
%     {'WaitForRewardEntry'}
%     {'RewardDelivery'    }
%     {'Drinking'          }
%     {'DrinkingGrace'     }
%     {'WaitForPortExit'   }
    
all_events = fieldnames(sd.RawEvents.Trial{1}.States);

events.GoodRelease = [];    % time of a successful lever release
events.GoodPokeIn = [];      % time of port poke after a succesful lever release (reward delivered immediately)
events.PokeIn = [];
events.PokeOut = [];
events.Reward = [];             % two-row matrix, first row valve open, second row valve close

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds
    
    if ~isnan(sd.RawEvents.Trial{k}.States.WaitForRewardEntry(1))
        events.GoodRelease = [events.GoodRelease t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(end)];
        events.GoodPokeIn = [events.GoodPokeIn t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery(1)];
        events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery(:, 1)'];
        events.PokeIn = [events.PokeIn  t_trial+sd.RawEvents.Trial{k}.States.Drinking(:, 1)'];
        events.PokeOut = [events.PokeOut  t_trial+sd.RawEvents.Trial{k}.States.Drinking(:, 2)'];
    else
        events.PokeIn = [events.PokeIn  t_trial+sd.RawEvents.Trial{k}.States.Drinking(:, 1)'];
        events.PokeOut = [events.PokeOut  t_trial+sd.RawEvents.Trial{k}.States.Drinking(:, 2)'];
    end;
    
    
end;

% relative timing with respect to the first trial
events.GoodRelease   = events.GoodRelease-t0;
events.GoodPokeIn     = events.GoodPokeIn-t0;
events.GoodPokeOut  = events.GoodPokeIn+0.1;

events.Reward            = events.Reward-t0
events.PokeIn             = events.PokeIn-t0;
events.PokeOut          = events.PokeOut-t0;

events.PokeIn            = sort([events.PokeIn events.GoodPokeIn]);
events.PokeOut         = sort([events.PokeOut events.GoodPokeOut]);

figure;

plot(events.GoodRelease,1, 'go'); hold on
text(100, 1.2, 'Good release', 'color', 'g');
plot(events.GoodPokeIn, 2, 'ro');
text(100, 2.2, 'Good poke', 'color', 'r')
plot(events.Reward, 3, 'ko');
text(100, 3.2, 'Reward', 'color', 'k')
plot(events.PokeIn, 4, 'bx');
text(100, 4.2, 'Other pokes', 'color', 'b')
plot(events.PokeOut, 4, 'cx');
set(gca, 'ylim', [0 5])
xlabel('sec')