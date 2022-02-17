function whiskingepochstim3(T, dataout, contacts, tdelay, vrange, md, whiskamps, th, showspikes,  touchwhisker, whisk_nonwhisk,  wid, badtrials, tosave);
% function whiskingepochstim3(T, dataout, contacts, tdelay, vrange, md, whiskamps, th, showspikes,  touchwhisker, whisk_nonwhisk,  wid, badtrials, tosave);
% use manually tracked contacts
% 10.2013, JY
% the Vm.
% after that, summerize Vm, amplitude, etc.
% 5.2014, no stim data will be plotted

tpre=50; % pre-stim time: 100 ms

selected_trialnums=[dataout.hit_nostim_nums dataout.cr_nostim_nums dataout.miss_nostim_nums dataout.fa_nostim_nums];
selected_trialnums=setdiff(selected_trialnums, badtrials);
whisking_th=whisk_nonwhisk(2);
nonwhisking_th=whisk_nonwhisk(1);

epoch_dur=100;
[whisking_epochs, nonwhisking_epochs]=T.detectWhiskingEpochs(wid, selected_trialnums, [whisking_th nonwhisking_th], 31, epoch_dur);

hfs=figure;
set(gcf, 'unit', 'centimeters', 'position', [2 2 10 20], 'paperpositionmode', 'auto')

K=randperm(length(selected_trialnums));
for k=1:5
    subplot(5, 1, k)
    i=K(k);
    [wpos, tw]=T.get_whisker_position(dataout.whiskid, selected_trialnums(i));
    
    tw=cell2mat(tw); wpos=cell2mat(wpos);
    %      line([trange(1) trange(1)], [min(wpos) max(wpos)], 'linestyle', '--', 'color', 'c', 'linewidth', 2);  hold on;
    %      line([trange(2) trange(2)], [min(wpos) max(wpos)], 'linestyle', '--', 'color', 'c', 'linewidth', 2);
    
    plot(tw, wpos); hold on
    
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

spknostim_whisk_avg={};
spknostim_nonwhisk_avg={};
spkstim_whisk_avg={};
spkstim_nonwhisk_avg={};

whiskamps_whiskstim_avg=[];
whiskamps_nonwhiskstim_avg=[];
whiskamps_whisknostim_avg=[];
whiskamps_nonwhisknostim_avg=[];

allstimtrials=T.stimtrialNums;
stimtrialsonset=[];
nostimtrialsonset=[];

whiskingstamp=[];
nonwhiskingstamp=[];

twhisk=[0:1/1000:4.999];

firstcontact=[];

vm_nostim_all=[];
vm_stim_all=[];
aom_all=[];

vm_stim_surround=[];
fp_stim_surround=[];
tvm_stim_surround=[0-tpre*10:24999]/10;
twhisk_stim_surround=[0-tpre:2499];
whiskamp_stim_surround=[];
whisksetpt_stim_surround=[];
whiskpos_stim_surround=[];

vm_nostim_surround=[];
fp_nostim_surround=[];

whiskamp_nostim_surround=[];
whisksetpt_nostim_surround=[];
whiskpos_nostim_surround=[];

aom_stim_surround=[];

whiskamp_nostim_all=[];
whiskamp_stim_all=[];
t_contact=[];
touch_trial=[];
wid_contact=[];

stimtrialnums=[];
nostimtrialnums=[];

allstimonset=[];
falsestim=[];
for ix=1:size(aomxstim, 2)
    on=find(aomxstim(:, ix)>.2, 1, 'first')/10000;
    if ~isempty(on)
        allstimonset=[allstimonset on];
    else
        falsestim=[falsestim xstim(ix)];
    end;
end;

allstimtrials=setdiff(allstimtrials, falsestim);

