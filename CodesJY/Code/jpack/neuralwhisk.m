function neuralwhisk(dat, Tend, t0, ylims, md, tofilt, tosave, stimtrials, whiskamps, th)
% md: median filter
% dat is from program "plotwhiskervm"
set(0, 'DefaultAxesFontName', 'arial')
calci=1;

if nargin<10
    th=5;
    if nargin<9
        whiskamps=[0 2:4:20];
        if nargin<8
            stimtrials=[];
            if nargin<7
                tosave=0
                if nargin<6
                    tofilt=0
                    if nargin<5
                        md=0;
                        if nargin<4
                            ylims=[-75 -35];
                            if nargin<3
                                t0=0.1;
                                if nargin<2
                                    Tend=0.86;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

clim1=[-70 -50];
clim2=[0 40];

tvm=dat.tneural;
indtvm=find(tvm<=Tend);

if ~isempty(stimtrials)
    vm_stim=cell(1, 1);
    
    [c, istim, dum]=intersect(dat.hit_stim_nums, stimtrials);
    vm_stim=[vm_stim dat.neural_hit_stim(istim)];
    
    [c, istim, dum]=intersect(dat.cr_stim_nums, stimtrials);
    vm_stim=[vm_stim dat.neural_cr_stim(istim)];
    
    [c, istim, dum]=intersect(dat.fa_stim_nums, stimtrials);
    vm_stim=[vm_stim dat.neural_fa_stim(istim)];
    
    [c, istim, dum]=intersect(dat.miss_stim_nums, stimtrials);
    vm_stim=[vm_stim dat.neural_miss_stim(istim)];
    
    vm_stim=cell2mat(vm_stim);
    
else
    
    vm_stim=[dat.neural_hit_stim dat.neural_cr_stim dat.neural_fa_stim dat.neural_miss_stim]; vm_stim=cell2mat(vm_stim);
    
end;

vm_nostim=[dat.neural_hit_nostim dat.neural_cr_nostim dat.neural_fa_nostim dat.neural_miss_nostim]; vm_nostim=cell2mat(vm_nostim);

spk_stim=[];
spk_nostim=[];

spk_stim=spikespy(vm_stim, 10000, th,4);
spk_nostim=spikespy(vm_nostim, 10000,th,4);

figure;
ha=axes;
i=1;
% in='y';
while i<min (10, size(vm_stim, 2)-2)
    cla
    plot(vm_stim(:, 2+i)); hold on
    plot(find(spk_stim(:, 2+i)), vm_stim(find(spk_stim(:, 2+i)), 2+i), 'ro')
    i=i+1;
    pause
end;
% % 

if md
    vm_stim=medfilt1(vm_stim, 4*10, [], 1);
    vm_nostim=medfilt1(vm_nostim, 4*10, [], 1);
else
    vm_stim=removeAP(vm_stim, 10000, 4, 4);
    vm_nostim=removeAP(vm_nostim, 10000, 4, 4);
end;

tvm=tvm(indtvm);
vm_stim=vm_stim(indtvm, :);
vm_nostim=vm_nostim(indtvm, :);
spk_stim=spk_stim(indtvm, :);
spk_nostim=spk_nostim(indtvm, :);

nstim=size(vm_stim, 2);
nnostim=size(vm_nostim, 2);

twhisk=dat.twhisk;
indtwhisk=find(twhisk<=Tend);


if ~isempty(stimtrials)
    
      whiskamp_stimorg=[];
    [c, istim, dum]=intersect(dat.hit_stim_nums, stimtrials);
    whiskamp_stimorg=[whiskamp_stimorg dat.whisk_hit_stim.amp(:, istim)];
    
    [c, istim, dum]=intersect(dat.cr_stim_nums, stimtrials);
      whiskamp_stimorg=[whiskamp_stimorg dat.whisk_cr_stim.amp(:, istim)];
    
    [c, istim, dum]=intersect(dat.fa_stim_nums, stimtrials);
      whiskamp_stimorg=[whiskamp_stimorg dat.whisk_fa_stim.amp(:, istim)];
    
    [c, istim, dum]=intersect(dat.miss_stim_nums, stimtrials);
      whiskamp_stimorg=[whiskamp_stimorg dat.whisk_miss_stim.amp(:, istim)];
    
else

