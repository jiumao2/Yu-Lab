function plotvmstim(T, stimfreq, ylims, type, th, badtrials,time,binsize, scalefac, tosave, win, hyp)
% e.g. plotvmstim(T, 2 , [-60 -30; 0 100] ,'5ms', 10, [], [], 0.002 , 1, 1,250, 1)
if nargin<12
    hyp=0;
if nargin<11
    win=50;
    if nargin<10
        tosave=0;
        if nargin<9
            scalefac=1;
            if nargin<8
                binsize=0.01;
                if nargin<7
                    time=[];
                    if nargin<6
                        badtrials=[];
                        if nargin<5
                            th=5;
                            if nargin<4
                                type='5ms';
                                if nargin<3
                                    ylims=[-70 -20; 0 25];
                                    if nargin<2
                                        stimfreq=[10 20 50];
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;
end;

Fs=10000;

trigrange=win;

% find stimulation frequency and corresponding Vm
ind_nostim=setdiff(T.trialNums, [badtrials T.stimtrialNums]);
tbin=[0:binsize:5.2];

vmnostim=[];
r_nostim=[];
if ~isempty(ind_nostim)
vmnostim=findvmtrials(T, ind_nostim);
t=[0:size(vmnostim, 1)-1]/10;
r_nostim=T.PSTH(ind_nostim, tbin);
end;


switch type
    
    case {'5ms'} % regular M1 pulses
        ind=setdiff(findM1trials(T, '5ms', stimfreq, scalefac), findM1trials(T, '5ms', stimfreq, scalefac*2));
        s1=0;
    case {'constant'} % M1 constant stim.
        ind=setdiff(setdiff(findM1trials(T, 'constant', [], scalefac), findM1trials(T, 'constant',[], scalefac*2)), setdiff(findM1trials(T, 'constant_shift', [], scalefac), findM1trials(T, 'constant_shift', [], scalefac*2)));
        s1=0;
    case {'shift'} % shift pulses, e.g., S1
        ind=setdiff(findM1trials(T, 'shift', stimfreq, scalefac),findM1trials(T, 'shift', stimfreq, scalefac*2) );
        s1=1;
    case {'constant_shift'} % shift constant, e.g., s1
        ind=setdiff(findM1trials(T, 'constant_shift', [], scalefac),findM1trials(T, 'constant_shift',[], scalefac*2) );
        s1=1;
    case {'depblock'}
        ind=intersect(findM1trials(T, 'depblock', stimfreq, 0.1), findM1trials(T, 'depblock', stimfreq, 1)) ;
        s1=0;
    otherwise
        error('no trials found')
end;

if isempty(ind)
    error ('no trials found')
else
    [vmstim, aom]=findvmtrials(T, setdiff(ind, badtrials));
    r=T.PSTH(ind, tbin);
end;

hf=figure;
set(hf, 'unit', 'centimeters','position', [5 1 8 12], 'paperpositionmode', 'auto')

if ~isempty(vmnostim)
    vbase=mean(mean(medfilt1(vmnostim, 40), 2));
else
    vbase=0;
    t=[0:size(vmstim, 1)-1]/10;
end;

pole_in=T.pinDescentOnsetTimes(ind(1))+0.2;
pole_out=T.pinAscentOnsetTimes(ind(1));

ha1=axes;
set(ha1, 'unit', 'normalized', 'nextplot', 'add', 'position', [0.2 0.75 0.7 0.15], 'fontsize', 8, 'xlim', [t(1) t(end)], 'ylim', ylims(1, :));
if ~isempty(vmnostim)
    plot(t, mean(medfilt1(vmnostim, 40), 2), 'k');hold on
    line([t(1) t(end)], [vbase vbase], 'color', 'k', 'linestyle', ':')
    
    line([pole_in pole_out]*1000, [ylims(1, 2)-5 ylims(1, 2)-5], 'color', [.75 .75 .75], 'linewidth', 2.5)
    legend('no stim.')
    legend(gca, 'boxoff')
    title([T.cellNum T.cellCode])
    box off
    
    
    ha2=axes;
    set(ha2, 'xlim', [t(1) t(end)], 'ylim', ylims(2, :),'position',[0.2 0.55 0.7 0.15], 'nextplot', 'add', 'fontsize', 8, 'YAxisLocation', 'left');
    
    hbar=bar(tbin*1000, r_nostim, 'edgecolor', 'k', 'linewidth', 1, 'facecolor', 'flat', 'barwidth', 1)
    line([t(end)-600 t(end)-600], [2 12], 'color', 'k', 'linewidth', 1.5)
    
