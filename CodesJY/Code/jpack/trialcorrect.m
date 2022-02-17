function [varout, ntrials]=trialcorrect(T, trials, cellname)

if nargin==3
    cd(['C:\Work\Projects\BehavingVm\Data\Vmdata\' cellname]);
    
    c=dir(['trial_array_*' cellname '*.mat']);
    
    if ~isempty(c) &&length(c)==1
        load(c.name);
    else
        error('double check')
    end
end;


if isempty(trials)
    c=dir(['C:\Work\Projects\BehavingVm\Data\Groupdata\Rawdata\Rawdata\piledata' T.cellNum '_form1.mat']);
    if ~isempty(c)
        load(['C:\Work\Projects\BehavingVm\Data\Groupdata\Rawdata\Rawdata\' c.name]);
        trials=iwdata.trialnums;
    else
        trials=setdiff(T.trialNums, T.stimtrialNums);
    end
    
end;

alltrials=intersect(trials, setdiff(T.trialNums, T.stimtrialNums));
alltrialscorrect=intersect(trials, setdiff([T.hitTrialNums T.correctRejectionTrialNums], T.stimtrialNums));

hit=intersect(trials, setdiff([T.hitTrialNums], T.stimtrialNums));
allgo=intersect(trials, setdiff([T.hitTrialNums T.missTrialNums], T.stimtrialNums));

hirtrate=length(hit)/length(allgo)

varout=length(alltrialscorrect)/length(alltrials)
ntrials=length(alltrials)
depth=T.depth