whiskamp_stimorg=[dat.whisk_hit_stim.amp dat.whisk_cr_stim.amp dat.whisk_fa_stim.amp dat.whisk_miss_stim.amp]; 

end;

whiskamp_nostimorg=[dat.whisk_hit_nostim.amp dat.whisk_cr_nostim.amp dat.whisk_fa_nostim.amp dat.whisk_miss_nostim.amp]; 

if tofilt
    [b, a]=butter(4, 5*2/1000, 'low');
    whiskamp_stim=filtfilt(b, a, whiskamp_stimorg);
    whiskamp_nostim=filtfilt(b, a, whiskamp_nostimorg);
else
    whiskamp_stim=whiskamp_stimorg;
    whiskamp_nostim=whiskamp_nostimorg;
end;

twhisk=twhisk(indtwhisk);
whiskamp_stim=whiskamp_stim(indtwhisk, :);
whiskamp_nostim=whiskamp_nostim(indtwhisk, :);

% lengths are all 850 ms long, laser turned on at 85 ms. start counting
% from 100 ms. 
% windows 100 ms, 100-200, 150-250, 200-300, ..., 750-850
%=
% t0=.1; % start from 100 ms

vmwin_stim=[];
spkwin_stim=[];
whiskwin_stim=[];

vmwin_nostim=[];
spkwin_nostim=[];
whiskwin_nostim=[];

% go through no stim trials first
twin=100;

while t0+twin/1000<=Tend-0.01
    
    [dum, ind1]=min(abs(twhisk-t0));
    ind1=[ind1:ind1+twin];
    whiskwin_nostim=[whiskwin_nostim whiskamp_nostim(ind1, :)];
    whiskwin_stim=[whiskwin_stim whiskamp_stim(ind1, :)];
    
    [dum, ind2]=min(abs(tvm-t0));
    ind2=[ind2:ind2+10*twin];
    
    vmwin_stim=[vmwin_stim vm_stim(ind2, :)];
    vmwin_nostim=[vmwin_nostim vm_nostim(ind2, :)];
    spkwin_stim=[spkwin_stim spk_stim(ind2, :)];
    spkwin_nostim=[spkwin_nostim spk_nostim(ind2, :)];
    
    t0=t0+0.05;
    
end;

if isfield(dat, 'poleonset')
 poleonset=dat.poleonset;
else
    poleonset=0.33';
end;
    
hf1=figure;
set(hf1, 'unit', 'centimeters', 'position', [2 2 8 12], 'paperpositionmode', 'auto','filename', 'vm_whisk_avg', 'name', dat.cellname)
subplot(2, 1, 1);
set(gca, 'xlim', [tvm(1) tvm(end)], 'ylim', [-50 -35], 'nextplot', 'add');

plot(tvm(2:end), mean(vm_nostim( 2:end, :), 2), 'k');
plot(tvm(2:end), mean(vm_stim(2:end, :), 2), 'b');
axis 'auto y'
ylim=get(gca, 'ylim');
plot(poleonset, ylim(2)-5, 'r*', 'markersize', 10)
name=dat.cellname;
title([name([17:end]) 'Vm'])


% also put aom
load('aom.mat')
taom=[0:length(aom)-1]/10000;
ylim2=get(gca, 'ylim');
aom=aom/5+ylim2(1)+0.5;
plot(taom, aom);

subplot(2, 1, 2)
plot(twhisk, mean(whiskamp_nostim, 2), 'k');
set(gca, 'xlim', [twhisk(1), twhisk(end)], 'nextplot', 'add');
plot(twhisk, mean(whiskamp_stim, 2), 'b');

title('Whisking amp')
axis 'auto y'
load('aom.mat')
taom=[0:length(aom)-1]/10000;
ylim2=get(gca, 'ylim');
aom=aom/5+ylim2(1)+0.5;
plot(taom, aom);
plot(poleonset, ylim2(2)-5, 'r*', 'markersize', 10)

%% Spikes 
hf11=figure;
set(hf11, 'unit', 'centimeters', 'position', [2 2 8 12], 'paperpositionmode', 'auto','filename', 'spk_whisk_avg', 'name', dat.cellname)
subplot(2, 1, 1);
set(gca, 'xlim', [tvm(1) tvm(end)], 'ylim', [-50 -35], 'nextplot', 'add');