end;


ha3=axes;
set(ha3, 'unit', 'normalized', 'nextplot', 'add', 'position', [0.2 0.3 0.7 0.15], 'fontsize', 8, 'xlim', [t(1) t(end)], 'ylim', ylims(1, :));

plot(t, mean(medfilt1(vmstim, 40), 2), 'b'); hold on
if ~isempty(vmnostim)
    plot(t, mean(medfilt1(vmnostim, 40), 2), 'k');
end;
line([t(1) t(end)], [vbase vbase], 'color', 'k',  'linestyle', ':')

plot(t, aom(:, 1)/2+ylims(1, 2)-4, 'b'); hold off
line([pole_in pole_out]*1000, [ylims(1, 2)-9 ylims(1, 2)-9], 'color', [.75 .75 .75], 'linewidth', 2.5)

legend([num2str(stimfreq) 'Hz'])
legend(gca, 'boxoff')
box off
ylabel('mV')

ha4=axes;
set(ha4, 'unit', 'normalized', 'xlim', [t(1) t(end)], 'ylim', ylims(2, :),'position',[0.2 0.1 0.7 0.15], 'nextplot', 'add','fontsize', 8, 'YAxisLocation', 'left');

%     if ~isempty(vmnostim)
%         plot(tbin*1000, r_nostim,  'k')
%     end;
bar(tbin*1000, r, 'edgecolor', 'b', 'linewidth', 1, 'facecolor', 'flat', 'barwidth', 1)
ylabel('spk')
xlabel('ms')

%%
[pulsetrig.vm,pulsetrig.vmorg, pulsetrig.spk, pulsetrig.aom, pulsetrig.t, pulsetrig.miss]=triggeringvm(vmstim, aom, stimfreq, th, time, binsize, scalefac);


% colors={'c', 'r', 'm', 'g'};
colors='b'; 
hf2=figure;
set(hf2, 'units','centimeters','position', [1 3 6 12], 'paperpositionmode', 'auto')

ha=axes;
set(ha,'units', 'normalized','position',[.25 .1 .7 .175],'nextplot', 'add','yaxislocation','left', 'xlim', [-5 100],'ylim',[0 1000], 'fontsize', 8);
if length(stimfreq)==1
    set(ha, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);
end;
hbar=bar(pulsetrig.spk.ts, pulsetrig.spk.histos, colors, 'barwidth', 1);
set(hbar,  'edgecolor', 'k','facecolor', 'flat', 'linewidth', .5)
axis 'auto y'
xlabel('Time (ms)')
ylabel('Spikes/s')

aomavg=mean(pulsetrig.aom, 2);
hab=axes;
set(hab,'units', 'normalized','position',[.25 .1 .7 .175],'nextplot', 'add', 'xlim', [-5 100],  'ylim',[-1 10], 'fontsize', 8, 'color', 'none');
axis off
plot(pulsetrig.t, aomavg, 'k', 'linewidth', 1)
set(hab, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);

ha2=axes;
set(ha2,'units', 'normalized','position',[.25 .3 .7 .175], 'nextplot', 'add', 'xlim', [-5 100],'xtick', [], 'ylim', [-70 -50], 'fontsize', 8);

spktrig=pulsetrig.spk.spkall;
ntrs=size(spktrig, 2);
tspk=[0:size(spktrig, 1)-1]/Fs;
% 
if ntrs>100
    newinds=randperm(ntrs);
    newinds=newinds(1:100);
    spktrig=spktrig(:, newinds);
end;

set(ha2, 'ylim', [-5 1+min(ntrs, 100)]);

for k=1:size(spktrig, 2)
    if ~isempty(find(spktrig(:, k)))
        xx=[pulsetrig.t(find(spktrig(:, k))); pulsetrig.t(find(spktrig(:,k)))];
        yy=[k*ones(1, size(xx, 2)); k*ones(1, size(xx, 2))+0.5];
        plot(xx, yy, 'k');
    end;
