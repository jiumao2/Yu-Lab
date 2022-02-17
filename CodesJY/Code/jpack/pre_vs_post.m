function pre_vs_post(wv, onefreq, tosave)

if nargin<2
    tosave=0;
end;

yrange=[-80 0];
whiskrange=[0 45];
pole_onset=wv.poleonset;

stimonset=wv.surroundAOM.stimonset;
vmstim=wv.surroundAOM.vm_stim_surround;
nstim=length(stimonset);
stimnums=wv.stimtrialnums;

nostimonset=wv.surroundAOM.nostimonset;
vmnostim=wv.surroundAOM.vm_nostim_surround;
nnostim=length(nostimonset);

aom=wv.surroundAOM.aom;

aomon=spikespy(aom, 10000, 1, 10);

for i=1:size(aomon, 2)
    aomfreq(i)=10000/median(diff(find(aomon(:, i))));
end;

ind=find(aomfreq==onefreq);

vmstim=vmstim(:, ind);
stimnums=stimnums(ind);
stimonset=stimonset(ind);
aom=aom(:, ind);
aomon=aomon(:, ind);
nstim=length(ind);
aomfreq=aomfreq(ind);
tvm_surround=wv.surroundAOM.tvm_stim_surround;

whiskamp_stim=wv.surroundAOM.whiskamp_stim_surround(:, ind);
whiskamp_nostim=wv.surroundAOM.whiskamp_nostim_surround;
whiskpos_stim=wv.surroundAOM.whiskpos_stim_surround(:, ind);
twhisk_surround=wv.surroundAOM.twhisk_surround;

figure

newrank=randperm(nstim);

for i=1:9
    ii=newrank(i);
    ha1=axes('nextplot', 'add','xtick', [],'ytick', [], 'unit', 'normalized', 'position', [.2 .1*i .7 .08], 'color', 'none', 'xlim', [-100 500], 'ylim', yrange); %#ok<LAXES>
    plot(tvm_surround, vmstim(:, ii));
    line([0 0], yrange, 'color', 'r', 'linestyle', ':')
    ha2=axes('nextplot', 'add', 'xtick', [],'ytick',[],  'unit', 'normalized', 'position', [.2 .1*i .7 .08], 'color', 'none', 'xlim', [-100 500], 'ylim', whiskrange); %#ok<LAXES>
    plot(twhisk_surround, whiskamp_stim(:, ii), 'k');
    
    if i==1
        set(ha1, 'xtick', [-100:100:500], 'ytick', [-80:20:0]);
    end;
    
end;

vmstim2=vmstim;
vmstim=sgolayfilt(removeAP(vmstim, 10000, 10, 4), 3, 41);
whiskamp_pre=max(whiskamp_stim(twhisk_surround<200 & twhisk_surround>0, :),[], 1);
Vmpre=mean(vmstim(tvm_surround<=0 & tvm_surround>=-50, :), 1);
dVm=min(vmstim(tvm_surround>=50 & tvm_surround<=200, :),[], 1)-Vmpre;

vmnostim2=vmnostim;
vmnostim=sgolayfilt(removeAP(vmnostim, 10000, 10, 4), 3, 41);
Vmprenostim=mean(vmnostim(tvm_surround<=0 & tvm_surround>=-50, :), 1);
dVmnostim=min(vmnostim(tvm_surround>=50 & tvm_surround<=200, :),[], 1)-Vmprenostim;
whiskamp_prenostim=max(whiskamp_nostim(twhisk_surround<00, :), [],1);

vmstim50=vmstim(:, aomfreq==50);
vmstimgrid=vmstim(:, aomfreq==100);


figure;
subplot(1, 2, 1)
set(gca, 'nextplot', 'add', 'ylim', yrange, 'xlim', [min(tvm_surround), 400])
if ~isempty(find(aomfreq==50))
    plot(tvm_surround, vmstim2(:, aomfreq==50), 'color', [0.75 0.75 0.75]);
    plot(tvm_surround, mean(vmstim50, 2), 'k', 'linewidth', 1);
end;

subplot(1, 2, 2)

if ~isempty(find(aomfreq==100))
    set(gca, 'nextplot', 'add', 'ylim', yrange, 'xlim', [min(tvm_surround), 400])
    plot(tvm_surround, vmstim2(:, aomfreq==100), 'color', [0.75 0.75 0.75]);
    plot(tvm_surround, mean(vmstimgrid, 2), 'k', 'linewidth', 1);
end;

figure; 

plot(whiskamp_pre, dVm, 'ko');
[r, p]=corrcoef(whiskamp_pre, dVm)

%% control, nostim
hf0=figure; 
set(hf0, 'unit', 'centimeters', 'position', [2 2 12 6], 'paperpositionmode', 'auto');

subplot(1, 2, 1)
plot(tvm_surround, vmnostim2, 'color', [.6 .6 .6], 'linewidth', 1)
hold on
plot(tvm_surround, mean(vmnostim, 2), 'color', 'k', 'linewidth', 1);
newrank2=randperm(size(vmnostim2, 2))
nx=newrank2(1:4);
plot(tvm_surround, vmnostim2(:, nx(1)), 'color','r', 'linewidth', 1)
plot(tvm_surround, vmnostim2(:, nx(2)), 'color','c', 'linewidth', 1)
plot(tvm_surround, vmnostim2(:, nx(3)), 'color','m', 'linewidth', 1)
plot(tvm_surround, vmnostim2(:, nx(4)), 'color','g', 'linewidth', 1)