[spkhisto_nostim, ts_nostim]=spikehisto(spk_nostim, 10000, round(Tend/0.025));
[spkhisto_stim, ts_stim]=spikehisto(spk_stim, 10000, round(Tend/0.025));

plot(ts_nostim, spkhisto_nostim, 'k');
plot(ts_stim, spkhisto_stim, 'b');

ylabel('Spks/s')
name=dat.cellname;
title([name([17:end]) 'Vm'])

% also put aom
load('aom.mat')
taom=[0:length(aom)-1]/10000;
ylim2=get(gca, 'ylim');
aom=aom/2-4;
plot(taom, aom);
axis 'auto y'

ylim=get(gca, 'ylim');
plot(poleonset, ylim(2)-5, 'r*', 'markersize', 10)

subplot(2, 1, 2)
plot(twhisk, mean(whiskamp_nostim, 2), 'k');
set(gca, 'xlim', [twhisk(1), twhisk(end)], 'nextplot', 'add');
plot(twhisk, mean(whiskamp_stim, 2), 'b');

title('Whisking amp')
axis 'auto y'
load('aom.mat')
taom=[0:length(aom)-1]/10000;
ylim2=get(gca, 'ylim');
aom=aom/5+ylim2(1)+0.5;
plot(taom, aom);

plot(poleonset, ylim2(2)-5, 'r*', 'markersize', 10)

%% 

% no stim

ind_lowwhisk_nostim=find(mean(whiskwin_nostim, 1)<=2);
ind_highwhisk_nostim=find(mean(whiskwin_nostim, 1)>5);

vm_nostim_avg=mean(vmwin_nostim, 1);
spk_nostim_avg=zeros(1, size(spkwin_nostim, 2));
for i=1:size(spkwin_nostim, 2)
    spk_nostim_avg(i)=numel(find(spkwin_nostim(:, i)))*1000/twin;
end;
vm_lowwhisk_nostim=vm_nostim_avg(ind_lowwhisk_nostim);
vm_highwhisk_nostim=vm_nostim_avg(ind_highwhisk_nostim);


spk_lowwhisk_nostim=spk_nostim_avg(ind_lowwhisk_nostim);
spk_highwhisk_nostim=spk_nostim_avg(ind_highwhisk_nostim);

% stim
ind_lowwhisk_stim=find(mean(whiskwin_stim, 1)<=2);
ind_highwhisk_stim=find(mean(whiskwin_stim, 1)>5);

vm_stim_avg=mean(vmwin_stim, 1);
spk_stim_avg=zeros(1, size(spkwin_stim, 2));
for i=1:size(spkwin_stim, 2)
    spk_stim_avg(i)=numel(find(spkwin_stim(:, i)))*1000/twin;
end;

vm_lowwhisk_stim=vm_stim_avg(ind_lowwhisk_stim);
vm_highwhisk_stim=vm_stim_avg(ind_highwhisk_stim);

spk_lowwhisk_stim=spk_stim_avg(ind_lowwhisk_stim);
spk_highwhisk_stim=spk_stim_avg(ind_highwhisk_stim);

%% plot Vm versus whisking
hf2=figure;    
set(hf2, 'unit', 'centimeters', 'position', [2 2 15 8], 'paperpositionmode', 'auto', 'filename', 'vm_whisk_win', 'name', dat.cellname)
subplot(1, 4, 1)
plot(mean(whiskwin_nostim, 1),  mean(vmwin_nostim, 1), 'k.');
hold on
plot(mean(whiskwin_stim, 1), mean(vmwin_stim, 1), 'b.');
hold off
xlabel('Whisking amplitude')
ylabel('Vm')
set(gca, 'xlim', [0 whiskamps(end)])
title([name([17:end]) 'Vm'])

subplot(1, 4, 3)
plot(0.5+rand(size(vm_lowwhisk_nostim)), vm_lowwhisk_nostim, 'k.');
hold on
plot(2.5+rand(size(vm_lowwhisk_stim)), vm_lowwhisk_stim, 'b.');
hold off
set(gca, 'xlim', [0 4], 'ylim', ylims)
title('Weak or no whisking')

dVm.lowwhisk=mean(vm_lowwhisk_stim)-mean(vm_lowwhisk_nostim);
p.low_whisking_vm=ranksum(vm_lowwhisk_nostim, vm_lowwhisk_stim);

