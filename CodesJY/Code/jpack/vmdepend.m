function vmdepend(wv)

pole_onset=wv.poleonset;

stimonset=wv.surroundAOM.stimonset;
vmstim=wv.surroundAOM.vm_stim_surround;
nstim=length(stimonset);

nostimonset=wv.surroundAOM.nostimonset;
vmnostim=wv.surroundAOM.vm_nostim_surround;
nnostim=length(nostimonset);

aom=wv.surroundAOM.aom;
tvm_surround=wv.surroundAOM.tvm_stim_surround;

whiskamp_stim=wv.surroundAOM.whiskamp_stim_surround;
whiskamp_nostim=wv.surroundAOM.whiskamp_nostim_surround;
twhisk_surround=wv.surroundAOM.twhisk_surround;


figure

newrank=randperm(nstim);

for i=1:9
    ii=newrank(i);
    ha1=axes('nextplot', 'add','xtick', [],'ytick', [], 'unit', 'normalized', 'position', [.2 .1*i .7 .08], 'color', 'none', 'xlim', [-100 500], 'ylim', [-70 -20]); %#ok<LAXES>
    plot(tvm_surround, vmstim(:, ii));
    line([0 0], [-70 -20], 'color', 'r', 'linestyle', ':')
    ha2=axes('nextplot', 'add', 'xtick', [],'ytick',[],  'unit', 'normalized', 'position', [.2 .1*i .7 .08], 'color', 'none', 'xlim', [-100 500], 'ylim', [0 25]); %#ok<LAXES>
    plot(twhisk_surround, whiskamp_stim(:, ii), 'k');
    
    if i==1
        set(ha1, 'xtick', [-100:100:500], 'ytick', [-70:20:-10]);
    end;
    
    
end;

vmstim=removeAP(vmstim, 10000, 10, 4);
whiskamp_pre=mean(whiskamp_stim(twhisk_surround<0, :), 1);
Vmpre=mean(vmstim(tvm_surround<=0 & tvm_surround>=-50, :), 1);
dVm=mean(vmstim(tvm_surround>=75 & tvm_surround<=150, :), 1)-Vmpre;


figure; 

plot(whiskamp_pre, dVm, 'ko');
[r, p]=corrcoef(whiskamp_pre, dVm)

figure; 
subplot(2, 1, 1)
plot(tvm_surround, vmstim, 'color', [.6 .6 .6], 'linewidth', 1)
hold on
plot(tvm_surround, mean(vmstim, 2), 'color', 'c', 'linewidth', 2);
set(gca, 'xlim', [-100 500], 'ylim', [-75 0])
subplot(2, 1, 2)
plot(Vmpre, dVm, 'r^')
[r2, p2]=corrcoef(Vmpre, dVm)



