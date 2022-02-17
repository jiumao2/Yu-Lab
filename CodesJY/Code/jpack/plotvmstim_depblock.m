function plotvmstim_depblock(T, stimfreq, ylims,th,badtrials,time, toremove,  tosave)
ttrig=150;

if nargin<8
    tosave=0;
    if nargin<7
        toremove=[];
    if nargin<6
        time=[];
        if nargin<5
            badtrials=[];
            if nargin<4
                th=5;
                if nargin<3
                    s1=0;
                    if nargin<2
                        ylims=[-70 -20; 0 25];
                        if nargin<1
                            stimfreq=[10 20 50];
                        end;
                    end;
                end;
            end;f
        end;
    end;
end;
end;

% find stimulation frequency and corresponding Vm

ind_nostim=setdiff(setdiff(T.trialNums, T.stimtrialNums), badtrials);
vmnostim=findvmtrials(T, ind_nostim);
t=[0:size(vmnostim, 1)-1]/10;
tbin=[0:0.05:5.2];
r_nostim=T.PSTH(ind_nostim, tbin);

[ind, ind_conds] =findM1trials_depblock(T, 'depblock', stimfreq);
ind=ind([1 2 3  5])
ind_conds=ind_conds([1 2 3 5]); 
colors=['b', 'g', 'm', 'c'];
if ~isempty(toremove)
    [dum, istay]=setdiff(ind_conds, toremove); 
    ind=ind(istay);
    ind_conds=ind_conds(istay);
end;

for i=1:length(ind)
    ind{i}=setdiff(ind{i}, badtrials);
    if ~isempty(ind{i})
        [vmstim{i}, aom{i}]=findvmtrials(T, ind{i});
        r{i}=T.PSTH(ind{i}, tbin);
    end;
end;

tstim_index=[find(aom{1}(:, 1)>1, 1, 'first') : find(aom{1}(:, 1)>1, 1, 'last')];

hf=figure;
set(hf, 'units', 'centimeters','position', [5 3 12 18], 'paperpositionmode', 'auto')
vbase=mean(mean(medfilt1(vmnostim, 40), 2));



