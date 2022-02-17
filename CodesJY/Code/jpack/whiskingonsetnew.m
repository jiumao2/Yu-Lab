function whiskmod=whiskingonsetnew(T, wvo, yrange, whiskrange, tosave, type, whiskampth)
set(0,'DefaultAxesFontSize',10)

if nargin<7
    whiskampth=5;
if nargin<6
    type='normal';
    if nargin<5
        tosave=0;
        if nargin<4
            whiskrange=[0 40];
            if nargin<3
                yrange=[0 0.1; 0 100];
            end;
        end;
    end;
end;
end;

vrange=yrange(1, :);
spkrange=yrange(2, :);
preonset=0.2;
postonset=0.5;
Fs=10000;
Fswhisk=1000;

switch type
    case 'normal'
    nstrinums=wvo.nostimtrialnums;
    whiskampall=wvo.whiskamp.nostim;
    case 'stim'
    nstrinums=wvo.stimtrialnums;
    whiskampall=wvo.whiskamp.stim;
    otherwise
        error('check type');
end;

twhisk=wvo.twhisk;
whiskingstamp=wvo.whiskingstamp;
vm_whisk=[];
spk_whisk=[];
lfp_whisk=[];
whiskamp_whisk=[];
touch_trials=wvo.trialnum_touch;
t_touch=wvo.t_touch;

tvm_whisk=[-preonset*Fs:postonset*Fs]'/Fs;
twhisk_whisk=[-preonset*Fswhisk:postonset*Fswhisk];

for i=1:length(nstrinums)
    
    t_touch=6; % if t_touch=6, then there is no touch for this trial
    tri=nstrinums(i); 
    
    if any(find(wvo.trialnum_touch==tri));
        t_touch=wvo.t_touch(wvo.trialnum_touch==tri);
    end;
    
    [vm_tri, aom, tvm, fp_tri]=findvmtrials(T, tri);
    tvm=tvm-0.01;
    
    if length(fp_tri)>41
    fp_tri=sgolayfilt(fp_tri, 3, 41);
    end;
    spk_tri=spikespy(vm_tri, Fs, wvo.spkth, 4);
    whiskamptri=whiskampall(:, i);
    if any(find(tri==touch_trials))
        t_touch_tri=wvo.t_touch(touch_trials==tri);
    else
        t_touch_tri=[];
    end;
    if any(find(tri==whiskingstamp(:, 1)))
        epochs=whiskingstamp(tri==whiskingstamp(:, 1), [2 3]);
        nepochs=size(epochs, 1);
        for k=1:nepochs
            if epochs(k, 1)>preonset && epochs(k, 1)+postonset<twhisk(end) && epochs(k, 2)-epochs(k, 1)>0.05
                ind=[round(epochs(k, 1)*Fs)-preonset*Fs:round(epochs(k, 1)*Fs)+postonset*Fs];
                [dum, onset_twhisk]=min(abs((twhisk-epochs(k, 1))));
                indwhisk=[onset_twhisk-Fswhisk*preonset:onset_twhisk+Fswhisk*postonset];
                if ~any(find(indwhisk<=0))
                    whiskamp_indwhisk=whiskamptri(indwhisk);
                    if median(whiskamp_indwhisk(1:Fswhisk*preonset))<=3 && median(whiskamp_indwhisk(Fswhisk*preonset+100:Fswhisk*preonset+Fswhisk*postonset))-median(whiskamp_indwhisk(1:Fswhisk*preonset))>whiskampth

                        whiskamp_whisk=[whiskamp_whisk whiskamptri(indwhisk)];
                        vm_whisk=[vm_whisk vm_tri(ind)];
                        spk_whisk=[spk_whisk spk_tri(ind)];
                        lfp_whisk=[lfp_whisk fp_tri(ind)];
                        
                        if t_touch<epochs(k, 1)+postonset
                            ind1=round(Fs*(postonset+epochs(k, 1)-t_touch));
                            ind2=round(1000*(postonset+epochs(k, 1)-t_touch));
                            
                            if ind1>=0.3*Fs
                                
                                whiskamp_whisk(:, end)=[];
                                vm_whisk(:, end)=[];
                                spk_whisk(:, end)=[];
                                lfp_whisk(:, end)=[];
                                
                            else
                                
                                whiskamp_whisk(end-ind2:end, end)=NaN;
                                vm_whisk(end-ind1:end, end)=NaN;
                                spk_whisk(end-ind1:end, end)=NaN;
                                lfp_whisk(end-ind1:end, end)=NaN;
                            
                            end;
                        end;
                        
                    end;
                end;
            end;
        end;
    end;
end;

twhisk_whisk=twhisk_whisk/1000;
% tvm_whisk=tvm_whisk/10000;

[ histos, ts ] = spikehisto(spk_whisk,Fs,round((preonset+postonset)/0.01));