subplot(1,4, 4)
plot(0.5+rand(size(vm_highwhisk_nostim)), vm_highwhisk_nostim, 'k.'); hold on
plot(2.5+rand(size(vm_highwhisk_stim)), vm_highwhisk_stim, 'b.'); hold off
set(gca, 'xlim', [0 4], 'ylim', ylims)
title('Whisking')
dVm.highwhisk=mean(vm_highwhisk_stim)-mean(vm_highwhisk_nostim)
p.high_whisking_vm=ranksum(vm_highwhisk_nostim, vm_highwhisk_stim)

p.length=Tend;

whiskwin_nostim_avg=mean(whiskwin_nostim, 1);
whiskwin_stim_avg=mean(whiskwin_stim, 1);

pmean=zeros(1, length(whiskamps)-1);

for i=1:length(whiskamps)-1
      
    ind_nostim=find(whiskwin_nostim_avg>=whiskamps(i) & whiskwin_nostim_avg<whiskamps(i+1));      
    vm_whiskamp_nostim_avg(i)=mean(vm_nostim_avg(ind_nostim));
    if calci
        if any(ind_nostim) && length(ind_nostim)>5
        vm_whiskamp_nostim_ci(:, i)=bootci(1000, @mean, vm_nostim_avg(ind_nostim));
        else
            vm_whiskamp_nostim_ci(:, i)=NaN;
        end;
    else
        vm_whiskamp_nostim_std(i)=std(vm_nostim_avg(ind_nostim));
    end;
    
    ind_stim=find(whiskwin_stim_avg>=whiskamps(i) & whiskwin_stim_avg<whiskamps(i+1));
    
    vm_whiskamp_stim_avg(i)=mean(vm_stim_avg(ind_stim));
    
        if calci
        if any(ind_stim) && length(ind_stim)>5
        vm_whiskamp_stim_ci(:, i)=bootci(1000, @mean, vm_stim_avg(ind_stim));
        else
            vm_whiskamp_stim_ci(:, i)=NaN;
        end;
    else
        vm_whiskamp_stim_std(i)=std(vm_stim_avg(ind_stim));
    end;
    
    
     whiskampsmid(i)=mean([whiskamps(i) whiskamps(i+1)]);
    
    pmean(i)=ranksum(vm_nostim_avg(ind_nostim), vm_stim_avg(ind_stim));
    
end;

subplot(1, 4, 2)

if ~calci
errorbar(whiskampsmid, vm_whiskamp_nostim_avg, vm_whiskamp_nostim_std, 'color', 'k', 'linewidth', 1.5);
hold on
errorbar(whiskampsmid, vm_whiskamp_stim_avg, vm_whiskamp_stim_std, 'color', 'b', 'linewidth', 1.5);
hold off
set(gca, 'xlim', [0 whiskamps(end)]);

else
    
   plot(whiskampsmid, vm_whiskamp_nostim_avg, 'color', 'k', 'linewidth', 1.5);
    
    hold on
    plot([whiskampsmid; whiskampsmid] , vm_whiskamp_nostim_ci, 'k-', 'linewidth', 1.5);
    plot(whiskampsmid, vm_whiskamp_stim_avg, 'color', 'b', 'linewidth', 1.5);
  
    plot([whiskampsmid; whiskampsmid], vm_whiskamp_stim_ci, 'b-', 'linewidth', 1.5);
    hold off
    set(gca, 'xscale', 'linear', 'xlim', [0 whiskamps(end)])

end;

p.pmean_vm=pmean

set(hf2, 'userdata', p)

%% whisking versus spikes
hf22=figure;    
set(hf22, 'unit', 'centimeters', 'position', [2 2 15 8], 'paperpositionmode', 'auto', 'filename', 'vm_whisk_win', 'name', dat.cellname)
subplot(1, 4, 1)
plot(mean(whiskwin_nostim, 1),  spk_nostim_avg, 'k.');
hold on
plot(mean(whiskwin_stim, 1), spk_stim_avg, 'b.');
hold off
xlabel('Whisking amplitude')
ylabel('Spk/s')
set(gca, 'xlim', [0 whiskamps(end)])
title([name([17:end]) 'Vm'])

