function whiskingepochstim(T, dataout, trange, vrange, md,whiskamps, th, showspikes, notouch, whisk_th, tosave);

% use Dan's T.detectWhiskingEpochs to classify whisking epochs, then get
% 2013, JY
% the Vm.
% after that, summerize Vm, amplitude, etc.
if nargin<11
    tosave=1;
    if nargin<10
        whisk_th=12;
        if nargin<9
            notouch=0;
            if nargin<8
                showspikes=0;
                if nargin<7
                    th=8;
                end;
            end;
        end;
    end;
end;

switch notouch
    case 0
        selected_trialnums=[dataout.hit_nostim_nums dataout.hit_stim_nums dataout.cr_nostim_nums dataout.cr_stim_nums dataout.fa_nostim_nums dataout.fa_stim_nums dataout.miss_nostim_nums dataout.miss_stim_nums];
    case 1
        selected_trialnums=[dataout.cr_nostim_nums dataout.cr_stim_nums dataout.fa_nostim_nums dataout.fa_stim_nums];
    case 2
        selected_trialnums=[dataout.hit_nostim_nums dataout.hit_stim_nums dataout.cr_nostim_nums dataout.cr_stim_nums   dataout.miss_nostim_nums dataout.miss_stim_nums dataout.fa_nostim_nums dataout.fa_stim_nums];  
end;

whisking_th=55;
nonwhisking_th=25;

epoch_dur=50;

[whisking_epochs, nonwhisking_epochs]=T.detectWhiskingEpochs(1, selected_trialnums, [whisking_th nonwhisking_th], 31, epoch_dur);

hfs=figure;
set(gcf, 'unit', 'centimeters', 'position', [2 2 10 20], 'paperpositionmode', 'auto')

K=randperm(length(selected_trialnums));
for k=1:5
    subplot(5, 1, k)
    i=K(k);
    [wpos, tw]=T.get_whisker_position(dataout.whiskid, selected_trialnums(i));
    
    tw=cell2mat(tw); wpos=cell2mat(wpos);
    line([trange(1) trange(1)], [min(wpos) max(wpos)], 'linestyle', '--', 'color', 'c', 'linewidth', 2);  hold on;
     line([trange(2) trange(2)], [min(wpos) max(wpos)], 'linestyle', '--', 'color', 'c', 'linewidth', 2);

    plot(tw, wpos); 
    
    wei=whisking_epochs{i};
    for ii=1:size(wei, 1)
        plot(tw(tw>=wei(ii, 1) & tw<=wei(ii, 2)), wpos(tw>=wei(ii, 1) & tw<=wei(ii, 2)), 'r.');
    end;
    
    nwei=nonwhisking_epochs{i};
    for ii=1:size(nwei, 1)
        plot(tw(tw>=nwei(ii, 1) & tw<=nwei(ii, 2)), wpos(tw>=nwei(ii, 1) & tw<=nwei(ii, 2)), 'k.');
    end;
    
    axis tight
    
end;

xlabel('sec'); ylabel ('whisk pos')

vmnostim_whisking_epochs={};
vmnostim_nonwhisking_epochs={};
vmstim_whisking_epochs={};
vmstim_nonwhisking_epochs={};

vmnostim_whisk_avg=[];
vmnostim_nonwhisk_avg=[];
vmstim_whisk_avg=[];
vmstim_nonwhisk_avg=[];

spknostim_whisk_avg=[];
spknostim_nonwhisk_avg=[];
spkstim_whisk_avg=[];
spkstim_nonwhisk_avg=[];

whiskamps_whiskstim_avg=[];
whiskamps_nonwhiskstim_avg=[];
whiskamps_whisknostim_avg=[];
whiskamps_nonwhisknostim_avg=[];

allstimtrials=T.stimtrialNums;

twhisk=[0:1/1000:4.999];

firstcontact=[];

vm_nostim_all=[];
vm_stim_all=[];
aom_all=[];

whiskamp_nostim_all=[];
whiskamp_stim_all=[];
t_contact=[];
touch_trial=[];
wid_contact=[];

stimtrialnums=[];
nostimtrialnums=[];