for i=1:4
    
    if i<=length(ind_conds)
    
    ha(i)=axes('units', 'normalized', 'position', [.15 0.25*(i-1)+0.06 0.7 0.18], 'fontsize', 8, 'xlim', [t(1) t(end)], 'ylim', ylims(1, :), 'nextplot', 'add');
    
    plot(t, mean(medfilt1(vmnostim, 40), 2), 'k', 'linewidth', 1);hold on
    line([t(1) t(end)], [vbase vbase], 'color', 'k', 'linestyle', ':')
    
    if ~isempty(vmstim{i})
        if ind_conds(i)==0
            plot(t, mean(medfilt1(vmstim{i}, 40), 2), 'b');
            plot(t, aom{i}(:, 1)/2+ylims(1, 2)-4, 'b', 'linewidth', 1);
        else
            plot(t, mean(medfilt1(vmstim{i}, 40), 2), colors(i), 'linewidth', 0.5);
            plot(t, aom{i}(:, 1)/2+ylims(1, 2)-4, colors(i));
            plot(t, aom{1}(:, 1)/2+ylims(1, 2)-4, 'b', 'linewidth', 1);
        end;
        
        [pulsetrig(i).vm, pulsetrig(i).spk, pulsetrig(i).aom, pulsetrig(i).t, pulsetrig(i).miss]=triggeringvm(vmstim{i}, aom{1}, stimfreq, th, time);
     
        % derive power spectrum of spikes or Vm
        
        vm_test=removeAP(vmstim{i}, 10000, th, 4);
        vm_test=medfilt1(detrend(vm_test(tstim_index, :)), 20);
         
        Vm_ft_stimfreq=mean(abs(ft(vm_test, stimfreq, 10000)), 2);
        
        params.Fs=10000;% 1000 Hz, frame rate
        params.fpass=[1 20];
        params.tapers=[3 5];
        params.trialave=1;
        params.err=[2 0.05];
        
        [S0, f, Serr]=mtspectrumc(vm_test, params);
        
        pulsetrig(i).Vm_ft_stimfreq=Vm_ft_stimfreq;
        pulsetrig(i).Vmpower=[f' S0];
        
    end;
     
    xlabel('ms')
    ylabel('mV')
    
    pole_in=T.pinDescentOnsetTimes(ind_nostim(1))+0.2;
    pole_out=T.pinAscentOnsetTimes(ind_nostim(1));
    
    line([pole_in pole_out]*1000, [ylims(1, 2)-10 ylims(1, 2)-10], 'color', [.75 .75 .75], 'linewidth', 2.5)
    legend('no stim.')
    legend(gca, 'boxoff')
    
    if i==5
    title([T.cellNum T.cellCode])
    end;
    box off
    
    ha2(i)=axes('unit', 'normalized', 'position', [.15 0.25*(i-1)+0.06 0.7 0.18], 'xlim', [t(1) t(end)], 'ylim', ylims(2, :), 'nextplot', 'add', 'xtick', [], 'fontsize', 8, 'YAxisLocation', 'right', 'color', 'none');
    
    plot(tbin*1000, r_nostim,  'k');

    if ~isempty(r{i})
        if ind_conds(i)==0
            plot(tbin*1000, r{i}, 'b')
        else
            plot(tbin*1000, r{i},  colors(i))
        end;
        
        spk_test=r{i}(tbin*1000>=t(tstim_index(1)) & tbin*1000<=t(tstim_index(end)));
        
        Spk_ft_stimfreq=abs(ft(spk_test', stimfreq, 1/(tbin(2)-tbin(1))));
        
        params.Fs=1/(tbin(2)-tbin(1));% 1000 Hz, frame rate
        params.fpass=[1 20];
        params.tapers=[3 5];
        params.trialave=1;
        params.err=[2 0.05];
        
        [S0, f, Serr]=mtspectrumc(spk_test', params);
        
        pulsetrig(i).Spk_ft_stimfreq=Spk_ft_stimfreq;
        pulsetrig(i).Spkpower=[f' S0];
        
    end;
    
    ylabel('Spk/s')
    
    end;
    
end;

hf2=figure;
set(hf2, 'units','centimeters','position', [1 3 10 10], 'paperpositionmode', 'auto');

ha3=axes;
set(ha3,'units', 'normalized','position',[.15 .1 .35 .35],'fontsize', 8, 'nextplot', 'add','yaxislocation','left', 'xlim', [-5 100],'ylim', ylims(2, :));
if length(stimfreq)==1 && stimfreq>10
    set(ha3, 'xlim', [-5 1000/stimfreq]);
else
    set(ha3, 'xlim', [-5 ttrig]);
end;

for i=1:length(ind);
    if ~isempty(ind{i})
        if ind_conds(i)==0
            plot(pulsetrig(i).spk.ts, pulsetrig(i).spk.histos,'b',  'linewidth', 1);
        else
            plot(pulsetrig(i).spk.ts, pulsetrig(i).spk.histos, 'color', colors(i),  'linewidth',1);
        end
    end;
end;

xlabel('Time (ms)')
ylabel('Spikes/s')

%% power spectrum

ha3b=axes;
set(ha3b,'units', 'normalized','position',[.6 .1 .35 .35],'fontsize', 8, 'nextplot', 'add','yaxislocation','left', 'xlim', [0 20],'ylim', [0 20]);

for i=1:length(ind);
    if ~isempty(ind{i})
        if ind_conds(i)==0
            plot(pulsetrig(i).Spkpower(:, 1), pulsetrig(i).Spkpower(:, 2),'b',  'linewidth', 1);
        else
            plot(pulsetrig(i).Spkpower(:, 1), pulsetrig(i).Spkpower(:, 2),  'color', colors(i),  'linewidth',1);
        end
    end;
end;

xlabel ('Frequency (Hz)')
ylabel('Spk power (Hz)')

axis 'auto y'

%% 

ha4=axes;
set(ha4, 'units', 'normalized', 'position',[.15 .6 .35 .35],'fontsize', 8,...
    'nextplot', 'add', 'xlim', [-5 100], 'ylim', [-70 -50]);

if length(stimfreq)==1 && stimfreq>10
    set(ha4, 'xlim', [-5 1000/stimfreq]);
else
    set(ha4, 'xlim', [-5 ttrig]);
end;
 
evokedPSP=zeros(1, length(ind));

thislegend={};
for i=1:length(ind)
    if ~isempty(ind{i})
        if ind_conds(i)==0
            plot(pulsetrig(i).t, mean(pulsetrig(i).vm, 2), 'b', 'linewidth', 1);
            evokedPSP(i)=max(mean(pulsetrig(i).vm, 2))-mean(mean(pulsetrig(i).vm(1:40, :), 2))
            thislegend=[thislegend 'M1Pulse'];
        else
            plot(pulsetrig(i).t, mean(pulsetrig(i).vm, 2) , 'color', colors(i), 'linewidth', 1);
             evokedPSP(i)=max(mean(pulsetrig(i).vm, 2))-mean(mean(pulsetrig(i).vm(1:40, :), 2));
            thislegend=[thislegend ['w/S1Cond' num2str(ind_conds(i))] ];
        end;
    end;
end;

evokedPSP

xlabel('Time (ms)')
ylabel ('mV')

axis 'auto y'

if size(ylims, 1)==3
    set(ha4, 'ylim', ylims(3, :));
end;

yrange=get(ha4, 'ylim');
aom=mean(pulsetrig(1).aom, 2)/4*(0.25*abs(diff(yrange)));
plot(pulsetrig(1).t, yrange(1)+aom+0.1, 'b', 'linewidth', 1.5)
title([T.cellNum T.cellCode])

axes(ha3)
plot(pulsetrig(1).t, 5*mean(pulsetrig(1).aom, 2)+0.1, 'b', 'linewidth', 1.5)

%%

ha4b=axes;
set(ha4b,'units', 'normalized','position',[.6 .6 .35 .35],'fontsize', 8, 'nextplot', 'add','yaxislocation','left', 'xlim', [0 20],'ylim', [0 10]);

for i=1:length(ind);
    if ~isempty(ind{i})
        if ind_conds(i)==0
            plot(pulsetrig(i).Vmpower(:, 1), pulsetrig(i).Vmpower(:, 2),'b',  'linewidth', 1);
        else
            plot(pulsetrig(i).Vmpower(:, 1), pulsetrig(i).Vmpower(:, 2),  'color', colors(i),  'linewidth',1);
        end
    end;
end;

xlabel ('Frequency (Hz)')
ylabel('Vm power (mV2/Hz)')

axis 'auto y'
hl=legend(thislegend);
set(hl, 'box', 'off', 'fontsize', 8)


%%
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

        saveas (hf, ['Vm_vs_stim_depblock' num2str(stimfreq) 'hz'], 'fig')
        saveas (hf, ['Vm_vs_stim_depblock' num2str(stimfreq) 'hz'], 'tif')
        saveas (hf2, ['Vmstimpulse_depblock' num2str(stimfreq) 'hz'], 'fig')
        saveas (hf2, ['Vmstimpulse_depblock' num2str(stimfreq) 'hz'], 'tif')
        
end;

function [vm_pulsetrig, spk_pulsetrig, aom_pulse, t_pulsetrig, vm_miss]=triggeringvm(vm, aom, freq, th, time)

vm_pulsetrig=[];
vm_miss=[];
spk_pulse=[];
t_pulsetrig=[-5*10:1000/freq*10]/10;
aom_pulse=[];

vmrmspk=sgolayfilt(removeAP(vm, 10000, th, 5), 3, 41);

for i=1:size(vm, 2)
    aomi=aom(:,1);
    
    if freq>1
    aom_pulseon=find(spikespy(aomi, 10000, 1, 7));
    else 
        aom_pulseon=find(aomi>1, 1, 'first');
    end;
    
    if ~isempty(time)
        aom_pulseon=aom_pulseon(aom_pulseon<aom_pulseon(1)+time*10000);
    end;
    
    for j=1:length(aom_pulseon)
        ind=[aom_pulseon(j)-5*10:aom_pulseon(j)+(1000/freq)*10];
        vm_pulsetrig=[vm_pulsetrig vmrmspk(ind, i)];
        spk_pulse=[spk_pulse spikespy(vm(ind, i), 10000, th, 4)];
        if isempty(find(spikespy(vm(ind, i), 10000, th, 4)));
            vm_miss=[vm_miss vm(ind, i)];
        end;
        aom_pulse=[aom_pulse aomi(ind)];
    end
end;

%  [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
[histos, ts]=spikehisto(spk_pulse, 10000, floor(size(spk_pulse, 1)/20));
spk_pulsetrig.histos=histos;
spk_pulsetrig.ts=1000*(ts-0.005);
spk_pulsetrig.spkall=spk_pulse;