subplot(1, 4, 3)
plot(0.5+rand(size(spk_lowwhisk_nostim)), spk_lowwhisk_nostim, 'k.');
hold on
plot(2.5+rand(size(spk_lowwhisk_stim)), spk_lowwhisk_stim, 'b.');
hold off
set(gca, 'xlim', [0 4], 'ylim',[0 40])
title('Weak or no whisking')

dVm.lowwhisk=mean(spk_lowwhisk_stim)-mean(spk_lowwhisk_nostim);
p.low_whisking_spikes=ranksum(spk_lowwhisk_nostim, spk_lowwhisk_stim);

subplot(1,4, 4)
plot(0.5+rand(size(spk_highwhisk_nostim)), spk_highwhisk_nostim, 'k.'); hold on
plot(2.5+rand(size(spk_highwhisk_stim)), spk_highwhisk_stim, 'b.'); hold off
set(gca, 'xlim', [0 4], 'ylim', [0 40])
title('Whisking')
dspk.highwhisk=mean(spk_highwhisk_stim)-mean(spk_highwhisk_nostim)
p.high_whisking_spikes=ranksum(spk_highwhisk_nostim, spk_highwhisk_stim)

p.length=Tend;


whiskwin_nostim_avg=mean(whiskwin_nostim, 1);
whiskwin_stim_avg=mean(whiskwin_stim, 1);

pmean=zeros(1, length(whiskamps)-1);

for i=1:length(whiskamps)-1
      
    ind_nostim=find(whiskwin_nostim_avg>=whiskamps(i) & whiskwin_nostim_avg<whiskamps(i+1));      
    spk_whiskamp_nostim_avg(i)=mean(spk_nostim_avg(ind_nostim));
    if calci
        if any(ind_nostim) && length(ind_nostim)>5
        spk_whiskamp_nostim_ci(:, i)=bootci(1000, @mean, spk_nostim_avg(ind_nostim));
        else
            spk_whiskamp_nostim_ci(:, i)=NaN;
        end;
    else
        spk_whiskamp_nostim_std(i)=std(spk_nostim_avg(ind_nostim));
    end;
    
    ind_stim=find(whiskwin_stim_avg>=whiskamps(i) & whiskwin_stim_avg<whiskamps(i+1));
    
    spk_whiskamp_stim_avg(i)=mean(spk_stim_avg(ind_stim));
    
        if calci
        if any(ind_stim) && length(ind_stim)>5
        spk_whiskamp_stim_ci(:, i)=bootci(1000, @mean, spk_stim_avg(ind_stim));
        else
            spk_whiskamp_stim_ci(:, i)=NaN;
        end;
    else
        spk_whiskamp_stim_std(i)=std(spk_stim_avg(ind_stim));
    end;
    
    
    whiskampsmid(i)=mean([whiskamps(i) whiskamps(i+1)]);
    
    pmean(i)=ranksum(spk_nostim_avg(ind_nostim), spk_stim_avg(ind_stim));
    
end;

subplot(1, 4, 2)

if ~calci
errorbar(whiskampsmid, s_whiskamp_nostim_avg, spk_whiskamp_nostim_std, 'color', 'k', 'linewidth', 1.5);
hold on
errorbar(whiskampsmid, spk_whiskamp_stim_avg, spk_whiskamp_stim_std, 'color', 'b', 'linewidth', 1.5);
hold off
set(gca, 'xlim', [0 whiskamps(end)]);

else
    
   plot(whiskampsmid, spk_whiskamp_nostim_avg, 'color', 'k', 'linewidth', 1.5);
    
    hold on
    plot([whiskampsmid; whiskampsmid] , spk_whiskamp_nostim_ci, 'k-', 'linewidth', 1.5);
    plot(whiskampsmid, spk_whiskamp_stim_avg, 'color', 'b', 'linewidth', 1.5);
  
    plot([whiskampsmid; whiskampsmid], spk_whiskamp_stim_ci, 'b-', 'linewidth', 1.5);
    hold off
    set(gca, 'xscale', 'linear', 'xlim', [0 whiskamps(end)])

end;

p.pmean_spikes=pmean

set(hf2, 'userdata', p)
%%

