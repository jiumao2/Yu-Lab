function [time, trialIds, theta, curv, vmtime, vmtrialIds, vmall, AOMall] = getwhiskertime(T);

wid=T.trials{1}.whiskerTrial.trajectoryIDs;
time=cell(1, length(wid));
trialIds=cell(1, length(wid));
theta=cell(1, length(wid));
curv=cell(1, length(wid));
vmtime=[];
vmall=[];
AOMall=[];
vmtrialIds=[];

for i=1:length(T.trials)
    Tstart(i)=24*3600*T.trials{i}.spikesTrial.time;
    vmtime=[vmtime Tstart(i)+(0:length(T.trials{i}.spikesTrial.rawSignal)-1)/20000];
    vmall=[vmall T.trials{i}.spikesTrial.rawSignal'];
    AOMall=[AOMall T.trials{i}.spikesTrial.AOM'];
    vmtrialIds=[vmtrialIds T.trials{i}.trialNum*ones(1, length(T.trials{i}.spikesTrial.rawSignal'))];
    for iw=1:length(wid)
        time{iw}=[time{iw} Tstart(i)+T.trials{i}.whiskerTrial.time{iw}+0.001];
        trialIds{iw}=[trialIds{iw} T.trials{i}.trialNum*ones(1, length(Tstart(i)+T.trials{i}.whiskerTrial.time{iw}))];
        theta{iw}=[theta{iw} T.trials{i}.whiskerTrial.thetaAtBase{iw}];
        curv{iw}=[curv{iw} T.trials{i}.whiskerTrial.deltaKappa{iw}];
    end;
end;