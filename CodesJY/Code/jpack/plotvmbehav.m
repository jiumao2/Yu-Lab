function plotvmbehav(T, dataout, b, trialcount, whiskrange, vmrange)

% 2013.4.18
% plot vm and behavior, including licks and whisking
% load('trial_array_ANM190963_130406_JY0514AAAA.mat')
% load('dataoutJY0514AAAAwid1.mat')
% load('beh.mat')

if nargin<6
    vmrange=[-70 0];
    if nargin<5
        whiskrange=[0 15];
    end;
end;


close all
Fs=10000;

hitcount=trialcount(1);
crcount=trialcount(2);

nhitrand=randperm(size(cell2mat(dataout.neural_hit_nostim), 2));
vmhit_index=nhitrand(1:hitcount); % when the animal was still behaving

ncrrand=randperm(size(cell2mat(dataout.neural_cr_nostim), 2));
vmcr_index=ncrrand(1:crcount);

% for "hit" trials
trialstr_hit=dataout.hit_nostim_nums(vmhit_index); 
[vmhitall, dum, tvm, fp_hitall,  twhiskhit, whiskhit]=findvmtrials(T, trialstr_hit);

twhiskstandard=[0:1/1000:4.999];
whisk_params_hit=whiskdecomposej(whiskhit, twhiskhit, twhiskstandard);
twhisk=twhiskstandard+0.01;
    
p_hit=[];

p_hit.des=T.pinDescentOnsetTimes(trialstr_hit); % when the pole starts to move in
p_hit.as=T.pinAscentOnsetTimes(trialstr_hit); % when the pole starts to go away
p_hit.rewards=b.rewardTime(trialstr_hit);

for i=1:length(trialstr_hit)
    lickmat=T.get_all_lick_times(trialstr_hit(i))
    p_hit.licks{i}=lickmat(:, 3);
end;

hf=figure;
set(hf, 'units', 'centimeters', 'position', [2 2 8 12], 'PaperPositionMode','auto')
ha=subplot(4, 1, 1)
title (T.cellNum)
set(ha, 'nextplot', 'add', 'ylim', [0 35], 'xlim', [0 5], 'fontsize', 10);

for i=1:length(trialstr_hit)
    if ~isempty(p_hit.licks{i})
        plot(p_hit.licks{i}, i, 'm', 'marker', '.', 'markersize', 4);
    end;
    % plot pole profile
    line([p_hit.des(i) p_hit.des(i)+0.25], [35 30], 'linewidth', 2, 'color', [.8 .8 .8]);
    line([p_hit.des(i)+0.25 p_hit.as(i)], [30 30], 'linewidth', 2, 'color', [0 0 0]);
    line([p_hit.as(i) p_hit.as(i)+0.25], [30 35], 'linewidth', 2, 'color', [.8 .8 .8]);
end;

ylabel('Hit trials')

% plot raw data:
ha=subplot(4, 1, 2)
set(ha, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vmrange, 'fontsize', 10);
vmhitall=sgolayfilt(vmhitall, 3, 31);
plot(tvm, vmhitall, 'color', [.75 .75 .75]);
vmhitall=removeAP(vmhitall, Fs, 5, 4);
plot(tvm, mean(vmhitall, 2), 'b', 'linewidth', 1)

% fp_hitall=sgolayfilt(fp_hitall, 3, 31);
% plot(tvm, 5*fp_hitall, 'color', [.75 .75 .75]);
% plot(tvm, 5*mean(fp_hitall, 2), 'k', 'linewidth', 1)

% plot(tvm, mean(vmhitall, 2), 'color', 'b', 'linewidth', 1);

% for "cr" trials

trialstr_cr=dataout.cr_nostim_nums(vmcr_index); 
[vmcrall, dum, tvm, fp_crall, twhiskcr, whiskcr]=findvmtrials(T, trialstr_cr);
whisk_params_cr=whiskdecomposej(whiskcr, twhiskcr, twhiskstandard);
   

fp_crall=sgolayfilt(fp_crall, 3, 31);
p_cr=[];

p_cr.des=T.pinDescentOnsetTimes(trialstr_cr); % when the pole starts to move in
p_cr.as=T.pinAscentOnsetTimes(trialstr_cr); % when the pole starts to go away
p_cr.rewards=b.rewardTime(trialstr_cr);

for i=1:length(trialstr_cr)
    lickmat=T.get_all_lick_times(trialstr_cr(i))
    p_cr.licks{i}=[];
    if ~isempty(lickmat)
        p_cr.licks{i}=lickmat(:, 3);
    end;
end;


