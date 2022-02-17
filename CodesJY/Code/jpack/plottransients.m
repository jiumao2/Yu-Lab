clear all;
close all;
n=1000;
cd ('C:\Work\Projects\BehavingVm\Data\Groupdata')
load('vmstim_onoff.mat')

t_onset=vmcompare.onset{1}(:, 1);
t_offset=vmcompare.offset{1}(:, 1);
aom_onset=vmcompare.onset{1}(:, 5);
aom_offset=vmcompare.offset{1}(:,5);

vm_onset=[];
vm_offset=[];
for i=1:length(vmcompare.onset)
    vmnostim_onset(:,i)=vmcompare.onset{i}(:, 2);
    vmstim_onset(:,i)=vmcompare.onset{i}(:, 3);
    vmnostim_offset(:,i)=vmcompare.offset{i}(:, 2);
    vmstim_offset(:,i)=vmcompare.offset{i}(:, 3);
    dvm_onset(:, i)=vmcompare.onset{i}(:, 4);
    dvm_offset(:,i)=vmcompare.offset{i}(:, 4);
end;

avg_vmnostim_onset=mean(vmnostim_onset, 2);
ci_vmnostim_onset=bootci(n, @mean, vmnostim_onset'); 
ci_vmnostim_onset=ci_vmnostim_onset';

avg_vmstim_onset=mean(vmstim_onset, 2);
ci_vmstim_onset=bootci(n, @mean, vmstim_onset'); 
ci_vmstim_onset=ci_vmstim_onset';

avg_vmnostim_offset=mean(vmnostim_offset, 2);
ci_vmnostim_offset=bootci(n, @mean, vmnostim_offset'); 
ci_vmnostim_offset=ci_vmnostim_offset';

avg_vmstim_offset=mean(vmstim_offset, 2);
ci_vmstim_offset=bootci(n, @mean, vmstim_offset'); 
ci_vmstim_offset=ci_vmstim_offset';

avg_dvm_onset=mean(dvm_onset, 2);
ci_dvm_onset=bootci(n, @mean, dvm_onset'); 
ci_dvm_onset=ci_dvm_onset';

[maxhyper, indmax]=max(abs(avg_dvm_onset));
half_hyper=0.5*maxhyper;

[y, half_time]=min(abs(abs(avg_dvm_onset(1:indmax))-half_hyper));

half_time=t_onset(half_time)



avg_dvm_offset=mean(dvm_offset, 2);
ci_dvm_offset=bootci(n, @mean, dvm_offset'); 
ci_dvm_offset=ci_dvm_offset';


%% load direct effect
 load('vmdirectstim_onoff.mat')
t_onset2=vmcompare.onset{1}(:, 1);
t_offset2=vmcompare.offset{1}(:, 1);

vm_onset2=[];
vm_offset2=[];

indon=find(t_onset2<=0);
indoff=find(t_offset2>=500);

for i=1:length(vmcompare.onset)
    
    dvm_onset2_i=vmcompare.onset{i}(:, 2);
    dvm_onset2(:, i)=dvm_onset2_i-mean(dvm_onset2_i(indon));
    
    dvm_offset2_i=vmcompare.offset{i}(:, 2);
    dvm_offset2(:,i)=dvm_offset2_i-mean(dvm_offset2_i(indoff));
    
end;

avg_dvm_onset2=mean(dvm_onset2, 2);
ci_dvm_onset2=bootci(n, @mean, dvm_onset2'); 
ci_dvm_onset2=ci_dvm_onset2';

[maxhyper, indmaxhyper]=max(abs(avg_dvm_onset2));
half_hyper=0.5*maxhyper;

[y, half_time2]=min(abs(abs(avg_dvm_onset2(1:indmaxhyper))-half_hyper));

half_time2=t_onset2(half_time2)

avg_dvm_offset2=mean(dvm_offset2, 2);
ci_dvm_offset2=bootci(n, @mean, dvm_offset2'); 
ci_dvm_offset2=ci_dvm_offset2';


hf1=figure;

set(hf1, 'units', 'centimeters', 'position', [3 3 10 10])

ha(1)=axes;
set(ha(1),'units', 'normalized','color', 'none', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_onset) max(t_onset)],'ylim', [-8 3], 'ytick', [-8:2:4], 'fontsize', 10)
axes(ha(1))
plot(t_onset, avg_dvm_onset, 'b', 'linewidth', 1.5);
plot(t_onset, ci_dvm_onset, 'b', 'linewidth', .5);
plot(t_onset, aom_onset/4+1, 'b');

line([0 0], [-8 3], 'color', 'k', 'linestyle', '--')

box off
xlabel('Time from onset (ms)')
ylabel('M1 stim: Vm change (mV)')

ha(2)=axes;
set(ha(2),'units', 'normalized','yaxislocation', 'right','color', 'none', 'xtick', [],'ycolor','m', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_onset) max(t_onset)], 'ylim', [-17 5],'ytick',[-20:5:5], 'fontsize', 10)
plot(t_onset2, avg_dvm_onset2, 'm', 'linewidth', 1.5);
plot(t_onset2, ci_dvm_onset2, 'm', 'linewidth', .5);
ylabel('S1 stim: Vm change (mV)')

hf2=figure;

set(hf2, 'units', 'centimeters', 'position', [6 3 10 10])

ha(1)=axes;
set(ha(1),'units', 'normalized','color', 'none', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_offset) max(t_offset)],'ylim', [-8 3], 'ytick', [-8:2:4], 'fontsize', 10)
axes(ha(1))
plot(t_offset, avg_dvm_offset, 'b', 'linewidth', 1.5);
plot(t_offset, ci_dvm_offset, 'b', 'linewidth', .5);
plot(t_offset, aom_offset/4+1, 'b');
line([0 0], [-8 3], 'color', 'k', 'linestyle', '--')
box off
xlabel('Time from offset (ms)')
ylabel('M1 stim: Vm change (mV)')

ha(2)=axes;
set(ha(2),'units', 'normalized','yaxislocation', 'right','color', 'none', 'xtick', [],'ycolor','m', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_offset) max(t_offset)], 'ylim', [-17 5],'ytick',[-20:5:5], 'fontsize', 10)
plot(t_offset2, avg_dvm_offset2, 'm', 'linewidth', 1.5);
plot(t_offset2, ci_dvm_offset2, 'm', 'linewidth', .5);
ylabel('S1 stim: Vm change (mV)')


