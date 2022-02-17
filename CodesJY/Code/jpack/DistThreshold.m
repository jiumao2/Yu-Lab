function DT=DistThreshold(T, whiskingvmout, contacts, Vth, trials)

% find out the distance to threshold for nonwhisking, whisking, and touch
% periods
% whiskingvmout gives whisking vs nonwhisking periods
% contacts give contact information
% vth contains threshold information for all the trials
% trials are those trials that are included

% distance to threshold
% just vm collector, vm var can be collected from these distributions

nwdist=[];
wdist=[];
touchdist=[];

% time accumulaiton
taccnw=0;
taccw=0;
tacctouch=0;

% go through the trials

for i=1:length(trials)
    itrialnum=trials(i);
    [vm, ~, tvm]=findvmtrials(T, itrialnum);
    % removeAPs
    vm=sgolayfilt(removeAP(vm, 10000, 10, 5), 3, 21);
    %   vm=sgolayfilt(vm, 3, 41);
    
    
    %% first figure out the spike threshold
    ith=Vth.threshold{Vth.trials==itrialnum};
    if ~isempty(ith)
        vth=prctile(ith, 5);
    else
        k1=1;
        vthpre=[]; vthpost=[];
        while find(Vth.trials==itrialnum)-k1>0 && isempty(Vth.threshold{find(Vth.trials==itrialnum)-k1})
            k1=k1+1;
        end;
        
        if find(Vth.trials==itrialnum)-k1<=0
            vthpre=[];
        else
            vthpre=prctile(Vth.threshold{find(Vth.trials==itrialnum)-k1}, 25);
        end;
        
        k=1;
        while find(Vth.trials==itrialnum)+k<=length(Vth.threshold) && isempty(Vth.threshold{find(Vth.trials==itrialnum)+k})
            k=k+1;
        end;
        
        if find(Vth.trials==itrialnum)+k>length(Vth.threshold)
            vthpost=[];
        else
            vthpost=prctile(Vth.threshold{find(Vth.trials==itrialnum)+k}, 25);
        end;
        
        vth=mean([vthpre vthpost])
    end;
    % vth is the threshold that vm will be compared to. it is for this
    % trial only (although the data may come from a different trials)
    
    % let's put Vm to the collector
    
    if isnan(vth)
        vth=-40;
    end;
    
    %% nonwhisking periods
    inonwhiskingperiods=whiskingvmout.nonwhiskingstamp(whiskingvmout.nonwhiskingstamp(:, 1)==itrialnum, [2 3]);
    if ~isempty(inonwhiskingperiods)
        for j=1:size(inonwhiskingperiods)
            tnwbeg=inonwhiskingperiods(j, 1);
            tnwend=inonwhiskingperiods(j, 2);
            nwdist=[nwdist; findpeaks(vm(tvm>=tnwbeg & tvm<=tnwend), 'minpeakdistance', 10)-vth];
            taccnw=taccnw+tnwend-tnwbeg;
        end;
    end;
    
    %% whisking periods
    iwhiskingperiods=whiskingvmout.whiskingstamp(whiskingvmout.whiskingstamp(:, 1)==itrialnum, [2 3]);
    if ~isempty(iwhiskingperiods)
        for j=1:size(iwhiskingperiods)
            twbeg=iwhiskingperiods(j, 1);
            twend=iwhiskingperiods(j, 2);
            wdist=[wdist; findpeaks(vm(tvm>=twbeg & tvm<=twend), 'minpeakdistance', 10)-vth];
            taccw=taccw+twend-twbeg;
        end;
    end;
    
    
    %% touch periods
    itouchperiods=contacts{T.trialNums==itrialnum}.segmentInds;
    twhisk=T.trials{T.trialNums==itrialnum}.whiskerTrial.time;
    wid=T.trials{T.trialNums==itrialnum}.whiskerTrial.trajectoryIDs;
    touchbeg=[];
    touchend=[];
    for iw=1:length(wid)
        if ~isempty(itouchperiods{iw})
            twhisk_iw=twhisk{iw};
            touchbeg=[touchbeg twhisk_iw(itouchperiods{iw}(1, 1))];
            touchend=[touchend twhisk_iw(itouchperiods{iw}(end, 2))];
        end;
    end;
    touchbeg=min(touchbeg); touchend=max(touchend);
    if ~isempty(touchbeg)
        if touchend-touchbeg>0.02
            if touchend-touchbeg>1
                touchend=touchbeg+1;
            end;
            touchdist=[touchdist; findpeaks(vm(tvm>=touchbeg & tvm<touchend), 'minpeakdistance', 10)-vth];
            tacctouch=tacctouch+touchend-touchbeg;
        end;
    end;
end;

figure;

vbins=[-50:1:20];

nwdist_bins=histc(nwdist, vbins);
wdist_bins=histc(wdist, vbins);
touchdist_bins=histc(touchdist, vbins);

ha1=subplot(3, 1, 1)
set(gca, 'xlim', [-60 20], 'nextplot', 'add')
stairs(vbins, nwdist_bins,  'color', 'k');

ha2=subplot(3, 1, 2)
set(gca, 'xlim', [-60 20], 'nextplot', 'add')
stairs(vbins, wdist_bins,'color', 'g');

ha3=subplot(3, 1, 3)
set(gca, 'xlim', [-60 20], 'nextplot', 'add')
stairs(vbins, touchdist_bins,'color', 'r');

ylim_min=min([get(ha1, 'ylim'), get(ha2, 'ylim') get(ha3, 'ylim')]);
ylim_max=max([get(ha1, 'ylim'), get(ha2, 'ylim') get(ha3, 'ylim')]);

set(ha1, 'ylim', [ylim_min ylim_max]);
set(ha2, 'ylim', [ylim_min ylim_max]);
set(ha2, 'ylim', [ylim_min ylim_max]);

axis auto

figure;
set(gca, 'xlim', [-30 20], 'nextplot', 'add')
stairs(vbins, nwdist_bins, 'color', 'k');
stairs(vbins, wdist_bins,'color', 'g');
stairs(vbins, touchdist_bins,'color', 'r');
set(gca, 'ylim', [ylim_min ylim_max]);

legend('nw', 'w', 'touch')

DT.cell=[T.cellNum T.cellCode];
DT.nonwhisking=nwdist;
DT.whisking=wdist;
DT.touch=touchdist;
DT.vbins=vbins;
DT.nwdist_bins=nwdist_bins;
DT.wdist_bins=wdist_bins;
DT.touchdist_bins=touchdist_bins;
DT.taccnw=taccnw;
DT.taccw=taccw;
DT.tacctouch=tacctouch;

'var, nw, w, touch'
[var(nwdist) var(wdist) var(touchdist)]
'mean, nw, w, touch'
[mean(nwdist) mean(wdist) mean(touchdist)]



filename=['Dist_to_threshold' T.cellNum T.cellCode '.mat'];
cd (['C:\Work\Projects\BehavingVm\Data\Vmdata\' T.cellNum]);
save (filename, 'DT')