ha=subplot(4, 1, 3)
set(ha, 'nextplot', 'add', 'ylim', [0 35], 'xlim', [0 5], 'fontsize', 10);
for i=1:length(trialstr_cr)
    if ~isempty(p_cr.licks{i})
        plot(p_cr.licks{i}, i, 'm', 'marker', '.', 'markersize', 4);
    end;
    % plot pole profile
    line([p_cr.des(i) p_cr.des(i)+0.25], [35 30], 'linewidth', 2, 'color', [.8 .8 .8]);
    line([p_cr.des(i)+0.25 p_cr.as(i)], [30 30], 'linewidth', 2, 'color', [0 0 0]);
    line([p_cr.as(i) p_cr.as(i)+0.25], [30 35], 'linewidth', 2, 'color', [.8 .8 .8]);
    
end;

ylabel('CR trials')

% plot raw CR data:

ha=subplot(4, 1, 4)
set(ha, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vmrange, 'fontsize', 10);
vmcrall=sgolayfilt(vmcrall, 3, 31);
plot(tvm, vmcrall,  'color', [.75 .75 .75]);
vmcrall=removeAP(vmcrall, Fs, 10, 4);
plot(tvm, mean(vmcrall, 2), 'r', 'linewidth', 1)
% plot(tvm, mean(vmcrall, 2), 'color', 'r', 'linewidth', 1);

hf2=figure;
set(hf2, 'units', 'centimeters', 'position', [2 2 8 5], 'PaperPositionMode','auto')

ha=axes;
set(ha, 'nextplot', 'add', 'xlim', [0 4.8], 'ylim', [-60 -40], 'ytick', [-60:5:-40], 'fontsize', 10);

vhitmean=mean(vmhitall, 2);
vcrmean=mean(vmcrall, 2);

vhitsd=std(vmhitall, 0, 2)/sqrt(size(vmhitall, 2)); 
vcrsd=std(vmcrall, 0, 2)/sqrt(size(vmcrall, 2));

plot(tvm, vhitmean, 'b', 'linewidth', 1);
plot(tvm, vcrmean, 'r', 'linewidth', 1);
% % 
% plot(tvm(index),  vhitmean(index)+vhitsd(index, :), 'b', 'linewidth', .5);
% 
% plot(tvm(index),  vhitmean(index)-vhitsd(index, :), 'b', 'linewidth', .5);
% 
% plot(tvm(index),  vcrmean(index)-vcrsd(index, :), 'r', 'linewidth', .5);
% plot(tvm(index),  vcrmean(index)+vcrsd(index, :), 'r', 'linewidth', .5);

line([3 4], [-50 -50], 'color', 'k', 'linewidth', 2)
line([4 4], [-50 -45], 'color', 'k', 'linewidth', 2)

p_hit_des=mean(p_hit.des);
p_hit_as=mean(p_hit.as);

line([p_hit_des p_hit_des+0.5], [-42 -45], 'linewidth', 2, 'color', [.8 .8 .8]);
line([p_hit_des+0.5 p_hit_as], [-45 -45], 'linewidth', 2, 'color', [0 0 0]);
line([p_hit_as p_hit_as+0.5], [-45 -42], 'linewidth', 2, 'color', [.8 .8 .8]);

p_cr_des=mean(p_cr.des);
p_cr_as=mean(p_cr.as);

% line([p_cr_des p_cr_des+0.5], [-44 -47], 'linewidth', 2, 'color', [.8 .8 .8]);
% line([p_cr_des+0.5 p_cr_as], [-47 -47], 'linewidth', 2, 'color', [0 0 0]);
line([p_cr_as p_cr_as+0.5], [-45 -42], 'linewidth', 2, 'color', [.8 .8 .8]);

xlabel('s')
ylabel('mV')

hf4=figure;
set(hf4, 'units', 'centimeters', 'position', [2 2 6 6], 'paperpositionmode', 'auto');
ha=axes;
set(ha, 'nextplot', 'add', 'xlim', [tvm(1) tvm(end)], 'xtick', [1:4], 'ylim', whiskrange, 'unit', 'centimeters', 'position', [1.5 1.5 3.7424 4.0746]);
plot(twhisk, mean(whisk_params_hit.amp, 2), 'b');
plot(twhisk, mean(whisk_params_cr.amp, 2), 'r');
xlabel('Time (s)')
ylabel('Whisking amp (deg)')

  plot (mean(p_hit.des, 2), 11,'k*');
  plot(mean(p_hit.des, 2)+0.25, 11,'ok' )
 line([mean(p_hit.des, 2)+0.25 mean(p_cr.as, 2)], [10 10], 'linewidth', 2, 'color', [0 0 0]);


print (hf, '-depsc2', 'GoNogo')
print(hf2, '-depsc2', 'Vmcompare')
print(hf4, '-depsc2', 'GoNoGoWhisking')
