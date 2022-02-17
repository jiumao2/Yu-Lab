function spkout=halo_onoff(T, badtrials,type, pre, post, binsize, plotwhisk, plotorder, filename, calpulse)

if nargin<10
    calpulse=0;
if nargin<9
    filename=[];
    if nargin<8
        plotwhisk=1;
    end;
    end;
end;

if nargin<3
base=-60;
end;
switch type
    case 'orange'
        stimcol=[255 159 0]/255;
    case 'blue'
        stimcol=[0 0 .75];
    otherwise
        return
end;

% need T, badtrials, etc.
if nargin<6
    post=3;
    if nargin<5
        pre=0.1;
    end;
end;
Fs=10000;

length_inwhisk=(post+pre)*1000; % the length of whisking data that will be taken into account

trial_stim=setdiff(T.stimtrialNums, badtrials);
trial_nostim=setdiff(T.trialNums, [T.stimtrialNums badtrials]);

vall=findvmtrials(T, sort([trial_stim trial_nostim]));

poleonset=median(cellfun(@(x)x.behavTrial.pinDescentOnsetTime, T.trials));

figure;
subplot(2, 1, 1)
plot(vall(:))
subplot(2, 1, 2)
plot(mean(vall(1:50000, :),	1), 'bo-')


[vstim, vlaserstim, tvm, ~, twhisk_stim, whisk_stim, spkstim]=findvmtrials(T, trial_stim);
[vnostim, ~, ~, ~, twhisk_nostim, whisk_nostim, spknostim]=findvmtrials(T, trial_nostim);

whiskout_stim=whiskdecomposej(whisk_stim, twhisk_stim, [0:0.001:4.999]);
whiskout_nostim=whiskdecomposej(whisk_nostim, twhisk_nostim, [0:0.001:4.999]);

twhisk=whiskout_stim.twhisk+0.01;
%
% whiskamp_stim=mean(whiskout_stim.amp, 2);
% whiskamp_nostim=mean(whiskout_nostim.amp, 2);

vstim_al=[]; % aligned traces during stimulation
spkstim_al=[];
lasershutter=[];
whiskstim_al=[]; % aligned whisking during stim

for i=1:size(vlaserstim, 2)
    onsets(i)=find(vlaserstim(:, i)>1, 1, 'first');
    vstim_al(:, i)=vstim(onsets(i)-pre*Fs:onsets(i)+post*Fs, i);
    spkstim_al(:, i)=spkstim(onsets(i)-pre*Fs:onsets(i)+post*Fs, i);
    lasershutter(:, i)=vlaserstim(onsets(i)-pre*Fs:onsets(i)+post*Fs, i);
    [~, idist]=min(abs(twhisk-onsets(i)/10000));
    ind_whisk=idist-pre*1000:idist-pre*1000+length_inwhisk;
    whiskstim_al(:, i)=whiskout_stim.amp(ind_whisk, i);
end;

[psth_stim, thist_stim]=spikehisto(spkstim_al, 10000,  round((pre+post)/(binsize/1000)));
% removeAPnew(Vm,Fs,ratio_dvdt, Vbound, dvdtlow, toplot)
vstim_avg=mean(sgolayfilt(removeAPnew(vstim_al, 10000, 0.33, [-50 -45 80 15], 10000, 0), 3, 41), 2);
lasershutterall=lasershutter;
lasershutter=mean(lasershutter, 2);

vnostim_al=[];
whisknostim_al=[];
spknostim_al=[];
for k=1:size(vnostim, 2)
    newrank=randperm(length(onsets));
    onset_new=onsets(newrank(1));
    vnostim_al(:, k)=vnostim(onset_new-pre*Fs:onset_new+post*Fs, k);
    spknostim_al(:, k)=spknostim(onset_new-pre*Fs:onset_new+post*Fs, k);
    [~, idist]=min(abs(twhisk-onset_new/10000));
    ind_whisk=idist-pre*1000:idist-pre*1000+length_inwhisk;
    whisknostim_al(:, k)=whiskout_nostim.amp(ind_whisk, k);
end;

[psth_nostim, thist_nostim]=spikehisto(spknostim_al, 10000,  round((pre+post)/(binsize/1000)));

vnostim_avg=mean(sgolayfilt(removeAPnew(vnostim_al, 10000, 0.33, [-50 -45 80 15], 10000, 0), 3, 41), 2);

t=[-pre*Fs:post*Fs]/10;
twhisk_al=[-pre*1000:-pre*1000+length_inwhisk];