end;

set(ha2, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);
ylabel ('Trials')

ha2b=axes;
set(ha2b,'units', 'normalized','position',[.25 .3 .7 .175],'nextplot', 'add', 'xlim', [-5 100],  'ylim',[-1 10], 'fontsize', 8, 'color', 'none');
axis off
plot(pulsetrig.t, aomavg, 'k', 'linewidth', 1)
set(ha2b, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);

ha3=axes;
set(ha3,'units', 'normalized','position',[.25 .55 .7 .175],'nextplot', 'add', 'xlim', [-5 100],  'ylim', ylims(1, :), 'fontsize', 8);
plot(pulsetrig.t, pulsetrig.vmorg, 'color', [0.75 0.75 0.75], 'linewidth', 0.5);
if size(pulsetrig.vm, 2)>=5
    randselect=randperm(size(pulsetrig.vm, 2)); randselect=randselect(1:5);
    colors=varycolor(5);
    for ii=1:5
        plot(pulsetrig.t, pulsetrig.vmorg(:, randselect(ii)), 'color', colors(ii, :), 'linewidth', 1);
    end;
end;

set(ha3, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);
ylabel('mV')

ha3b=axes;
set(ha3b,'units', 'normalized','position',[.25 .55 .7 .175],'nextplot', 'add', 'xlim', [-5 100],  'ylim',[-1 10], 'fontsize', 8, 'color', 'none');
axis off
plot(pulsetrig.t, aomavg, 'k', 'linewidth', 1)
set(ha3b, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);

ha4=axes;
set(ha4,'units', 'normalized','position',[.25 .75 .7 .175],'nextplot', 'add', 'xlim', [-5 100], 'xtick', [], 'ylim', ylims(1, :), 'fontsize', 8);
plot(pulsetrig.t, mean(pulsetrig.vm, 2), 'color', 'k', 'linewidth', 1.5);
axis 'auto y'
set(ha4, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);
ylabel ('mV')
ha4b=axes;
set(ha4b,'units', 'normalized','position',[.25 .75 .7 .175],'nextplot', 'add', 'xlim', [-5 100],  'ylim',[-1 10], 'fontsize', 8, 'color', 'none');
axis off
plot(pulsetrig.t, aomavg, 'k', 'linewidth', 1)
set(ha4b, 'xlim', [-5 min(trigrange, 1000/stimfreq)]);

ylabel('Vm (mV)')

% if ~s1
%     title([T.cellNum T.cellCode ':M1stim'])
% else
%     title([T.cellNum T.cellCode ':S1stim'])
% end;

ind_pre=find(pulsetrig.t<=5);

Vmpre=mean(pulsetrig.vm(ind_pre, :), 1);
Vmmean=mean(pulsetrig.vm, 2);

Vmmean=Vmmean(pulsetrig.t<=trigrange); % cut to certain range
Vmall=pulsetrig.vm([pulsetrig.t<=trigrange], :);

if ~hyp
    [Vpeak, indpeak]=max(Vmmean);
else
    [Vpeak, indpeak]=min(Vmmean);
end;

if pulsetrig.t(indpeak)<0
    indpeak=find(pulsetrig.t==15);
end;

axes(ha4);
% plot(pulsetrig.t(indpeak), Vpeak, 'ro')

Vmpeak=mean(Vmall([indpeak-25 indpeak+25], :), 1);
Vmdelta=Vmpeak-Vmpre;


hf3=figure;
set(hf3, 'units','centimeters','position', [1 3 5 10], 'paperpositionmode', 'auto')
ha=subplot(2, 1, 1);
set(ha, 'nextplot', 'add');
plot(Vmpre, Vmdelta, 'ko', 'markersize', 4);

pval=polyfit(Vmpre, Vmdelta, 1);
hold on
plot([min(Vmpre):0.1:max(Vmpre)], polyval(pval,[min(Vmpre):0.1:max(Vmpre)]), 'linestyle', '--', 'color', 'r');
line([min(Vmpre) max(Vmpre)], [0 0], 'linestyle', '--', 'color', 'k')
axis tight
xlabel('Vm base (mV)')
ylabel('Vm change (mV)')
title ('Vm dependence')

