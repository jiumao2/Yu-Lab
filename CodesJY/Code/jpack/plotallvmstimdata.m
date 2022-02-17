function plotallvmstimdata(cellnames)

% find out all the stim trials and no stim trials, AOM data, 
if nargin==0
    cellnames={'JY0158'};
end;

Ncell=length(cellnames);

vmcompare_onset=cell(1, Ncell);
vmcompare_offset=cell(1, Ncell);

for i=1:Ncell
    icellname=cellnames{i};
    load (['C:\Work\Projects\BehavingVm\Data\Vmdata\' icellname '\' 'whiskingvmout_2.mat'])
    
    vmnostim=mean(medfilt1(whiskingvmout.vm.nostim_all, 40), 2);
    vmstim=mean(medfilt1(whiskingvmout.vm.stim_all, 40), 2);
    
    aom_onset=[];
    aom_offset=[];
    
    vmstim_onarray=[];
    vmstim_offarray=[];
    t_onset=[-500:5000]/10;
    t_offset=[-1000:10000]/10;
    
    % AOM signal may vary, have to align Vm traces one by one
    for j=1:size(whiskingvmout.vm.aom, 2)
        aom_onset(j)=find(whiskingvmout.vm.aom(:, j)>=1, 1, 'first');
        aom_offset(j)=find(whiskingvmout.vm.aom(:,j)>=1, 1, 'last');
        
        ind_onset=[aom_onset(j)-500:aom_onset(j)+5000];
        ind_offset=[aom_offset(j)-1000:aom_offset(j)+10000];
        
        vmstim_j=medfilt1(whiskingvmout.vm.stim_all(:, j), 40);
        vmstim_onarray(:, j)=vmstim_j(ind_onset);
        vmstim_offarray(:, j)=vmstim_j(ind_offset);
        
        aom_onarray(:,j)=whiskingvmout.vm.aom(ind_onset, j);
        aom_offarray(:,j)=whiskingvmout.vm.aom(ind_offset, j);
    end;
    
    vmstim_onavg=mean(vmstim_onarray, 2);
    vmstim_offavg=mean(vmstim_offarray, 2);
    
    aom_onset=round(mean(aom_onset(j)));
    aom_offset=round(mean(aom_offset(j)));
    ind_onset=[aom_onset-500:aom_onset+5000];
    ind_offset=[aom_offset-1000:aom_offset+10000];
        
    vmcompare_onset{i}=[t_onset' vmnostim(ind_onset) vmstim_onavg vmstim_onavg-vmnostim(ind_onset) mean(aom_onarray, 2)];
    vmcompare_offset{i}=[t_offset' vmnostim(ind_offset) vmstim_offavg vmstim_offavg-vmnostim(ind_offset) mean(aom_offarray, 2)];
    
    clear  whiskingvmout
end;

vmcompare.cellnames=cellnames;
vmcompare.onset=vmcompare_onset;
vmcompare.offset=vmcompare_offset;

cd('C:\Work\Projects\BehavingVm\Data\Groupdata')
save vmstim_onoff vmcompare

figure;
for i=1:Ncell
    ton=vmcompare_onset{i}(:, 1);
    von(:, i)=medfilt1(vmcompare_onset{i}(:, 4), 20);
    
    toff=vmcompare_offset{i}(:, 1);
    voff(:, i)=medfilt1(vmcompare_offset{i}(:, 4), 20);
    
end;


subplot(2, 1, 1)
plot(ton, mean(von, 2));
set(gca, 'xlim', [ton(1) ton(end)])
xlabel ('ms')
ylabel('mV')

subplot(2, 1, 2)
plot(toff, mean(voff, 2))
set(gca, 'xlim', [toff(1) toff(end)])
xlabel('ms')
ylabel('mV')