saveas (hf1, ['onset'], 'fig');
saveas(hf1, ['onset'], 'tif');

saveas (hf2, 'offset', 'fig');
saveas(hf2, 'offset', 'tif');


hf3=figure;

set(hf3, 'units', 'centimeters', 'position', [3 3 10 10])

ha(1)=axes;
set(ha(1),'units', 'normalized','color', 'none', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_onset) 100],'ylim', [-8 3], 'ytick', [-8:2:4], 'fontsize', 10)
axes(ha(1))
plot(t_onset, avg_dvm_onset, 'b', 'linewidth', 1.5);
plot(t_onset, ci_dvm_onset, 'b', 'linewidth', .5);
plot(t_onset, aom_onset/4+1, 'b');
line([0 0], [-8 3], 'color', 'k', 'linestyle', '--')
box off
xlabel('Time from onset (ms)')
ylabel('M1 stim: Vm change (mV)')

ha(2)=axes;
set(ha(2),'units', 'normalized','yaxislocation', 'right','color', 'none', 'xtick', [],'ycolor','m', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_onset) 100], 'ylim', [-17 5],'ytick',[-20:5:5], 'fontsize', 10)
plot(t_onset2, avg_dvm_onset2, 'm', 'linewidth', 1.5);
plot(t_onset2, ci_dvm_onset2, 'm', 'linewidth', .5);
ylabel('S1 stim: Vm change (mV)')

hf4=figure;

set(hf4, 'units', 'centimeters', 'position', [6 3 10 10])

ha(1)=axes;
set(ha(1),'units', 'normalized','color', 'none', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_offset) 400],'ylim', [-8 3], 'ytick', [-8:2:4], 'fontsize', 10)
axes(ha(1))
plot(t_offset, avg_dvm_offset, 'b', 'linewidth', 1.5);
plot(t_offset, ci_dvm_offset, 'b', 'linewidth', .5);
plot(t_offset, aom_offset/4+1, 'b');
line([0 0], [-8 3], 'color', 'k', 'linestyle', '--')
box off
xlabel('Time from offset (ms)')
ylabel('M1 stim: Vm change (mV)')

ha(2)=axes;
set(ha(2),'units', 'normalized','yaxislocation', 'right','color', 'none', 'xtick', [],'ycolor','m', 'position', [.2 .2 .7 .7], 'nextplot', 'add', 'xlim', [min(t_offset) 400], 'ylim', [-17 5],'ytick',[-20:5:5], 'fontsize', 10)
plot(t_offset2, avg_dvm_offset2, 'm', 'linewidth', 1.5);
plot(t_offset2, ci_dvm_offset2, 'm', 'linewidth', .5);
ylabel('S1 stim: Vm change (mV)')


saveas (hf3, ['onsetzoom'], 'fig');
saveas(hf3, ['onsetzoom'], 'tif');
saveas (hf4, ['offsetzoom'], 'fig');
saveas(hf4, ['offsetzoom'], 'tif');