ha2=subplot(2, 1, 2)

set(ha2, 'nextplot', 'add');
plot(Vmpre, Vmpeak, 'ko', 'markersize', 4);

pval=polyfit(Vmpre, Vmpeak, 1);
hold on
plot([min(Vmpre):0.1:max(Vmpre)], polyval(pval,[min(Vmpre):0.1:max(Vmpre)]), 'linestyle', '--', 'color', 'r');
axis tight
xlabel('Vm base (mV)')
ylabel('Vm peak (mV)')

if tosave
    dat.stimfreq=stimfreq;
    dat.tvm=t;
    dat.vmnostim=vmnostim;
    dat.vmstim=vmstim;
    dat.tbin=tbin;
    dat.rnostim=r_nostim;
    dat.rstim=r;
    dat.pulsetrig=pulsetrig;
    
    set(hf2, 'userdata', dat);
    if ~s1
        
        if stimfreq>1
            saveas (hf, ['Vm_vs_stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf, ['Vm_vs_stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf2, ['Vmstimpulse' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf2, ['Vmstimpulse' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf3, ['Vm_dependence' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf3, ['Vm_dependence' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            
        else
            saveas (hf, ['Vm_vs_stim' 'const' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf, ['Vm_vs_stim' 'const' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf2, ['Vmstimpulse' 'const' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf2, ['Vmstimpulse' 'const' 'Scale' num2str(scalefac*100)], 'tif')
            
        end;
        
    else
        
        if stimfreq>1
            
            saveas (hf, ['Vm_vs_S1stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf, ['Vm_vs_S1stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf2, ['Vmstimpulse_S1' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf2, ['Vmstimpulse_S1' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf3, ['Vm_dependence_S1stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf3, ['Vm_dependence_S1stim' num2str(stimfreq) 'hz' 'Scale' num2str(scalefac*100)], 'tif')
            
        else
            saveas (hf, ['Vm_vs_S1stim' 'const' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf, ['Vm_vs_S1stim' 'const' 'Scale' num2str(scalefac*100)], 'tif')
            saveas (hf2, ['Vmstimpulse_S1' 'const' 'Scale' num2str(scalefac*100)], 'fig')
            saveas (hf2, ['Vmstimpulse_S1' 'const' 'Scale' num2str(scalefac*100)], 'tif')
        end;
        
    end;
    
end;

function [vm_pulsetrig, vm_pulsetrigorg spk_pulsetrig, aom_pulse, t_pulsetrig, vm_miss]=triggeringvm(vm, aom, freq, th, time, binsize, scalefac)

vm_pulsetrig=[];
vm_pulsetrigorg=[];
vm_miss=[];
spk_pulse=[];
t_pulsetrig=[-5*10:1000/freq*10]/10;
aom_pulse=[];

vmrmspk=sgolayfilt(removeAP(vm, 10000, th, 5), 3, 41);

for i=1:size(vm, 2)
    aomi=aom(:, i);
    
        above=find(aomi>scalefac*4);
        if ~isempty(above)
            aom_pulseon=above([1 ;1+find(diff(above)>1)]);
        end;
    
    if ~isempty(time)
        aom_pulseon=aom_pulseon(aom_pulseon<aom_pulseon(1)+time*10000);
    end;
    
    for j=1:length(aom_pulseon)
        ind=[aom_pulseon(j)-5*10:aom_pulseon(j)+(1000/freq)*10];
        
        vm_pulsetrig=[vm_pulsetrig vmrmspk(ind, i)];
        vm_pulsetrigorg=[vm_pulsetrigorg vm(ind, i)];
        spk_pulse=[spk_pulse spikespy(vm(ind, i), 10000, th, 4)];
        
        if isempty(find(spikespy(vm(ind, i), 10000, th, 4)));
            vm_miss=[vm_miss vm(ind, i)];
        end;
        aom_pulse=[aom_pulse aomi(ind)];
    end
end;

%  [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
[histos, ts]=spikehisto(spk_pulse, 10000, floor(size(spk_pulse, 1)/(10*binsize*1000)));
spk_pulsetrig.histos=histos;
spk_pulsetrig.ts=1000*(ts-0.005);
spk_pulsetrig.spkall=spk_pulse;