for i=1:length(selected_trialnums)
    tids=T.trials{T.trialNums==selected_trialnums(i)}.whiskerTrial. trajectoryIDs;
    t_contact_iw=[];
    wid_contact_iw=[];
    icont=contacts{T.trialNums==selected_trialnums(i)};
    if isempty(touchwhisker)
        for iw=1:length(tids)
            touch_iw=icont.segmentInds{iw};
            if ~isempty(touch_iw)
                time=T.trials{T.trialNums==selected_trialnums(i)}.whiskerTrial.time{iw};
                first_touch=touch_iw(1, 1);
                t_contact_iw=[t_contact_iw time(first_touch)];
                wid_contact_iw=[wid_contact_iw tids(iw)];
            end;
        end;
        
        [t_contact, ind_contact]=min(t_contact_iw);
        wid_contact=[wid_contact wid_contact_iw(ind_contact)];
        
    else
        touch_iw=icon.segmentInds{icon.tid==touchwhisker};
        if ~isempty(touch_iw)
            time=T.trials{T.trialNums==selected_trialnums(i)}.whiskerTrial.time{icon.tid==touchwhisker};
            first_touch=touch_iw(1, 1);
            t_contact=time(first_touch);
            wid_contact=[wid_contact touchwhisker];
        else
            t_contact=[];
        end;
    end;
    [selected_trialnums(i) t_contact];
    firstcontact=[firstcontact t_contact];
    if ~isempty(t_contact)
        touch_trial=[touch_trial selected_trialnums(i)];
    end;
    t_contact=t_contact; % subtract 25ms for more conservative estimate
    
    twhisk=[0:1/1000:4.999];
    [wpos, tw]=T.get_whisker_position(dataout.whiskid, selected_trialnums(i));
    whisk_params=whiskdecomposej(wpos, tw, twhisk);
    % twhisk=twhisk+0.01;
    
    tri=selected_trialnums(i);
    vm_tn=T.trials{T.trialNums==tri}.spikesTrial.rawSignal;
    tvm=[0:length(vm_tn)-1]/10000-0.01; % substracting the offset
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
        vm_tn=medfilt1(vm_tn, 10*5); % good for removing bursts
    end;
    
    whisking_epochs_tn=whisking_epochs{i};
    n_whisking_epochs_tn=size(whisking_epochs_tn, 1);
    
    nonwhisking_epochs_tn=nonwhisking_epochs{i};
    n_nonwhisking_epochs_tn=size(nonwhisking_epochs_tn, 1);
    
    if any(intersect(tri, allstimtrials))
        % so it belongs to a stim trial
        stimtrialnums=[stimtrialnums tri];
        [vm_tri, aom, tvm, fp_tri]=findvmtrials(T, tri);
        aom_all=[aom_all aom];
        
        aom_onset=find(aom>.2, 1, 'first')/10000;
        aom_offset=find(aom>.2, 1, 'last')/10000;
        
        stimtrialsonset=[stimtrialsonset aom_onset];
        vm_stim_surround=[vm_stim_surround vm_tri(find(aom>1, 1, 'first')-tpre*10:find(aom>1, 1, 'first')+24999)];
        aom_stim_surround=[aom_stim_surround aom(find(aom>1, 1, 'first')-tpre*10:find(aom>1, 1, 'first')+24999)];
        fp_stim_surround=[fp_stim_surround fp_tri(find(aom>1, 1, 'first')-tpre*10:find(aom>1, 1, 'first')+24999)];
        
        indx=find(twhisk>=aom_onset-tpre/1000 & twhisk<=aom_onset+3.5);
        indx=indx(1:tpre+2500);
        
        whiskamp_stim_surround=[whiskamp_stim_surround whisk_params.amp(indx)];
        whisksetpt_stim_surround=[whisksetpt_stim_surround whisk_params.setpt(indx)];
        whiskpos_stim_surround=[whiskpos_stim_surround whisk_params.whiskpos(indx)];
        
        aom_onset=aom_onset+tdelay;
        
        vm_stim_all=[vm_stim_all vm_tri];
        whiskamp_stim_all=[whiskamp_stim_all whisk_params.amp];
        
        if n_whisking_epochs_tn>0
            for j=1:n_whisking_epochs_tn
                
                t1=whisking_epochs_tn(j, 1);
                
                if  ~isempty(t_contact)
                    t2=min([whisking_epochs_tn(j, 2) t_contact]);
                else
                    t2=min([whisking_epochs_tn(j, 2)]);
                end;
                
                t12=[t1 t2];
                aom_onoff=[aom_onset aom_offset];
                
                if t2>t1+0.01 && t1>=aom_onset && t1<=aom_offset
                    
                    vmstim_whisking_epochs=[vmstim_whisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmstim_whisk_avg=[vmstim_whisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spkstim_whisk_avg=[spkstim_whisk_avg {spk_tn(tvm>=t1 & tvm<=t2)}];
                    whiskamps_whiskstim_avg=[whiskamps_whiskstim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                    whiskingstamp=[whiskingstamp; tri, t1, t2];
                    tri
                end;
                
            end;
        end;
        
        if n_nonwhisking_epochs_tn>0
            
            for j=1:n_nonwhisking_epochs_tn
                
                t1=nonwhisking_epochs_tn(j, 1);
                if  ~isempty(t_contact)
                    t2=min([nonwhisking_epochs_tn(j, 2) t_contact]);
                else
                    t2=min([nonwhisking_epochs_tn(j, 2)]);
                end;
                
                if t2>t1+0.01&& t1>=aom_onset && t1<=aom_offset
                    
                    vmstim_nonwhisking_epochs=[vmstim_nonwhisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmstim_nonwhisk_avg=[vmstim_nonwhisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spkstim_nonwhisk_avg=[spkstim_nonwhisk_avg {spk_tn(tvm>=t1 & tvm<=t2)}];
                    whiskamps_nonwhiskstim_avg=[whiskamps_nonwhiskstim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                    nonwhiskingstamp=[nonwhiskingstamp; tri, t1, t2];
                end;
            end;
        end;
    else
        % so it belongs to a nonstim trial
        nostimtrialnums=[nostimtrialnums tri];
        [vm_tri, aom,tvm,  fp_tri]=findvmtrials(T, tri);
        
        vm_nostim_all=[vm_nostim_all vm_tri];
        whiskamp_nostim_all=[whiskamp_nostim_all whisk_params.amp];
        
        randonset=allstimonset(randperm(size(allstimonset, 2)));
        trand=randonset(1);
        
        %aom_onset=find(aom<0, 1, 'first')/10000;
        % aom_offset=length(vm_tri)/10000;
        
        aom_onset=trand;
        nostimtrialsonset=[nostimtrialsonset aom_onset];
        
        aom_offset=find(aom>.2, 1, 'last')/10000;
        
        vm_nostim_surround=[vm_nostim_surround vm_tri(round(trand*10000)-tpre*10:round(trand*10000)+24999)];
        fp_nostim_surround=[fp_nostim_surround fp_tri(round(trand*10000)-tpre*10:round(trand*10000)+24999)];
        
        indx=find(twhisk>=aom_onset-tpre/1000 & twhisk<=aom_onset+3.5);
        indx=indx(1:tpre+2500);
        
        whiskamp_nostim_surround=[whiskamp_nostim_surround whisk_params.amp(indx)];
        whisksetpt_nostim_surround=[whisksetpt_nostim_surround whisk_params.setpt(indx)];
        whiskpos_nostim_surround=[whiskpos_nostim_surround whisk_params.whiskpos(indx)];
        
        aom_onset=aom_onset+tdelay;
        
        if n_whisking_epochs_tn>0
            for j=1:n_whisking_epochs_tn
                
                t1=max([whisking_epochs_tn(j, 1), 0]);
                
                if ~isempty(t_contact)
                    t2=min([whisking_epochs_tn(j, 2),  t_contact]);
                else
                    t2=min([whisking_epochs_tn(j, 2)]);
                end;
                
                if t2>t1+0.01
                    
                    vmnostim_whisking_epochs=[vmnostim_whisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmnostim_whisk_avg=[vmnostim_whisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spknostim_whisk_avg=[spknostim_whisk_avg {spk_tn(tvm>=t1 & tvm<=t2)}];
                    whiskamps_whisknostim_avg=[whiskamps_whisknostim_avg mean(whisk_params.amp(twhisk>=t1 & twhisk<=t2))];
                    whiskingstamp=[whiskingstamp; tri, t1, t2];
                end;
            end;
        end;
        
        if n_nonwhisking_epochs_tn>0
            for j=1:n_nonwhisking_epochs_tn
                
                t1=max([nonwhisking_epochs_tn(j, 1)]);
                
                if ~isempty(t_contact)
                    t2=min([nonwhisking_epochs_tn(j, 2) t_contact]);
                else
                    t2=min([nonwhisking_epochs_tn(j, 2)]);
                end;
                
                if t2>t1+0.01
                    vmnostim_nonwhisking_epochs=[vmnostim_nonwhisking_epochs vm_tn_org(tvm>=t1 & tvm<=t2)];
                    vmnostim_nonwhisk_avg=[vmnostim_nonwhisk_avg mean(vm_tn(tvm>=t1 & tvm<=t2))];
                    spknostim_nonwhisk_avg=[spknostim_nonwhisk_avg {spk_tn(tvm>=t1 & tvm<=t2)}];
                    whiskamps_nonwhisknostim_avg=[whiskamps_nonwhisknostim_avg mean(whisk_params.amp(twhisk>=t1& twhisk<=t2))];
                    nonwhiskingstamp=[nonwhiskingstamp; tri, t1, t2];
                end;
            end;
        end;
    end;    
end;
    
    hfcontact=figure;
    set(hfcontact, 'paperpositionmode', 'auto', 'units', 'centimeters', 'position', [5 2 8 8], 'color', 'w');
    ha=axes;
    hist(firstcontact, 50);
    xlabel('touch time (s)')
    ylabel('count')
    
    hf_avg=figure;
    set(hf_avg, 'units', 'centimeters', 'position', [4 4 15 10], 'paperpositionmode', 'auto', 'color', 'w')
    
    ha_whisk=axes('xlim', [tvm(1) tvm(end)], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.1 .72 .35 .25], 'xticklabel', [])
    
    plot(twhisk, mean(whiskamp_nostim_all, 2), 'k');
    plot(twhisk, mean(whiskamp_stim_all, 2), 'b');
    ylabel('whisk amp (deg)')
    legend('no stim', 'stim')
    
    ha_avg=axes('xlim', [tvm(1) tvm(end)], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.1 .45 .35 .25])
    
    plot(tvm, mean(removeAP(vm_nostim_all, 10000, th, 4), 2), 'k');
    plot(tvm, mean(removeAP(vm_stim_all,10000, th, 4), 2), 'b');
    axis 'auto y'
    ylim=get(ha_avg, 'ylim');
    plot(tvm,  aom_all(:, 1)/2+ylim(1)-2, 'b:')
    plot(dataout.poleonset, ylim(2)-5, 'r*', 'markersize', 8)
    xlabel('Time (s)')
    ylabel('Vm (mV)')
    
    ha=axes('xlim', [tvm_stim_surround(1) 1000], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.1 .1 .35 .25])
    
    % get spikes
    spk_nostim_surround=spikespy(vm_nostim_surround, 10000, th, 4);
    spk_stim_surround=spikespy(vm_stim_surround, 10000, th, 4);
    
    % med filt
    % vm_stim_surround=medfilt1(vm_stim_surround, 15, 1);
    % vm_nostim_surround=medfilt1(vm_nostim_surround, 15, 1);
    
    plot(tvm_stim_surround, vm_stim_surround, 'color', [0.75 0.75 0.75]);
    ncols=size(vm_stim_surround, 2);
    randcols=randperm(ncols);
    
    plot(tvm_stim_surround, vm_stim_surround(:, randcols(1)), 'c', 'linewidth', 1);
    plot(tvm_stim_surround, vm_stim_surround(:, randcols(2)), 'm', 'linewidth', 1);
    plot(tvm_stim_surround, vm_stim_surround(:, randcols(3)), 'g', 'linewidth', 1);
    plot(tvm_stim_surround, vm_stim_surround(:, randcols(4)), 'r', 'linewidth', 1);
    
    axis tight
    ylim=get(ha, 'ylim');
    set(gca, 'xlim', [tvm_stim_surround(1) 1000], 'ylim', [ylim(1)-5 ylim(2)]);
    plot(tvm_stim_surround,aom_stim_surround+ylim(1)-4, 'b')
    xlabel('Time (s)')
    ylabel('Vm (mV)')
    
    ha_avg=axes('xlim', [tvm_stim_surround(1) tvm_stim_surround(1)+1000], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.55 .7 .35 .25], 'xticklabel', [])
    
    %  [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
    
    [spkhist_nostim_surround, thist_surround]=spikehisto(spk_nostim_surround, 10000, 2600/10);
    spkhist_stim_surround=spikehisto(spk_stim_surround, 10000, 2600/10);
    thist_surround=1000*(thist_surround+tvm_stim_surround(1)/1000);
    plot(thist_surround, spkhist_nostim_surround, 'k');
    plot(thist_surround, spkhist_stim_surround, 'b');
    
    axis 'auto y'
    ylim=get(ha_avg, 'ylim');
    plot(tvm_stim_surround,aom_stim_surround/4+ylim(1)-2, 'b')
    %plot(dataout.poleonset, ylim(2)-2, 'r*', 'markersize', 8)
    ylabel('Spk(Hz)')
    
    ha_avg=axes('xlim', [tvm_stim_surround(1) tvm_stim_surround(1)+1000], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.55 .4 .35 .25])
    
    plot(tvm_stim_surround, mean(removeAP(vm_nostim_surround, 10000, th, 4), 2), 'k');
    plot(tvm_stim_surround, mean(removeAP(vm_stim_surround, 10000, th, 4), 2), 'b');
    axis 'auto y'
    ylim=get(ha_avg, 'ylim');
    plot(tvm_stim_surround,aom_stim_surround/4+ylim(1)-2, 'b')
    %plot(dataout.poleonset, ylim(2)-2, 'r*', 'markersize', 8)
    ylabel('Vm (mV)')
    
    axes(axes('xlim', [twhisk_stim_surround(1) twhisk_stim_surround(1)+1000], 'nextplot', 'add', 'fontsize', 8, 'units', 'normalized', 'position', [.55 .1 .35 .25]))
    plot(twhisk_stim_surround, mean(whiskamp_nostim_surround, 2), 'k');
    plot(twhisk_stim_surround, mean(whiskamp_stim_surround, 2), 'b');
    axis 'auto y'
    xlabel('Time (ms)')
    ylabel('Whisking amp (deg)')
    
    hf1=figure;
    set(gcf, 'units', 'centimeters', 'position', [4 4 20 14],'color', 'w', 'paperpositionmode', 'auto');
    
    subplot(4, 4, 1)
    [n1,x1]=hist(vmnostim_nonwhisk_avg, linspace(vrange(1), vrange(2), 50));
    set(gca, 'xlim', vrange, 'nextplot', 'add');
    bar(x1, n1,  'k', 'edgecolor', 'k')
    title(['no stim, nonwhisking(1), ' sprintf('%0.1f',median(vmnostim_nonwhisk_avg))])
    
    subplot(4, 4, 5)
    [n2,x2]=hist(vmstim_nonwhisk_avg, linspace(vrange(1), vrange(2), 50));
    set(gca, 'xlim', vrange, 'nextplot', 'add');
    bar(x2, n2,  'b', 'edgecolor', 'b')
    
    title(['stim, nonwhisking (2), ' sprintf('%0.1f',median(vmstim_nonwhisk_avg))])
    xlabel('mV')
    ylabel('count')
    
    if ~isempty(vmnostim_nonwhisk_avg) && ~isempty(vmstim_nonwhisk_avg)
        data.pvm_nonwhisking=ranksum(vmnostim_nonwhisk_avg, vmstim_nonwhisk_avg);
        data.dVm_nonwhisking=median(vmstim_nonwhisk_avg)-median(vmnostim_nonwhisk_avg);
    else
        data.pvm_nonwhisking=[];
        data.dVm_nonwhisking=[];
    end;
    
    subplot(4, 4, 2)
    [n3,x3]=hist(vmnostim_whisk_avg, linspace(vrange(1), vrange(2), 50));
    set(gca, 'xlim', vrange, 'nextplot', 'add');
    bar(x3, n3,  'k', 'edgecolor', 'k')
    title(['no stim, whisking(3), ' sprintf('%0.1f',median(vmnostim_whisk_avg))])
    
    subplot(4, 4, 6)
    [n4,x4]=hist(vmstim_whisk_avg, linspace(vrange(1), vrange(2), 50));
    set(gca, 'xlim', vrange, 'nextplot', 'add');
    bar(x4, n4,  'b', 'edgecolor', 'b')
    title(['stim, whisking(4), ' sprintf('%0.1f',median(vmstim_whisk_avg))])
    
    if ~isempty(vmnostim_nonwhisk_avg) && ~isempty(vmstim_nonwhisk_avg)
        
        data.pvm_whisking=ranksum(vmnostim_whisk_avg, vmstim_whisk_avg);
        data.dVm_whisking=median(vmstim_whisk_avg)-median(vmnostim_whisk_avg);
        
    end;
    
    stat_vm.whisking_nonwhisking=data;
    
    set (gcf, 'userdata', data)
    
    subplot(4, 4, [3 7])
    set(gca, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vrange)
    
    boxplot([vmnostim_nonwhisk_avg vmstim_nonwhisk_avg vmnostim_whisk_avg vmstim_whisk_avg],...
        [ones(size(vmnostim_nonwhisk_avg)) 2*ones(size(vmstim_nonwhisk_avg)) 3*ones(size(vmnostim_whisk_avg)) 4*ones(size(vmstim_whisk_avg))],...
        'colors', 'kbkb');
    
    xlabel('conditions')
    ylabel ('mV')
    
    posvm=get(gca, 'position');
    
    subplot(4, 4, [4 8])
    set(gca, 'nextplot', 'add', 'xlim', [0 5], 'ylim', vrange, 'xtick', [1 2 3 4])
    
    
    spknostim_nonwhisk_rate=findrate(spknostim_nonwhisk_avg);
    spkstim_nonwhisk_rate=findrate(spkstim_nonwhisk_avg);
    spknostim_whisk_rate=findrate(spknostim_whisk_avg);
    spkstim_whisk_rate=findrate(spkstim_whisk_avg);
    
    plot(1, spknostim_nonwhisk_rate(1), 'ko')
    line([1 1], [spknostim_nonwhisk_rate(2) spknostim_nonwhisk_rate(3)], 'color', 'k')
    
    plot(2, spkstim_nonwhisk_rate(1), 'bo')
    line([2 2], [spkstim_nonwhisk_rate(2) spkstim_nonwhisk_rate(3)], 'color', 'b')
    
    plot(3, spknostim_whisk_rate(1), 'ko')
    line([3 3], [spknostim_whisk_rate(2) spknostim_whisk_rate(3)], 'color', 'k')
    
    plot(4, spkstim_whisk_rate(1), 'bo')
    line([4 4], [spkstim_whisk_rate(2) spkstim_whisk_rate(3)], 'color', 'b')
    
    axis 'auto y'
    xlabel('conditions')
    ylabel('Spk (Hz)')
    posspk=get(gca, 'position');
    posspk(2)=posvm(2);
    posspk(4)=posvm(4);
    set(gca, 'position', posspk);
    
    set (gcf, 'userdata',data)
    xlabel('Conditions')
    ylabel('Firing rate')
    
    ha1=subplot(4, 4, [9 13]);
    set(ha1, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)], 'ylim', vrange);
    xlabel ('Whisking amp'); ylabel('Vm')
    
    nostim_vm=[vmnostim_whisk_avg vmnostim_nonwhisk_avg];
    stim_vm=[vmstim_whisk_avg vmstim_nonwhisk_avg];
    
    nostim_vmepochs=[vmnostim_whisking_epochs  vmnostim_nonwhisking_epochs];
    stim_vmepochs=[vmstim_whisking_epochs  vmstim_nonwhisking_epochs];
    
    nostim_whiskamp=[whiskamps_whisknostim_avg whiskamps_nonwhisknostim_avg];
    stim_whiskamp=[whiskamps_whiskstim_avg whiskamps_nonwhiskstim_avg];
    
    plot(nostim_whiskamp, nostim_vm, 'ko', 'markersize', 4);
    plot(stim_whiskamp, stim_vm, 'bo', 'markersize', 4);
    
    axis 'auto y'
    
    ha2=subplot(4, 4, [10 14]);
    set(ha2, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)], 'ylim', vrange);
    % bin the whisking amplitudes
    xlabel('Whisking amp'); ylabel ('Vm')
    
    pmean=[];
    for i=1:length(whiskamps)-1
        whiskampsmid(i)=mean([whiskamps(i), whiskamps(i+1)]);
        
        ind_nostim=find(nostim_whiskamp>=whiskamps(i) & nostim_whiskamp<whiskamps(i+1));
        % nostim_vmepochs
        if length(ind_nostim)>3
            [vm_whiskamp_nostim_avg(i, :), vm_whiskamp_nostim_all{i}]=analyze_vmepoch(nostim_vmepochs(ind_nostim), th);
            line([whiskampsmid(i) whiskampsmid(i)] , [vm_whiskamp_nostim_avg(i, 2) vm_whiskamp_nostim_avg(i, 3)], 'color', 'k', 'linewidth', 1);
        else
            vm_whiskamp_nostim_avg(i, :)=[NaN NaN NaN];
            vm_whiskamp_nostim_all{i}=[];
        end;
        
        ind_stim=find(stim_whiskamp>=whiskamps(i) & stim_whiskamp<whiskamps(i+1));
        if length(ind_stim)>3
            [vm_whiskamp_stim_avg(i, :), vm_whiskamp_stim_all{i}]=analyze_vmepoch(stim_vmepochs(ind_stim), th);
            line([whiskampsmid(i) whiskampsmid(i)] , [vm_whiskamp_stim_avg(i, 2) vm_whiskamp_stim_avg(i, 3)], 'color', 'b', 'linewidth', 1);
        else
            vm_whiskamp_stim_avg(i, :)=[NaN NaN NaN];
            vm_whiskamp_stim_all{i}=[];
            
        end;
        
        if any(ind_nostim) && any(ind_stim)
            pmean(i)=ranksum(nostim_vm(ind_nostim), stim_vm(ind_stim));
        else
            pmean(i)=NaN;
        end;
    end;
    
    plot(whiskampsmid(~isnan(vm_whiskamp_nostim_avg(:, 1))), vm_whiskamp_nostim_avg(~isnan(vm_whiskamp_nostim_avg(:, 1)), 1), 'ko-', 'linewidth', 1);
    plot(whiskampsmid(~isnan(vm_whiskamp_stim_avg(:, 1))), vm_whiskamp_stim_avg(~isnan(vm_whiskamp_stim_avg(:, 1)), 1), 'bo-', 'linewidth', 1);
    
    axis 'auto y'
    
    % spikes
    
    % hf3=figure;
    % set(hf3, 'units', 'centimeters', 'position', [2 2 6 6], 'paperpositionmode', 'auto')
    ha3=subplot(4, 4, [11 15]);
    set(ha3, 'nextplot', 'add', 'xlim', [min(whiskamps) max(whiskamps)]);
    % bin the whisking amplitudes
    
    nostim_spk=[spknostim_whisk_avg spknostim_nonwhisk_avg];
    stim_spk=[spkstim_whisk_avg spkstim_nonwhisk_avg];
    pmean=[];
    
    for i=1:length(whiskamps)-1
        
        ind_nostim=find(nostim_whiskamp>=whiskamps(i) & nostim_whiskamp<whiskamps(i+1));
        if any(ind_nostim) && length(ind_nostim)>5
            spk_whiskamp_nostim_avg(i, :)=findrate(nostim_spk(ind_nostim));
        else
            spk_whiskamp_nostim_avg(i, :)=[NaN NaN NaN];
        end;
        
        ind_stim=find(stim_whiskamp>=whiskamps(i) & stim_whiskamp<whiskamps(i+1));
        if any(ind_stim) && length(ind_stim)>5
            spk_whiskamp_stim_avg(i, :)=findrate(stim_spk(ind_stim));
        else
            spk_whiskamp_stim_avg(i, :)=[NaN NaN NaN];
        end;
        
    end;
    
    plot(whiskampsmid, spk_whiskamp_nostim_avg(:, 1), 'ko-', 'linewidth', 1);
    plot([whiskampsmid; whiskampsmid] , spk_whiskamp_nostim_avg(:, [2 3])', 'k-', 'linewidth', 1);
    
    plot(whiskampsmid, spk_whiskamp_stim_avg(:, 1), 'bo-', 'linewidth', 1);
    plot([whiskampsmid; whiskampsmid], spk_whiskamp_stim_avg(:, [2 3])', 'b-', 'linewidth', 1);
    
    axis 'auto y'
    xlabel('Whisking amp')
    ylabel ('Spiking rate')
    
    
    if tosave
        
        whiskingvmout=[];
        whiskingvmout.name=dataout.cellname;
        whiskingvmout.depth=T.depth;
        whiskingvmout.norm=dataout.vnorm;
        whiskingvmout.tdelay=tdelay;
        whiskingvmout.whiskingrange=whiskamps;
        whiskingvmout.whiskingparams=[whisking_th nonwhisking_th epoch_dur];
        whiskingvmout.trialnums=selected_trialnums;
        whiskingvmout.stimtrialnums=stimtrialnums;
        whiskingvmout.nostimtrialnums=nostimtrialnums;
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
        
        whiskingvmout.vm.nostim_nonwhisking_avg=analyze_vmepoch(vmnostim_nonwhisking_epochs, th);
        whiskingvmout.vm.nostim_nonwhisking_epochs=vmnostim_nonwhisking_epochs;
        whiskingvmout.vm.nostim_whisking_avg=analyze_vmepoch(vmnostim_whisking_epochs, th);
        whiskingvmout.vm.nostim_whisking_epochs=vmnostim_whisking_epochs;
        
        whiskingvmout.vm.stim_nonwhisking_avg=analyze_vmepoch(vmstim_nonwhisking_epochs, th);
        whiskingvmout.vm.stim_nonwhisking_epochs=vmstim_nonwhisking_epochs;
        
        whiskingvmout.vm.stim_whisking_avg=analyze_vmepoch(vmstim_whisking_epochs, th);
        whiskingvmout.vm.stim_whisking_epochs=vmstim_whisking_epochs;
        
        whiskingvmout.spk.nostim_nonwhisking_epochs=spknostim_nonwhisk_avg;
        whiskingvmout.spk.nostim_nonwhisking_avg=spknostim_nonwhisk_rate;
        
        whiskingvmout.spk.nostim_whisking_epochs=spknostim_whisk_avg;
        whiskingvmout.spk.nostim_whisking_avg=spknostim_whisk_rate;
        
        whiskingvmout.spk.stim_nonwhisking_epochs=spkstim_nonwhisk_avg;
        whiskingvmout.spk.stim_nonwhisking_avg=spkstim_nonwhisk_rate;
        
        whiskingvmout.spk.stim_whisking_epochs=spkstim_whisk_avg;
        whiskingvmout.spk.stim_whisking_avg=spkstim_whisk_rate;
        
        whiskingvmout.surroundAOM.aom= aom_stim_surround;
        whiskingvmout.surroundAOM.vm_nostim_surround=vm_nostim_surround;
        whiskingvmout.surroundAOM.vm_stim_surround=vm_stim_surround;
        whiskingvmout.surroundAOM.fp_nostim_surround=fp_nostim_surround;
        whiskingvmout.surroundAOM.fp_stim_surround=fp_stim_surround;
        whiskingvmout.surroundAOM.stimonset=stimtrialsonset;
        whiskingvmout.surroundAOM.nostimonset=nostimtrialsonset;
        whiskingvmout.surroundAOM.tvm_stim_surround=tvm_stim_surround;
        
        whiskingvmout.surroundAOM.spkhist_nostim_surround=spkhist_nostim_surround;
        whiskingvmout.surroundAOM.spkhist_stim_surround=spkhist_stim_surround;
        whiskingvmout.surroundAOM.thist_surround=thist_surround;
        
        whiskingvmout.surroundAOM.whiskamp_stim_surround=whiskamp_stim_surround;
        whiskingvmout.surroundAOM.whiskamp_nostim_surround=whiskamp_nostim_surround;
        whiskingvmout.surroundAOM.whisksetpt_stim_surround=whisksetpt_stim_surround;
        whiskingvmout.surroundAOM.whisksetpt_nostim_surround=whisksetpt_nostim_surround;
        whiskingvmout.surroundAOM.whiskpos_stim_surround=whiskpos_stim_surround;
        whiskingvmout.surroundAOM.whiskpos_nostim_surround=whiskpos_nostim_surround;
        whiskingvmout.surroundAOM.twhisk_surround=twhisk_stim_surround;
        
        whiskingvmout.whiskamps.nonwhisknostim_avg=whiskamps_nonwhisknostim_avg;
        whiskingvmout.whiskamps.nonwhiskstim_avg= whiskamps_nonwhiskstim_avg;
        whiskingvmout.whiskamps.whisknostim_avg=  whiskamps_whisknostim_avg;
        whiskingvmout.whiskamps.whiskstim_avg= whiskamps_whiskstim_avg;
        whiskingvmout.whiskingstamp=whiskingstamp;
        whiskingvmout.nonwhiskingstamp=nonwhiskingstamp;
        
        whiskingvmout.whiskampsmid=whiskampsmid;
        whiskingvmout.vm_whiskamp_nostim_avg=vm_whiskamp_nostim_avg;
        whiskingvmout.vm_whiskamp_nostim_all=vm_whiskamp_nostim_all;
        whiskingvmout.vm_whiskamp_stim_avg=vm_whiskamp_stim_avg;
        whiskingvmout.vm_whiskamp_stim_all=vm_whiskamp_stim_all;
        
        whiskingvmout.spk_whiskamp_nostim_avg=spk_whiskamp_nostim_avg;
        whiskingvmout.spk_whiskamp_stim_avg=spk_whiskamp_stim_avg;
        whiskingvmout.stat_vm=stat_vm;
        whiskinvmou.date=date;
        
        save (['whiskingvmout' '_' 'contacts' '.mat'], 'whiskingvmout');
        % export_fig (hf, 'TouchPlot','-pdf', '-tiff')
        export_fig(hf_avg, ['avg_effect', '_newcontacts'] , '-tiff', '-pdf')
        saveas (hf_avg, ['avg_effect', '_newcontacts' ], 'fig')
        
        export_fig(hf1, ['vmspk_whisk_nonwhisk' '_newcontacts'],'-tiff', '-pdf')
        saveas(hf1, ['vmspk_whisk_nonwhisk' '_newcontacts'],'fig')
        
        
        export_fig(hfcontact, 'firstcontact', '-tiff', '-pdf');
        saveas(hfcontact, 'firstcontact', 'fig')
        assignin('base','whiskingvmout',whiskingvmout);
        
    end;