set(gca, 'xlim', [-100 500], 'ylim',yrange)

xlabel('Time')
ylabel('mV')

title(wv.name(end-9:end));

subplot(1, 2, 2)
plot(Vmprenostim, dVmnostim, 'k^');hold on

plot(Vmprenostim(nx(1)), dVmnostim(nx(1)), 'r^', 'linewidth',1.5);
plot(Vmprenostim(nx(2)), dVmnostim(nx(2)), 'c^', 'linewidth',1.5);
plot(Vmprenostim(nx(3)), dVmnostim(nx(3)), 'm^', 'linewidth',1.5);
plot(Vmprenostim(nx(4)), dVmnostim(nx(4)), 'g^', 'linewidth',1.5);

[r2, p2]=corrcoef(Vmprenostim, dVmnostim)

xlabel('Vm level before onset')
ylabel('dVm')

title(['r=', num2str(r2(1, 2)) '; p=', num2str(p2(1, 2))])
%%

hf=figure; 
set(hf, 'unit', 'centimeters', 'position', [2 2 12 12], 'paperpositionmode', 'auto');

subplot(2, 2, 1)
plot(tvm_surround, vmstim2, 'color', [.6 .6 .6], 'linewidth', 1)
hold on
plot(tvm_surround, mean(vmstim, 2), 'color', 'k', 'linewidth', 1);

nx=newrank(1:4);
plot(tvm_surround, vmstim2(:, nx(1)), 'color','r', 'linewidth', 1)
plot(tvm_surround, vmstim2(:, nx(2)), 'color','c', 'linewidth', 1)
plot(tvm_surround, vmstim2(:, nx(3)), 'color','m', 'linewidth', 1)
plot(tvm_surround, vmstim2(:, nx(4)), 'color','g', 'linewidth', 1)

plot(tvm_surround, aom(:, nx(1))+yrange(1)+2, 'b')

set(gca, 'xlim', [-100 500], 'ylim',yrange)

xlabel('Time')
ylabel('mV')

title(wv.name(end-9:end));

subplot(2, 2, 3)

plot(Vmprenostim, dVmnostim, 'square', 'color', [0.8 0.8 0.8]);
hold on
plot(Vmpre, dVm, '^k', 'color', 'k');
%plot(Vmpre(aomfreq==100), dVm(aomfreq==100), 'k^', 'markerfacecolor', 'k');

plot(Vmpre(nx(1)), dVm(nx(1)), 'r^', 'linewidth',1.5);
plot(Vmpre(nx(2)), dVm(nx(2)), 'c^', 'linewidth',1.5);
plot(Vmpre(nx(3)), dVm(nx(3)), 'm^', 'linewidth',1.5);
plot(Vmpre(nx(4)), dVm(nx(4)), 'g^', 'linewidth',1.5);

[r2, p2]=corrcoef(Vmpre, dVm)


[pnostim, snostim]=polyfit(Vmprenostim, dVmnostim, 1);
y2=polyval(pnostim, [min(Vmprenostim):max(Vmprenostim)])
plot([min(Vmprenostim):max(Vmprenostim)], y2, 'color', [0.75 0.75 0.75], 'linewidth', 1);

[pstim, sstim]=polyfit(Vmpre, dVm, 1);
y=polyval(pstim, [min(Vmpre):max(Vmpre)])
plot([min(Vmpre):max(Vmpre)], y, 'color', 'k', 'linewidth', 1);


xlabel('Vm level before onset')
ylabel('dVm')

title(['r=', num2str(r2(1, 2)) '; p=', num2str(p2(1, 2))])

subplot(2, 2, 2)
plot(twhisk_surround, whiskamp_stim, 'color', [0.5 0.5 0.5], 'linewidth', 1);
hold on
plot(twhisk_surround, whiskamp_stim(:, nx(1)), 'color','r', 'linewidth', 1)
plot(twhisk_surround, whiskamp_stim(:, nx(2)), 'color','c', 'linewidth', 1)
plot(twhisk_surround, whiskamp_stim(:, nx(3)), 'color','m', 'linewidth', 1)
plot(twhisk_surround, whiskamp_stim(:, nx(4)), 'color','g', 'linewidth', 1)

set(gca, 'xlim', [-100 500], 'ylim', [-5 whiskrange(2)])
plot(tvm_surround, aom(:, nx(1))/2-4, 'b')

xlabel('Time')
ylabel('Whisking amplitude')

subplot(2, 2, 4)
plot(whiskamp_prenostim, dVmnostim, 'square', 'color', [0.8 0.8 0.8]); hold on
plot(whiskamp_pre, dVm, 'o', 'color', 'k');
%plot(whiskamp_pre(aomfreq==100), dVm(aomfreq==100), 'ko', 'markerfacecolor', 'k')
plot(whiskamp_pre(nx(1)), dVm(nx(1)), 'ro', 'linewidth',1.5);
plot(whiskamp_pre(nx(2)), dVm(nx(2)), 'co', 'linewidth',1.5);
plot(whiskamp_pre(nx(3)), dVm(nx(3)), 'mo', 'linewidth',1.5);
plot(whiskamp_pre(nx(4)), dVm(nx(4)), 'go', 'linewidth',1.5);

xlabel('Whisking amp')
ylabel('dVm')

title(['r=', num2str(r(1, 2)) '; p=', num2str(p(1, 2))])

 if tosave
     saveas(hf, ['trial_to_trial_var'], 'fig')
     saveas(hf, ['trial_to_trial_var'], 'tif')
 end;
