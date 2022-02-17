function expdata=piledataforvideo(T, trials)

expdata.vout=findvmtrials(T, trials);
expdata.tvm=[0:size(expdata.vout, 1)-1]/20000;

for i=1:length(trials)
    expdata.twhisk{i}=T.trials{T.trialNums==trials(i)}.whiskerTrial.time;
    expdata.whisk{i}=T.trials{T.trialNums==trials(i)}.whiskerTrial.thetaAtBase;
    expdata.whiskertrialNums(i)=T.trials{T.trialNums==trials(i)}.whiskerTrial.trialNum;
end;

expdata.cell=T.cellNum;
expdata.trialNums=trials;