hf3=figure;    
set(hf3, 'unit', 'centimeters', 'position', [6 2 10 8], 'paperpositionmode', 'auto', 'filename', 'vm_whisk_win', 'name', dat.cellname)
subplot(1,2, 1)
plot(mean(whiskwin_nostim, 1),  std(vmwin_nostim), 'k.');
hold on
plot(mean(whiskwin_stim, 1), std(vmwin_stim), 'b.');
hold off
xlabel('Whisking amplitude')
ylabel('Var Vm')
set(gca, 'xlim', [0 whiskamps(end)])
title([name([17:end]) 'Vm'])


pvar=zeros(1, length(whiskamps)-1);
whiskwin_nostim_avg=mean(whiskwin_nostim, 1);
whiskwin_stim_avg=mean(whiskwin_stim, 1);

vm_nostim_var=std(vmwin_nostim);
vm_stim_var=std(vmwin_stim);

for i=1:length(whiskamps)-1
      
    ind_nostim=find(whiskwin_nostim_avg>=whiskamps(i) & whiskwin_nostim_avg<whiskamps(i+1));      
    vm_whiskamp_nostim_var(i)=mean(vm_nostim_var(ind_nostim));
    if calci
        if any(ind_nostim) && length(ind_nostim)>5
        vm_whiskamp_nostim_ci(:, i)=bootci(1000, @mean, vm_nostim_var(ind_nostim));
        else
            vm_whiskamp_nostim_ci(:, i)=NaN;
        end;
    else
        vm_whiskamp_nostim_std(i)=std(vm_nostim_avg(ind_nostim));
    end;
    
    ind_stim=find(whiskwin_stim_avg>=whiskamps(i) & whiskwin_stim_avg<whiskamps(i+1));
    
    vm_whiskamp_stim_var(i)=mean(vm_stim_var(ind_stim));
    
        if calci
        if any(ind_stim) && length(ind_stim)>5
        vm_whiskamp_stim_ci(:, i)=bootci(1000, @mean, vm_stim_var(ind_stim));
        else
            vm_whiskamp_stim_ci(:, i)=NaN;
        end;
    else
        vm_whiskamp_stim_std(i)=std(vm_stim_avg(ind_stim));
    end;
    
    whiskampsmid(i)=mean([whiskamps(i) whiskamps(i+1)]);
    
    pvar(i)=ranksum(vm_nostim_var(ind_nostim), vm_stim_var(ind_stim));
    
end;

subplot(1, 2, 2)

if ~calci
errorbar(whiskampsmid, vm_whiskamp_nostim_var, vm_whiskamp_nostim_std, 'color', 'k', 'linewidth', 1.5);
hold on
errorbar(whiskampsmid, vm_whiskamp_stim_var, vm_whiskamp_stim_std, 'color', 'b', 'linewidth', 1.5);
hold off
set(gca, 'xlim', [0 whiskamps(end)]);

else
    
   plot(whiskampsmid, vm_whiskamp_nostim_var, 'color', 'k', 'linewidth', 1.5);
    
    hold on
    plot([whiskampsmid; whiskampsmid] , vm_whiskamp_nostim_ci, 'k-', 'linewidth', 1.5);
    plot(whiskampsmid, vm_whiskamp_stim_var, 'color', 'b', 'linewidth', 1.5);
    plot([whiskampsmid; whiskampsmid], vm_whiskamp_stim_ci, 'b-', 'linewidth', 1.5);
    hold off
    set(gca, 'xscale', 'linear', 'xlim', [0 whiskamps(end)])

end;

pvar

set(hf3, 'userdata', pvar)
if tosave
    
    saveas(hf1, ['vm_whisk_avg' '_wid' num2str(dat.whiskid)],'tif')
    saveas(hf2, ['vm_whisk_win' '_wid' num2str(dat.whiskid)],'tif')
    saveas(hf1, ['vm_whisk_avg' '_wid' num2str(dat.whiskid)],'fig')
    saveas(hf2, ['vm_whisk_win' '_wid' num2str(dat.whiskid)],'fig')
    
        
    saveas(hf11, ['spk_whisk_avg' '_wid' num2str(dat.whiskid)],'tif')
    saveas(hf22, ['spk_whisk_win' '_wid' num2str(dat.whiskid)],'tif')
    saveas(hf11, ['spk_whisk_avg' '_wid' num2str(dat.whiskid)],'fig')
    saveas(hf22, ['spk_whisk_win' '_wid' num2str(dat.whiskid)],'fig')
    
    
    
end;