% modulation:
hf=figure;
set(hf, 'unit', 'centimeter', 'position', [2 2 8 12], 'paperpositionmode', 'auto', 'color', [1 1 1]);
ha1=axes;
set(ha1, 'fontsize', 8, 'nextplot', 'add', 'unit', 'normalized','position', [.25 .75 .65 .2],...
    'xlim',[-preonset postonset], 'fontname', 'arial', 'xticklabel', [], 'ylim', whiskrange)

title(type)

nrand=randperm(size(whiskamp_whisk, 2));
if length(nrand)>10
nrand=nrand(1:10);
end;

plot(twhisk_whisk, whiskamp_whisk(:, nrand));
plot(twhisk_whisk, nanmean(whiskamp_whisk, 2), 'color', 'k', 'linewidth', 2);
ylabel('Whisking amp. (deg)')
title(T.cellNum, 'fontsize', 8)

axis 'auto y'

ha1b=axes;
set(ha1b, 'fontsize', 8, 'nextplot', 'add', 'unit', 'normalized','position', [.25 .53 .6 .2], 'xlim',[-preonset postonset] , 'fontname', 'arial',  'xticklabel', [])

plot(tvm_whisk*1000, sgolayfilt(vm_whisk(:, nrand), 3, 41), 'linewidth', 0.5);
axis tight
set(ha1b, 'xlim', [-preonset postonset]*1000 );

y2=get(ha1b, 'ylim');
line([postonset*1000-50 postonset*1000-50], [y2(1)+5 y2(1)+10], 'color', 'k', 'linewidth', 1)
axis off

ha2=axes;
set(ha2, 'fontsize', 8, 'unit','normalized', 'position', [.25 .3 .65 .2], 'nextplot', 'add', 'ylim', vrange, 'fontname', 'arial')

    Vm_all=vm_whisk;
    for j=1:size(Vm_all, 2)
    
        Vmj=Vm_all(:, j);
        Vmja=Vmj(~isnan(Vmj));
        Vmjb=Vmj(isnan(Vmj));
        
        Vmja=sgolayfilt(removeAP(Vmja, 10000, 5, 7), 3, 31);
        
        Vmj=[Vmja ;Vmjb];
        
        Vm_all(:, j)=Vmj;
        
    end; 
    vm_nspikes=Vm_all;
    
    dVm=nanmean(nanmean(vm_nspikes(tvm_whisk>=0.15, :), 2))-nanmean(nanmean(vm_nspikes(tvm_whisk<=0.05, :), 2));
    vmavg=nanmean(vm_nspikes, 2);
    vmavg(1)=vmavg(2);
% vmci=bootci(1000, @nanmean, vm_nspikes');

switch type
    case 'normal'
        plot(tvm_whisk*1000, vmavg, 'k', 'linewidth', 1)
        % plot(tvm_whisk, vmci', 'k:');
    case 'stim'
        plot(tvm_whisk*1000, vmavg, 'b', 'linewidth', 1)
end;

set(gca, 'xlim', [-preonset postonset]*1000)

axis 'auto y'

ylabel('Vm (mV)')

ha3=axes;
set(ha3, 'fontsize', 8, 'unit','normalized', 'position', [.25 .1 .65 .1], 'nextplot', 'add','yaxislocation', 'left', 'xlim', 1000*[-preonset postonset], 'ylim', spkrange, 'fontname', 'arial')

switch type
    case 'normal'
        bar(1000*(ts-preonset), histos, 'facecolor', 'k', 'edgecolor', 'k')
    case 'stim'
        bar(1000*(ts-preonset), histos, 'facecolor', 'b', 'edgecolor', 'b')
end;

spkrate_pre=mean(histos(find(ts-preonset<=0.05)));
spkrate_post=mean(histos(find(ts-preonset>=0.15)));

dspk=(spkrate_post-spkrate_pre);
dspkratio=spkrate_post/spkrate_pre;

xlabel('Time (ms)')
ylabel('Spk/s')

figure;
plot(tvm_whisk*1000, nanmean(lfp_whisk, 2), 'k', 'linewidth', 1)
 
whiskmod.twhisk_whisk=twhisk_whisk;
whiskmod.whiskamp_whisk=whiskamp_whisk;
whiskmod.tvm_whisk=tvm_whisk;
whiskmod.Vm_whisk=vm_whisk;
whiskmod.dVm=dVm;
% whiskmod.vmci=vmci';
whiskmod.tspk=ts-preonset;
whiskmod.spk= histos;
whiskmod.dspk=dspk;
whiskmod.dspkratio=dspkratio;

if tosave
    switch type
        case 'normal'
            save whiskampmod whiskmod
            export_fig(hf,  'whiskamp_vmdc', '-tiff')
        case 'stim'
            save whiskampmodstim whiskmod
            export_fig(hf,  'whiskamp_vmdcstim', '-tiff')
        otherwise
            return;
    end;
end;