for i=1:length(selected_trialnums)
    if notouch==2
        tids=T.trials{T.trialNums==selected_trialnums(i)}.whiskerTrial. trajectoryIDs;
        t_contact_iw=[];
        wid_contact_iw=[];
        for iw=1:length(tids)
            r=T.detectFirstContacts(tids(iw), selected_trialnums(i), whisk_th);
            if ~isempty(cell2mat(r))
                t_contact_iw=[t_contact_iw cell2mat(r)];
                wid_contact_iw=[wid_contact_iw tids(iw)];
            end;
        end;

        [t_contact, ind_contact]=min(t_contact_iw);
        wid_contact=[wid_contact wid_contact_iw(ind_contact)];
        
        [selected_trialnums(i) t_contact];
        firstcontact=[firstcontact t_contact];
        if ~isempty(t_contact)
            touch_trial=[touch_trial selected_trialnums(i)];
        end;
        t_contact=t_contact-0.005; % subtract 5ms for more conservative estimate
    end;
    twhisk=[0:1/1000:4.999];
    [wpos, tw]=T.get_whisker_position(dataout.whiskid, selected_trialnums(i));
   
    whisk_params=whiskdecomposej(wpos, tw, twhisk);
    
    twhisk=twhisk+0.01;
    
    tri=selected_trialnums(i);
    vm_tn=T.trials{T.trialNums==tri}.spikesTrial.rawSignal;
    tvm=[0:length(vm_tn)-1]/10000;

    spk_tn=spikespy(vm_tn, 10000, th, 4);

    if showspikes
    figure(30); clf(30)
    if rem(i, 5)==0 && ~isempty(find(spk_tn))
    plot(tvm, vm_tn);
    hold on
    plot(tvm(find(spk_tn)), vm_tn(find(spk_tn)), 'or');
    pause
    end;
    end;
    
    vm_tn_org=vm_tn;
    
    if ~md
    vm_tn=removeAP(vm_tn, 10000, th, 4);
    else
        vm_tn=medfilt1(vm_tn, 10*8); % good for removing bursts
    end;
   
    whisking_epochs_tn=whisking_epochs{i};
    n_whisking_epochs_tn=size(whisking_epochs_tn, 1);
    
    nonwhisking_epochs_tn=nonwhisking_epochs{i};
    n_nonwhisking_epochs_tn=size(nonwhisking_epochs_tn, 1);
    
    if any(intersect(tri, allstimtrials))
        % so it belongs to a stim trial
        stimtrialnums=[stimtrialnums tri];
        [vm_tri, aom]=findvmtrials(T, tri);
        aom_all=[aom_all aom];
        vm_stim_all=[vm_stim_all vm_tri];
        whiskamp_stim_all=[whiskamp_stim_all whisk_params.amp];
        
        if n_whisking_epochs_tn>0
            for j=1:n_whisking_epochs_tn
                
                t1=max([whisking_epochs_tn(j, 1), trange(1)]);
                
                if notouch==2 && ~isempty(t_contact)
                    t2=min([whisking_epochs_tn(j, 2), trange(2) t_contact]);
                else
                    t2=min([whisking_epochs_tn(j, 2), trange(2)]);
                end;
                
                if t2>t1+0.01
                    
                    vmstim_whisking_epochs=[vmstim_whisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmstim_whisk_avg=[vmstim_whisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spkstim_whisk_avg=[spkstim_whisk_avg length(find(spk_tn(tvm>=t1 & tvm<=t2)))/(t2-t1)];
                    whiskamps_whiskstim_avg=[whiskamps_whiskstim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                    
                end;
                
            end;
        end;
        
        if n_nonwhisking_epochs_tn>0
            for j=1:n_nonwhisking_epochs_tn
                
                t1=max([nonwhisking_epochs_tn(j, 1), trange(1)]);
                t2=min([nonwhisking_epochs_tn(j, 2), trange(2)]);
         
                if t2>t1+0.01
                    
                    vmstim_nonwhisking_epochs=[vmstim_nonwhisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmstim_nonwhisk_avg=[vmstim_nonwhisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spkstim_nonwhisk_avg=[spkstim_nonwhisk_avg length(find(spk_tn(tvm>=t1 & tvm<=t2)))/(t2-t1)];
                    whiskamps_nonwhiskstim_avg=[whiskamps_nonwhiskstim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                end;
            end;
        end;
    else
        % so it belongs to a nonstim trial
        nostimtrialnums=[nostimtrialnums tri];
        [vm_tri, aom]=findvmtrials(T, tri);
        vm_nostim_all=[vm_nostim_all vm_tri];
        whiskamp_nostim_all=[whiskamp_nostim_all whisk_params.amp];
        
        if n_whisking_epochs_tn>0
            for j=1:n_whisking_epochs_tn
                
                t1=max([whisking_epochs_tn(j, 1), trange(1)]);
                t2=min([whisking_epochs_tn(j, 2), trange(2)]);
                
                if t2>t1+0.01
                
                    vmnostim_whisking_epochs=[vmnostim_whisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmnostim_whisk_avg=[vmnostim_whisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spknostim_whisk_avg=[spknostim_whisk_avg length(find(spk_tn(tvm>=t1 & tvm<=t2)))/(t2-t1)];
                    whiskamps_whisknostim_avg=[whiskamps_whisknostim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                    
                end;
            end;
        end;
        
        if n_nonwhisking_epochs_tn>0
            for j=1:n_nonwhisking_epochs_tn
              
                t1=max([nonwhisking_epochs_tn(j, 1), trange(1)]);
                t2=min([nonwhisking_epochs_tn(j, 2), trange(2)]);
         
                if t2>t1+0.01
                    vmnostim_nonwhisking_epochs=[vmnostim_nonwhisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmnostim_nonwhisk_avg=[vmnostim_nonwhisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spknostim_nonwhisk_avg=[spknostim_nonwhisk_avg length(find(spk_tn(tvm>=t1 & tvm<=t2)))/(t2-t1)];
                    whiskamps_nonwhisknostim_avg=[whiskamps_nonwhisknostim_avg mean(whisk_params.amp(twhisk>=t1& twhisk<=t2))];

                end;
            end;
        end;
        
    end
    
end;

if notouch==2
    hfcontact=figure;
    set(hfcontact, 'paperpositionmode', 'auto', 'units', 'centimeters', 'position', [5 2 8 8]);
    ha=axes;
    hist(firstcontact, 50);
    xlabel('touch time (s)')
    ylabel('count')
end;

hf_avg=figure;
set(hf_avg, 'units', 'centimeters', 'position', [4 4 10 18], 'paperpositionmode', 'auto')

ha_whisk=subplot(3, 1, 1)
set(ha_whisk,'xlim', [tvm(1) tvm(end)], 'nextplot', 'add', 'fontsize', 8)
plot(twhisk, mean(whiskamp_nostim_all, 2), 'k');
plot(twhisk, mean(whiskamp_stim_all, 2), 'b');
set(gca, 'xtick', [])
ylabel('whisk amp (deg)')
legend('no stim', 'stim')
set(hf_avg, 'paperpositionmode', 'auto','units', 'centimeters', 'position', [5, 2, 8  16]);
ha_avg=subplot(3, 1, 2);
set(ha_avg,'xlim', [tvm(1) tvm(end)], 'nextplot', 'add', 'fontsize', 8)
plot(tvm, mean(removeAP(vm_nostim_all, 10000, th, 4), 2), 'k');
plot(tvm, mean(removeAP(vm_stim_all,10000, th, 4), 2), 'b');
axis 'auto y'
ylim=get(ha_avg, 'ylim');
plot(tvm,  aom_all(:, 1)/2+ylim(1)-2, 'b')
plot(dataout.poleonset, ylim(2)-5, 'r*', 'markersize', 8)
xlabel('Time (s)')
ylabel('Vm (mV)')
ha_avg=subplot(3, 1, 3);
set(ha_avg,'xlim', [tvm(1) tvm(1)+1], 'nextplot', 'add', 'fontsize', 8)
plot(tvm, mean(removeAP(vm_nostim_all, 10000, th, 4), 2), 'k');
plot(tvm, mean(removeAP(vm_stim_all,10000, th, 4), 2), 'b');
axis 'auto y'
ylim=get(ha_avg, 'ylim');
plot(tvm, aom_all(:, 1)/2+ylim(1)-2, 'b')
plot(dataout.poleonset, ylim(2)-2, 'r*', 'markersize', 8)
xlabel('Time (s)')
ylabel('Vm (mV)')
legend('no stim', 'stim')

hf1=figure;
set(gcf, 'units', 'centimeters', 'position', [4 4 25 10], 'paperpositionmode', 'auto');
subplot(2, 3, 1)
[n1,x1]=hist(vmnostim_nonwhisk_avg, linspace(vrange(1), vrange(2), 50));
set(gca, 'xlim', vrange, 'nextplot', 'add');
bar(x1, n1,  'k', 'edgecolor', 'k')
title(['no stim, nonwhisking(1), ' sprintf('%0.1f',median(vmnostim_nonwhisk_avg))])

subplot(2, 3, 4)
[n2,x2]=hist(vmstim_nonwhisk_avg, linspace(vrange(1), vrange(2), 50));
set(gca, 'xlim', vrange, 'nextplot', 'add');
bar(x2, n2,  'b', 'edgecolor', 'b')

title(['stim, nonwhisking (2), ' sprintf('%0.1f',median(vmstim_nonwhisk_avg))])
xlabel('mV')
ylabel('count')
data.pvm_nonwhisking=ranksum(vmnostim_nonwhisk_avg, vmstim_nonwhisk_avg);
data.dVm_nonwhisking=median(vmstim_nonwhisk_avg)-median(vmnostim_nonwhisk_avg);

subplot(2, 3, 2)
[n3,x3]=hist(vmnostim_whisk_avg, linspace(vrange(1), vrange(2), 50));
set(gca, 'xlim', vrange, 'nextplot', 'add');
bar(x3, n3,  'k', 'edgecolor', 'k')
title(['no stim, whisking(3), ' sprintf('%0.1f',median(vmnostim_whisk_avg))])

subplot(2, 3, 5)
[n4,x4]=hist(vmstim_whisk_avg, linspace(vrange(1), vrange(2), 50));
set(gca, 'xlim', vrange, 'nextplot', 'add');
bar(x4, n4,  'b', 'edgecolor', 'b')
title(['stim, whisking(4), ' sprintf('%0.1f',median(vmstim_whisk_avg))])

data.pvm_whisking=ranksum(vmnostim_whisk_avg, vmstim_whisk_avg);
data.dVm_whisking=median(vmstim_whisk_avg)-median(vmnostim_whisk_avg);

stat_vm.whisking_nonwhisking=data

set (gcf, 'userdata', data)
subplot(2, 3, [3 6])
set(gca, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vrange)

boxplot([vmnostim_nonwhisk_avg vmstim_nonwhisk_avg vmnostim_whisk_avg vmstim_whisk_avg],...
    [ones(size(vmnostim_nonwhisk_avg)) 2*ones(size(vmstim_nonwhisk_avg)) 3*ones(size(vmnostim_whisk_avg)) 4*ones(size(vmstim_whisk_avg))],...
    'colors', 'kbkb');
xlabel('conditions')
ylabel ('mV')
hf11=figure;
set(hf11, 'units', 'centimeters', 'position', [4 4 8 6], 'paperpositionmode', 'auto')
set(gca, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vrange)

boxplot([spknostim_nonwhisk_avg spkstim_nonwhisk_avg spknostim_whisk_avg spkstim_whisk_avg],...
    [ones(size(spknostim_nonwhisk_avg)) 2*ones(size(spkstim_nonwhisk_avg)) 3*ones(size(spknostim_whisk_avg)) 4*ones(size(spkstim_whisk_avg))],...
    'colors', 'kbkb');

data=[];
data.pspk_nonwhisking=ranksum(spknostim_nonwhisk_avg, spkstim_nonwhisk_avg);
data.dspk_nonwhisking=mean(spkstim_nonwhisk_avg)-mean(spknostim_nonwhisk_avg);
data.pspk_whisking=ranksum(spknostim_whisk_avg, spkstim_whisk_avg);
data.dspk_whisking=mean(spkstim_whisk_avg)-mean(spknostim_whisk_avg);
stat_spk.whisking_nonwhisking=data
set (gcf, 'userdata',data)
xlabel('Conditions')
ylabel('Firing rate')

hf2=figure;
set(gcf, 'units', 'centimeters', 'position', [4 4 12 6], 'paperpositionmode', 'auto');

ha1=subplot(1, 2, 1);
set(ha1, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)], 'ylim', vrange);
xlabel ('Whisking amp'); ylabel('Vm')
nostim_vm=[vmnostim_whisk_avg vmnostim_nonwhisk_avg];
stim_vm=[vmstim_whisk_avg vmstim_nonwhisk_avg];

nostim_whiskamp=[whiskamps_whisknostim_avg whiskamps_nonwhisknostim_avg];
stim_whiskamp=[whiskamps_whiskstim_avg whiskamps_nonwhiskstim_avg];

plot(nostim_whiskamp, nostim_vm, 'ko');
plot(stim_whiskamp, stim_vm, 'bo');

axis 'auto y'

ha2=subplot(1, 2, 2);
set(ha2, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)], 'ylim', vrange);
% bin the whisking amplitudes
xlabel('Whisking amp'); ylabel ('Vm')

pmean=[];
for i=1:length(whiskamps)-1
    
    ind_nostim=find(nostim_whiskamp>=whiskamps(i) & nostim_whiskamp<whiskamps(i+1));
    vm_whiskamp_nostim_avg(i)=mean(nostim_vm(ind_nostim));
    
    if any(ind_nostim) && length(ind_nostim)>5
        vm_whiskamp_nostim_ci(:, i)=bootci(1000, @mean, nostim_vm(ind_nostim));
    else
        vm_whiskamp_nostim_ci(:, i)=[NaN; NaN];
        vm_whiskamp_nostim_avg(i)=NaN;
    end;
    
    ind_stim=find(stim_whiskamp>=whiskamps(i) & stim_whiskamp<whiskamps(i+1));
    
    vm_whiskamp_stim_avg(i)=mean(stim_vm(ind_stim));
    
    if any(ind_stim) && length(ind_stim)>5
        vm_whiskamp_stim_ci(:, i)=bootci(1000, @mean, stim_vm(ind_stim));
    else
        vm_whiskamp_stim_ci(:, i)=[NaN; NaN];
         vm_whiskamp_stim_avg(i)=NaN;
    end;
    
    whiskampsmid(i)=mean([whiskamps(i), whiskamps(i+1)]);
    
    if any(ind_nostim) && any(ind_stim)
        
        pmean(i)=ranksum(nostim_vm(ind_nostim), stim_vm(ind_stim));
        
    else
        pmean(i)=NaN;
    end;
    
end;

stat_vm.pmean_whiskingbins=pmean

set(gcf, 'userdata', stat_vm)

plot(whiskampsmid(~isnan(vm_whiskamp_nostim_avg)), vm_whiskamp_nostim_avg(~isnan(vm_whiskamp_nostim_avg)), 'color', 'k', 'linewidth', 1.5);

plot([whiskampsmid; whiskampsmid] , vm_whiskamp_nostim_ci, 'k-', 'linewidth', 1.5);
plot(whiskampsmid(~isnan(vm_whiskamp_stim_avg)), vm_whiskamp_stim_avg(~isnan(vm_whiskamp_stim_avg)), 'color', 'b', 'linewidth', 1.5);
plot([whiskampsmid; whiskampsmid], vm_whiskamp_stim_ci, 'b-', 'linewidth', 1.5);

axis 'auto y'

% spikes

hf3=figure;
set(hf3, 'units', 'centimeters', 'position', [2 2 6 6], 'paperpositionmode', 'auto')
ha=axes;
set(ha, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)]);
% bin the whisking amplitudes

nostim_spk=[spknostim_whisk_avg spknostim_nonwhisk_avg];
stim_spk=[spkstim_whisk_avg spkstim_nonwhisk_avg];
pmean=[];
for i=1:length(whiskamps)-1
    
    ind_nostim=find(nostim_whiskamp>=whiskamps(i) & nostim_whiskamp<whiskamps(i+1));
    spk_whiskamp_nostim_avg(i)=mean(nostim_spk(ind_nostim));
    
    if any(ind_nostim) && length(ind_nostim)>5
        spk_whiskamp_nostim_ci(:, i)=bootci(1000, @mean, nostim_spk(ind_nostim));
    else
        spk_whiskamp_nostim_ci(:, i)=[NaN NaN];
        spk_whiskamp_nostim_avg(i)=NaN;
    end;
    
    ind_stim=find(stim_whiskamp>=whiskamps(i) & stim_whiskamp<whiskamps(i+1));
    
    spk_whiskamp_stim_avg(i)=mean(stim_spk(ind_stim));
    
    if any(ind_stim) && length(ind_stim)>5
        spk_whiskamp_stim_ci(:, i)=bootci(1000, @mean, stim_spk(ind_stim));
    else
        spk_whiskamp_stim_ci(:, i)=[NaN NaN];
         spk_whiskamp_stim_avg(i)=NaN;
    end;
    
    whiskampsmid(i)=mean([whiskamps(i), whiskamps(i+1)]);
    
    if any(ind_nostim) && any(ind_stim)
        
        pmean(i)=ranksum(nostim_spk(ind_nostim), stim_spk(ind_stim));
        
    else
        pmean(i)=NaN;
    end;
    
end;

pmean_spk=pmean
stat_spk.pmean_whiskingbins=pmean_spk;

set(gcf, 'userdata', stat_spk)



plot(whiskampsmid(~isnan(spk_whiskamp_nostim_avg)), spk_whiskamp_nostim_avg(~isnan(spk_whiskamp_nostim_avg)), 'color', 'k', 'linewidth', 1.5);

plot([whiskampsmid; whiskampsmid] , spk_whiskamp_nostim_ci, 'k-', 'linewidth', 1.5);
plot(whiskampsmid(~isnan(spk_whiskamp_stim_avg)), spk_whiskamp_stim_avg(~isnan(spk_whiskamp_stim_avg)), 'color', 'b', 'linewidth', 1.5);

plot([whiskampsmid; whiskampsmid], spk_whiskamp_stim_ci, 'b-', 'linewidth', 1.5);

axis 'auto y'
xlabel('Whisking amp')
ylabel ('Spiking rate')


if tosave
    
    whiskingvmout=[];
    whiskingvmout.name=dataout.cellname;
    whiskingvmout.depth=T.depth;
    whiskingvmout.norm=dataout.vnorm;
    whiskingvmout.trange=trange;
    whiskingvmout.whiskingrange=whiskamps;
    whiskingvmout.whiskingparams=[whisking_th nonwhisking_th epoch_dur];
    whiskingvmout.trialnums=selected_trialnums;
    whiskingvmout.stimtrialnums=stimtrialnums;
    whiskingvmout.nostimtrialnums=nostimtrialnums;
    whiskingvmout.type=notouch;
    whiskingvmout.touch_threshold=whisk_th;
    whiskingvmout.poleonset=dataout.poleonset;
    
    whiskingvmout.t_touch=firstcontact;
    whiskingvmout.trialnum_touch=touch_trial;
    whiskingvmout.wid_contact=wid_contact;
    
    whiskingvmout.spkth=th;
    whiskingvmout.vm.nostim_all=vm_nostim_all;
    whiskingvmout.whiskamp.nostim=whiskamp_nostim_all;
    whiskingvmout.vm.stim_all=vm_stim_all;
    whiskingvmout.whiskamp.stim=whiskamp_stim_all;
    whiskingvmout.vm.aom=aom_all;
    whiskingvmout.tvm=tvm;
    whiskingvmout.twhisk=twhisk;
    
    whiskingvmout.vm.nostim_nonwhisking_avg=vmnostim_nonwhisk_avg;
    whiskingvmout.vm.nostim_nonwhisking_epochs=vmnostim_nonwhisking_epochs;
    whiskingvmout.vm.nostim_whisking_avg=vmnostim_whisk_avg;
    whiskingvmout.vm.nostim_whisking_epochs=vmnostim_whisking_epochs;
    
    whiskingvmout.vm.stim_nonwhisking_avg=vmstim_nonwhisk_avg;
    whiskingvmout.vm.stim_nonwhisking_epochs=vmstim_nonwhisking_epochs;
    whiskingvmout.vm.stim_whisking_avg=vmstim_whisk_avg;
    whiskingvmout.vm.stim_whisking_epochs=vmstim_whisking_epochs;
    
    whiskingvmout.spk.nostim_nonwhisking_avg=spknostim_nonwhisk_avg;
    whiskingvmout.spk.nostim_whisking_avg=spknostim_whisk_avg;
    
    whiskingvmout.spk.stim_nonwhisking_avg=spkstim_nonwhisk_avg;
    whiskingvmout.spk.stim_whisking_avg=spkstim_whisk_avg;
    
    whiskingvmout.whiskamps.nonwhisknostim_avg=whiskamps_nonwhisknostim_avg;
    whiskingvmout.whiskamps.nonwhiskstim_avg= whiskamps_nonwhiskstim_avg;
    whiskingvmout.whiskamps.whisknostim_avg=  whiskamps_whisknostim_avg;
    whiskingvmout.whiskamps.whiskstim_avg= whiskamps_whiskstim_avg;
    
    whiskingvmout.whiskampsmid=whiskampsmid;
    whiskingvmout.vm_whiskamp_nostim_avg=vm_whiskamp_nostim_avg;
    whiskingvmout.vm_whiskamp_nosim_ci=vm_whiskamp_nostim_ci;
    whiskingvmout.vm_whiskamp_stim_avg=vm_whiskamp_stim_avg;
    whiskingvmout.vm_whiskamp_stim_ci=vm_whiskamp_stim_ci;
    whiskingvmout.spk_whiskamp_nostim_avg=spk_whiskamp_nostim_avg;
    whiskingvmout.spk_whiskamp_nosim_ci=spk_whiskamp_nostim_ci;
    whiskingvmout.spk_whiskamp_stim_avg=spk_whiskamp_stim_avg;
    whiskingvmout.spk_whiskamp_stim_ci=spk_whiskamp_stim_ci;
    whiskingvmout.stat_vm=stat_vm;
    whiskingvmout.stat_spk=stat_spk;

    whiskinvmou.date=date;
    
    save (['whiskingvmout' '_' num2str(notouch) '.mat'], 'whiskingvmout');
    whiskingvmout.stat_vm.whisking_nonwhisking
    whiskingvmout.stat_spk.whisking_nonwhisking
    whiskingvmout.stat_vm.pmean_whiskingbins
    whiskingvmout.stat_spk.pmean_whiskingbins
    
    saveas(hf_avg, ['avg_effect', '_' num2str(notouch)], 'tif')
    saveas(hf_avg, ['avg_effect', '_' num2str(notouch)], 'fig')
    
    saveas(hf1, ['vm_whisk_new' '_wid'  num2str(dataout.whiskid) '_' num2str(notouch)],'tif')
    saveas(hf2, ['vm_whiskamps_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'tif')
    saveas(hf1, ['vm_whisk_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'fig')
    saveas(hf2, ['vm_whiskamps_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'fig')
    
    saveas(hfs, ['whisking_vs_nonwhisking' '_' num2str(notouch)], 'fig')
    saveas(hfs, ['whisking_vs_nonwhisking' '_' num2str(notouch)], 'tif')
    
    saveas(hf11, ['spk_whisk_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'tif')
    saveas(hf3, ['spk_whiskamps_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'tif')
    saveas(hf11, ['spk_whisk_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'fig')
    saveas(hf3, ['spk_whiskamps_new' '_wid' num2str(dataout.whiskid) '_' num2str(notouch)],'fig')
    
    if notouch==2
        saveas(hfcontact, 'firstcontact', 'tif');
        saveas(hfcontact, 'firstcontact', 'fig')
    end;
    
end;