hf=figure;
set(hf, 'unit', 'centimeters', 'position', [2 2 8 12], 'paperpositionmode', ' auto', 'color', 'w');
ha2=subplot(3, 1, 2)
plot(t, vnostim_avg, 'k', 'linewidth', 1.5);
hold on
plot(t, vstim_avg, 'color', stimcol, 'linewidth', 1.5)
plot(t, lasershutter/4+min([vnostim_avg; vstim_avg])-2, 'color', stimcol);

set(gca, 'xlim', [-pre post]*1000)

xlabel('Time (ms)')
ylabel ('Vm (mV)')

ha1=subplot(3, 1, 1);
if plotwhisk
    plot(twhisk_al, mean(whisknostim_al, 2), 'k', 'linewidth', 1.5);hold on
    plot(twhisk_al, mean(whiskstim_al, 2), 'color', stimcol, 'linewidth', 1.5);

    set(gca, 'xlim', [-pre post]*1000)
    xlabel('Time (ms)')
    ylabel('Whisking amp (deg)')
end;

title ([T.cellNum T.cellCode])
% spikes
ha3=subplot(3, 1, 3);
set(gca, 'nextplot', 'add')

bar(thist_nostim*1000-pre*1000, psth_nostim, 1, 'edgecolor','none',  'facecolor', 'k', 'linewidth', .5);
h = findobj(gca,'Type','patch');
set(h,'FaceColor', [0 0 0],'EdgeColor', 'none','facealpha',0.75)

bar(thist_stim*1000-pre*1000, psth_stim, 1,'edgecolor', 'none',  'facecolor', stimcol, 'linewidth', .5);
h1 = findobj(gca,'Type','patch');
set(setdiff(h1, h),'FaceColor', stimcol,'EdgeColor', 'none','facealpha',0.5)

set(gca, 'xlim', [-pre post]*1000)
xlabel('Time (ms)')
ylabel('Spk')

spkout.twhisk=twhisk_al;
spkout.whisknostim=whisknostim_al;
spkout.whiskstim=whiskstim_al;
spkout.tvm=t;
spkout.vnostim=vnostim_avg;
spkout.vstim=vstim_avg;
spkout.spknostim=spknostim_al;
spkout.spkstim=spkstim_al;
spkout.thist_nostim=thist_nostim*1000-pre*1000;
spkout.psth_nostim=psth_nostim;
spkout.thist_stim=thist_stim*1000-pre*1000;
spkout.psth_stim=psth_stim;
spkout.aom=lasershutter;

if plotwhisk
linkaxes([ha1, ha2, ha3], 'x')
end;

filename=['LaserOnOff' filename];

export_fig(hf, filename, '-tiff');
print(gcf, '-depsc',  filename)

save ([filename '.mat'], 'spkout')

if calpulse
[pulse.vm_pulsetrig, pulse.vm_pulsetrigorg, pulse.spk_pulsetrig, pulse.aom_pulse, pulse.t_pulsetrig]=triggeringvm(vstim_al, spkstim_al, lasershutterall);

save directpulse pulse
end

function [vm_pulsetrig, vm_pulsetrigorg, spk_pulsetrig, aom_pulse, t_pulsetrig]=triggeringvm(vm, spk, aom)


vm_pulsetrig=[];
vm_pulsetrigorg=[];
vm_miss=[];
spk_pulse=[];

aom_pulse=[];

for i=1:size(vm, 2)
    aomi=aom(:, i);
    
        above=find(aomi>1);
        if ~isempty(above)
            aom_pulseon=above([1 ;1+find(diff(above)>1)]);
        end;
        
        freq=10000/median(diff(aom_pulseon));
    
    for j=1:length(aom_pulseon)
        ind=[aom_pulseon(j)-5*10:aom_pulseon(j)+(1000/freq)*10];
        
        vm_pulsetrig=[vm_pulsetrig vm(ind, i)];
        vm_pulsetrigorg=[vm_pulsetrigorg vm(ind, i)];
        spk_pulse=[spk_pulse spk(ind, i)];

        aom_pulse=[aom_pulse aomi(ind)];
    end
end;
t_pulsetrig=[-5*10:1000/freq*10]/10;
binsize=1;
%  [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
[histos, ts]=spikehisto(spk_pulse, 10000, floor(size(spk_pulse, 1)/(10*binsize)));
spk_pulsetrig.histos=histos;
spk_pulsetrig.ts=1000*(ts-0.005);
spk_pulsetrig.spkall=spk_pulse;