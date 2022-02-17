function durs=extractdurs(T, touch, contacts, ind)

touch_trials=touch.TrialNum(ind);
touch_onsets=touch.onset(ind);

for i=1:length(ind)
    ic=contacts{T.trialNums==touch_trials(i)};
    ialltouches=ic.segmentInds{1}(:, 1);
    
end;
    