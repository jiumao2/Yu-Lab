function badtrials=find_earlylick_trials(b)

% badtrials are the trials that start witha sustained of impulsive licking
% (n>=2 before pole onset)

badtrials=[];
for i=1:length(b.trials)
    beam=       b.trials{i}.beamBreakTimes;
    pole=       b.trials{i}.pinDescentOnsetTime;
    if ~isempty(beam)
        if length(find(beam<pole))>=2
            badtrials=[badtrials b.trialNums(i)];
        end;
    end;
end;