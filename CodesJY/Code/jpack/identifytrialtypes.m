function [trialtypes_unique, trialtypes_all, outcome]=identifytrialtypes(T)

for i=1:length(T.trials)
    alltrials{i}=T.trials{i}.behavTrial.trialTypeorg;
end;

trialtypes_unique=unique(alltrials);

for i=1:length(T.trials)
    thistrial=T.trials{i}.behavTrial.trialTypeorg;
    trialtypes_all(i)=find(ismember(trialtypes_unique, thistrial));
    outcome{i}=T.trials{i}.trialOutcome; 
end;