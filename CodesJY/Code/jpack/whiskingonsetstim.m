function whiskmod=whiskingonsetstim(T, wvo, yrange, whiskrange,  tosave)
set(0,'DefaultAxesFontSize',10)

if nargin<5
    tosave=0;
    if nargin<4
        whiskrange=[0 40];
        if nargin<3
            yrange=[-70 -50; 0 100];
        end;
    end;
end;
vrange=yrange(1, :);
spkrange=yrange(2, :);
preonset=0.2;
postonset=0.5;
Fs=10000;
Fswhisk=1000;

nstrinums=wvo.stimtrialnums;
twhisk=wvo.twhisk;

whiskampall=wvo.whiskamp.stim;

whiskingstamp=wvo.whiskingstamp;
vm_whisk=[];
spk_whisk=[];
whiskamp_whisk=[];
touch_trials=wvo.trialnum_touch;
t_touch=wvo.t_touch;

tvm_whisk=[-preonset*Fs:postonset*Fs]'/Fs;
twhisk_whisk=[-preonset*Fswhisk:postonset*Fswhisk];

for i=1:length(nstrinums)
    tri=nstrinums(i); 
    [vm_tri, aom, tvm, fp_tri]=findvmtrials(T, tri);
    spk_tri=spikespy(vm_tri, Fs, wvo.spkth, 4);
    whiskamptri=whiskampall(:, i);
    if any(find(tri==touch_trials))
        t_touch_tri=t_touch(touch_trials==tri);
    else
        t_touch_tri=[];
    end;
    if any(find(tri==whiskingstamp(:, 1)))
        epochs=whiskingstamp(tri==whiskingstamp(:, 1), [2 3]);
        nepochs=size(epochs, 1);
        for k=1:nepochs
            if epochs(k, 1)>preonset && epochs(k, 1)+postonset<twhisk(end) && epochs(k, 2)-epochs(k, 1)>0.25
                ind=[round(epochs(k, 1)*Fs)-preonset*Fs:round(epochs(k, 1)*Fs)+postonset*Fs];
                [dum, onset_twhisk]=min(abs((twhisk-epochs(k, 1))));
                indwhisk=[onset_twhisk-Fswhisk*preonset:onset_twhisk+Fswhisk*postonset];
                whiskamp_indwhisk=whiskamptri(indwhisk);
                if median(whiskamp_indwhisk(1:Fswhisk*preonset))<=5
                    whiskamp_whisk=[whiskamp_whisk whiskamptri(indwhisk)];
                    vm_whisk=[vm_whisk vm_tri(ind)];
                    spk_whisk=[spk_whisk spk_tri(ind)];
                    if ~isempty(t_touch_tri)
                        if t_touch_tri>=epochs(k, 1) && t_touch_tri<=epochs(k, 2)
                            vm_whisk(tvm_whisk>=t_touch-epochs(k, 1))=nan;
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
dVm=mean(mean(vm_whisk(tvm_whisk>=0.05 & tvm_whisk<=0.2, :), 2))-mean(mean(vm_whisk(tvm_whisk<=-0.05, :), 2));

hf=figure;
set(hf, 'unit', 'centimeter', 'position', [2 2 6 12], 'paperpositionmode', 'auto');
ha1=axes;
set(ha1, 'nextplot', 'add', 'unit', 'normalized','position', [.2 .75 .7 .2],...
    'xlim',[-preonset postonset], 'fontname', 'arial', 'fontsize', 10, 'xticklabel', [], 'ylim', whiskrange)
nrand=randperm(size(whiskamp_whisk, 2));
nrand=nrand(1:3);
plot(twhisk_whisk, whiskamp_whisk(:, nrand));

plot(twhisk_whisk, mean(whiskamp_whisk, 2), 'color', 'k', 'linewidth', 2);
ylabel('Whisking amp. (deg)')

ha1b=axes;
set(ha1b, 'nextplot', 'add', 'unit', 'normalized','position', [.2 .45 .7 .2], 'xlim',[-preonset postonset] , 'fontname', 'arial', 'fontsize', 10, 'xticklabel', [])

plot(tvm_whisk, sgolayfilt(vm_whisk(:, nrand), 3, 41));

axis tight
set(ha1b, 'xlim', [-preonset postonset] );

y2=get(ha1b, 'ylim');
line([postonset-0.1 postonset-0.1], [y2(1)+5 y2(1)+10], 'color', 'k', 'linewidth', 1)
axis 'auto y'

ha2=axes;
set(ha2, 'unit','normalized', 'position', [.2 .1 .7 .25], 'nextplot', 'add', 'ylim', vrange, 'fontname', 'arial', 'fontsize', 10)

vm_nspikes=removeAP(vm_whisk, Fs, wvo.spkth, 4);

vmavg=mean(vm_nspikes, 2);
% vmci=bootci(1000, @mean, vm_nspikes');
plot(tvm_whisk, mean(vmavg, 2), 'k', 'linewidth', 1)
% plot(tvm_whisk, vmci', 'k:');
set(gca, 'xlim', [-preonset postonset])
xlabel('Time (s)')
ylabel('Vm (mV)')

ha3=axes;
set(ha3, 'unit','normalized', 'position', [.2 .1 .7 .15], 'nextplot', 'add','yaxislocation', 'right', 'xlim', [-preonset postonset], 'ylim', spkrange, 'color', 'none', 'fontname', 'arial', 'fontsize', 10)
bar(ts-preonset, histos, 'facecolor', 'c', 'edgecolor', 'c')
if spkrange(2)<10
line([postonset-0.1 postonset-0.1], [1 6], 'color', 'k', 'linewidth', 2)
else
    line([postonset-0.1 postonset-0.1], [5 15], 'color', 'k', 'linewidth', 2)
end

axis off

whiskmod.twhisk_whisk=twhisk_whisk;
whiskmod.whiskamp_whisk=whiskamp_whisk;
whiskmod.tvm_whisk=tvm_whisk;
whiskmod.Vm_whisk=vm_whisk;
whiskmod.dVm=dVm;
% whiskmod.vmci=vmci';
whiskmod.spk=[ts-preonset, histos];

if tosave
    
    save whiskampmodstim whiskmod
    print(hf, '-depsc', 'whiskampstim_vmdc')
    
end;
