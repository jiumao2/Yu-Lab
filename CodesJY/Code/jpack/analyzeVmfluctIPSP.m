function analyzeVmfluctIPSP(T, contacts, nontrials, prtl, wid, prefph, touchPSPdur, ampth, md, plot_ratio)

% prtl: percentile selection, e.g., 10th, this is the chosen baseline
% wid: whisker id
% prefph: preferred phase. if over pi, it means going through all whisking
% phases
% touchPSPdur about 0.2 sec, where to search the maximum depolarization
% ampth: amplitude threshold, where whisking is considered to be whisking
% md: min distance separation between peaks. in ms
% plot_ratio, if 0.25, means 25% of all figures will be plotted.

% analyze the amplitude of Vm fluctuations between truly-spontaneous,
% whisking, and touch periods. The baseline is the resting potential.

% nontrials are those that are not included, these could be stimulation
% trials, unstable trials, etc.
% every three trials, there will be an estimation of the baseline
twhiskorg=[0:1/1000:4.999];

md=md*10; % min distance between peaks.

% w_params=whiskdecomposej(wpos, tpos, twhiskorg);

file=dir('VthJY*.mat');
if ~isempty(file)
    load(file.name);
end;
trialnums=setdiff(T.trialNums, nontrials);
[Vm, ~, tvm]=findvmtrials(T, trialnums);

Vm=Vm(tvm<=5, :);
tvm=tvm(tvm<=5);

Vm=-Vm;
[b, a]=butter(4, 0.5*2/10000, 'high');
Vm=filtfilt(b, a, detrend(Vm));

baseline=zeros(1, size(Vm, 2));
tvm=tvm-0.01;

for i=1:size(Vm, 2)
    
    Vm_clust=Vm(:, i);
    
    Vm_clust=sgolayfilt(removeAP(Vm_clust, 10000, 5, 4), 3, 21);
    baseline(i)=prctile(Vm_clust(:), prtl);
end;


PSP_nw=[];
PSP_wh=[];
PSP_prefph=[];
PSP_touch=cell(1, length(contacts{5}.tid));
PSP_time=cell(1, length(contacts{5}.tid)); % this is the peak of touch evoked PSP
% now go through each trial

Vmph={}; % first row is alway whisking, second row is always Vm (raw, with spikes)
Spkph={};
phVm={};
[whiskingEpochs,nonWhiskingEpochs] = T.detectWhiskingEpochs(wid, trialnums, [5 65], 21, 100);

close all

tic
for i=1:length(trialnums)
    ivm=sgolayfilt(Vm(:, i), 3, 21);
    
    ivmnoap=sgolayfilt(removeAP(Vm(:, i), 10000, 5, 4), 3, 21); % remove AP
    spk=spikespy(Vm(:, i), 10000, 10, 4);
    
    itrialnum=trialnums(i);
    itrial=T.trials{T.trialNums==itrialnum};
    itouch=contacts{T.trialNums==itrialnum};
    
    touchtime=cell(1, length(itouch.tid));
    indtouch=cell(1, length(itouch.tid));
    
    touchofftime=cell(1, length(itouch.tid));
    indtouchoff=cell(1, length(itouch.tid));
    newtouch=cell(1, length(contacts{5}.tid));
    newtouchtime=cell(1, length(contacts{5}.tid));
    
    % licking time, need them so that we won't include them for whiksing or
    % nonwhisking
    licktime=itrial.behavTrial.beamBreakTimes;
    if isempty(licktime)
        licktime=-1;
    end;
    
    % touch PSPs
    
    for iw=1:length(itouch.tid)
        if ~isempty(itouch.contactInds{iw}) % there is touch on this whisker
            twhisk_iw=itrial.whiskerTrial.get_time(itouch.tid(iw)); % time stamps for this trial and this whisker
            touchtime{iw}=twhisk_iw(itouch.segmentInds{iw}(:, 1));
            
            if ~isempty(touchtime{iw})
                
                for k=1:length(touchtime{iw})
                    tPSP=find(tvm>=touchtime{iw}(k) & tvm<=touchtime{iw}(k)+touchPSPdur);
                    vmPSP=Vm(tvm>=touchtime{iw}(k) & tvm<=touchtime{iw}(k)+touchPSPdur, i);
                    
                    % if spike occurs, PSP peak is the spike threshold
                    % otherwise, PSP peak is the real peak.
                    
                    if any(find(spikespy(vmPSP, 10000, 20, 4)))
                        
                        spktime=Vth.spktime{Vth.trials==itrialnum}-0.01;
                        
                        indspkth=find(spktime>tvm(tPSP(1))+0.005,1, 'first');
                        
                        PSPpeak=Vth.threshold{Vth.trials==itrialnum}(indspkth);
                        PSP_time{iw}=[PSP_time{iw} spktime(indspkth)];
                        PSP_touch{iw}=[PSP_touch{iw}; PSPpeak-baseline(i)];
                        newtouch{iw}=[newtouch{iw} PSPpeak];
                        newtouchtime{iw}=[newtouchtime{iw} spktime(indspkth)];
                        
                    else
                        
                        [PSPpeak, indpeak_k]=max(ivmnoap(tPSP));
                        PSP_time{iw}=[PSP_time{iw} tvm(tPSP(indpeak_k))]; % time when peak occurs
                        PSP_touch{iw}=[PSP_touch{iw}; PSPpeak-baseline(i)];
                        
                        newtouch{iw}=[newtouch{iw} PSPpeak];
                        newtouchtime{iw}=[newtouchtime{iw} tvm(tPSP(indpeak_k))];
                    end;
                    
                end;
            end;
            
            touchofftime{iw}=twhisk_iw(itouch.segmentInds{iw}(:, 2));
            % findout the closest point in tvm
            indtouch{iw}=findclosest(touchtime{iw}, tvm);
            indtouchoff{iw}=findclosest(touchofftime{iw}, tvm);
        end;
    end;
    
    touch_blank=[min(cell2mat(touchtime)) max(cell2mat(touchofftime))];
    
    if isempty(touch_blank)
        touch_blank=[0 0];
    else
        touch_blank(2)=touch_blank(2)+0.5;
    end;
    
    alltouchon_thistrial=cell2mat(touchtime);
    alltouchoff_thistrial=cell2mat(touchofftime);
    
    
    iwhiskertrial=itrial.whiskerTrial;
    
    twhisk=itrial.whiskerTrial.get_time(wid);
    thetawhisk=itrial.whiskerTrial.get_thetaAtBase(wid);
    
    iwhisk_params=whiskdecomposej(thetawhisk, twhisk, twhiskorg);
    %% nonwhisking periods
    
    mindur=0.25; % has to be at least 0.5 second long, otherwise remove
    
    % passing amplitude
    nw_periods=nonWhiskingEpochs{i}; % in seconds, start and end
    nw_periods(nw_periods(:, 2)-nw_periods(:, 1)<mindur, :)=[];
    % touch should not be within "non whisking periods" or 150 ms near it
    
    nw_exclude=[];
    
    if ~isempty(nw_periods)
        for inw=1:size(nw_periods, 1)
            if any((nw_periods(inw, 1)-touch_blank(1)).*(nw_periods(inw, 2)-touch_blank(2))<0)...
                    ||mean(iwhisk_params.phase(iwhisk_params.twhisk>=nw_periods(inw, 1) & iwhisk_params.twhisk<=nw_periods(inw, 2)))>1.5...
                    ||any((nw_periods(inw, 1)-licktime).*(nw_periods(inw, 2)-licktime)<0)
                nw_exclude=[nw_exclude inw];
            end;
        end;
    end;
    
    nw_periods(nw_exclude, :)=[];
    
    % let's find out the peak depolarization during non whisking periods
    
    PSP_nw_itrial=[];
    t_nw_itrial=[];
    for inw=1:size(nw_periods, 1)
        tvm_inw=tvm(tvm>=nw_periods(inw, 1) & tvm<=nw_periods(inw, 2));
        vm_orginw=Vm(tvm>=nw_periods(inw, 1) & tvm<=nw_periods(inw, 2),i);
        vm_inw=ivmnoap(tvm>=nw_periods(inw, 1) & tvm<=nw_periods(inw, 2));
        
        if any(find(spikespy(vm_orginw, 10000, 20, 4))) % spikes occurs
            
            spktime=Vth.spktime{Vth.trials==itrialnum}-0.01;
            spkth=Vth.threshold{Vth.trials==itrialnum}(spktime>=nw_periods(inw, 1)&spktime<=nw_periods(inw, 2));
            spktime=spktime(spktime>=nw_periods(inw, 1)&spktime<=nw_periods(inw, 2));
            
            [PSP_nw_peaks, nw_peaks_locs]=findpeaks(vm_inw, 'minpeakdistance', md);
            
            % get rid of small fluctuations
            %             nw_peaks_locs=nw_peaks_locs(PSP_nw_peaks>prctile(ivmnoap, 50));
            %             PSP_nw_peaks=PSP_nw_peaks(PSP_nw_peaks>prctile(ivmnoap, 50));
            
            if ~isempty(spkth)
                if ~isempty(PSP_nw_peaks>min(spkth))
                    PSP_nw_peaks(PSP_nw_peaks>min(spkth))=min(spkth);
                end;
                
                if any(PSP_nw_peaks-baseline(i)>40)
                    itrialnum
                    error('too big');
                end;
                
                PSP_nw=[PSP_nw ;PSP_nw_peaks-baseline(i)];
                t_nw_itrial=[t_nw_itrial tvm_inw(nw_peaks_locs)]; % peak time in this trial, for plotting purpose
                
            else
                [PSP_nw_peaks, nw_peaks_locs]=findpeaks(vm_inw, 'minpeakdistance', md);
                PSP_nw=[PSP_nw ;PSP_nw_peaks-baseline(i)];
                t_nw_itrial=[t_nw_itrial tvm_inw(nw_peaks_locs)]; % peak time in this trial, for plotting purpose
            end;
            
        else
            
            [PSP_nw_peaks, nw_peaks_locs]=findpeaks(vm_inw, 'minpeakdistance', md);
            
            if any(PSP_nw_peaks-baseline(i)>100)
                itrialnum
                error ('too big')
            end;
           
            
            PSP_nw=[PSP_nw ;PSP_nw_peaks-baseline(i)];
            t_nw_itrial=[t_nw_itrial tvm_inw(nw_peaks_locs)]; % peak time in this trial, for plotting purpose
            
        end;
    end;
    
    
    %% whisking periods
    indnearph0=find(abs(iwhisk_params.phase)<0.1);
    indnearph0=indnearph0([1; 1+find(diff(indnearph0)>1)]); % this is supposely the peak of protraction
    
    % remove small or pseudo whisking peaks
    indnearph0(iwhisk_params.amp(indnearph0)<ampth)=[];
    
    % touch should not occur within 0.1 sec of indnearph0, before or after
    % indnearph0 should not occur within a touch either
    
    to_exclude=[];
    for iph=1:length(indnearph0)
        tph0=iwhisk_params.twhisk(indnearph0(iph));
        % no touch occurs before or after
        
        if isempty(nw_periods)
            if any(abs(tph0-touch_blank(1))<0.15)||any((tph0-touch_blank(1)).*(tph0-touch_blank(2))<0)...
                    ||tph0+0.1>max(iwhisk_params.twhisk) ||tph0-0.1<0 || any(abs(licktime-tph0)<0.15)
                % if repetitive licks occur during licks,disgard
                to_exclude=[to_exclude iph];
            end;
        else
            if any(abs(tph0-touch_blank(1))<0.15)||any((tph0-touch_blank(1)).*(tph0-touch_blank(2))<0)...
                    ||tph0+0.1>max(iwhisk_params.twhisk) ||tph0-0.1<0 || any((nw_periods(:, 1)-tph0).*(nw_periods(:, 2)-tph0)<0)|| any(abs(licktime-tph0)<0.15)
                to_exclude=[to_exclude iph];
            end
        end
    end;
    
    excluded=indnearph0(to_exclude);
    indnearph0(to_exclude)=[];
    
    
    hf(i)=figure(itrialnum); clf
    set(hf(i), 'units', 'centimeter', 'position', [1 2 22 18], 'paperpositionmode', 'auto')
    
    
    havm=subplot(3, 1, 3);
    plot(tvm, ivm, 'k')
    line([tvm(1) tvm(end)], [baseline(i), baseline(i)], 'color', 'b')
    hold on
    
    for iw=1:length(itouch.tid)
        if ~isempty(indtouch{iw})
            iwcolor=[0 0 0];
            if iw==1
                iwcolor(iw)=1;
            else
                iwcolor=[85 0 128]/255;
            end;
            plot(tvm(indtouch{iw}), ivm(indtouch{iw}), 'x', 'color', iwcolor)
            plot(tvm(indtouchoff{iw}), ivm(indtouchoff{iw}), '^', 'color', iwcolor)
            
            line([newtouchtime{iw}; newtouchtime{iw}], [repmat(baseline(i), 1, length(newtouch{iw})); newtouch{iw}], 'color', iwcolor)
        end;
    end;
    
    % plot PSP deps during non-whisking periods
    [~, ia, ~]=intersect(tvm, t_nw_itrial);
    
    line([t_nw_itrial;t_nw_itrial], [baseline(i)*ones(1, length(t_nw_itrial)); ivm(ia)'], 'color', [.75 .75 .75])
    
    set(gca, 'xlim', [0 5])
    title('Vm')
    ylabel('mV')
    xlabel('Time (s)')
    axis tight
    
    
    subplot(3, 1, 2)
    
    [hawhisk, py1, py2]=plotyy(iwhisk_params.twhisk, iwhisk_params.whiskpos, iwhisk_params.twhisk, iwhisk_params.amp);
    
    axes(hawhisk(1))
    hold on
    plot(iwhisk_params.twhisk(indnearph0), iwhisk_params.whiskpos(indnearph0), 'm*')
    if ~isempty(excluded)
        plot(iwhisk_params.twhisk(excluded), iwhisk_params.whiskpos(excluded), 'k*')
    end;
    
    ylabel('theta')
    
    axes(hawhisk(2))
    ylabel('amplitude')
    hold on
    plot(iwhisk_params.twhisk(indnearph0), iwhisk_params.amp(indnearph0), 'm*')
    line([min(iwhisk_params.twhisk) max(iwhisk_params.twhisk)], [ampth ampth], 'color', 'k', 'linestyle', ':')
    
    % plot in non whisking
    if ~isempty(nw_periods)
        for iiwh=1:size(nw_periods,1)
            nwepoch=nw_periods(iiwh, :);
            yrange=get(hawhisk(2), 'ylim');
            p = patch([nwepoch(1) nwepoch(1) nwepoch(2) nwepoch(2)], [yrange(1) yrange(2) yrange(2) yrange(1)],[1 0 0],'FaceAlpha',0.2,'EdgeColor','none', 'facecolor',[.5 .5 .5] );
            uistack(p,'bottom')
        end;
    end;
    
    if ~isempty(licktime)
        plot(licktime, mean(get(gca, 'ylim')), 'ko', 'markerfacecolor', 'k')
    end
    
    set(gca, 'xlim', [0 5])
    title('whisker position/amplitude')
    
    haph=subplot(3, 1, 1);
    
    plot(iwhisk_params.twhisk, iwhisk_params.phase, '.', 'color', [.75 .75 .75])
    hold on
    
    set(gca, 'xlim', [0 5])
    
    ylabel(['whisking phase'])
    
    linkaxes([havm,hawhisk, haph], 'x')
    
    title([T.cellNum ' trial ' num2str(itrialnum)])
    
    
    % go through each "whisking" cycle
    % indnearph0 is where ph is closest to 0, the most protraction point
    whiskstart=zeros(1, length(indnearph0));
    whiskend=zeros(1, length(indnearph0));
    
    to_exclude2nd=[];  % second round of exclusion
    %
    for iph=1:length(indnearph0)
        % find the closest min phase before this point
        
        diffph=iwhisk_params.phase-iwhisk_params.phase(indnearph0(iph));
        
        whiskstart(iph)=1+find((diffph')>2 & iwhisk_params.twhisk<iwhisk_params.twhisk(indnearph0(iph)), 1, 'last');
        
        whiskend(iph)=-1+find((diffph')<-2 & iwhisk_params.twhisk>iwhisk_params.twhisk(indnearph0(iph)), 1, 'first');
        
        
    end;
    %
    
    % next, go through each and every epoch of whisking
    ind_vm_prefph=cell(1,1);
    ind_whisk_prefph=cell(1, 1);
    
    for iph=1:length(indnearph0)
        ind_iphase=whiskstart(iph):whiskend(iph);
        t_iphase=iwhisk_params.twhisk(ind_iphase);
        iphase=iwhisk_params.phase(ind_iphase);
        ind_vm_cycle=find(tvm>=iwhisk_params.twhisk(whiskstart(iph)) & tvm<=iwhisk_params.twhisk(whiskend(iph)));
        % plot this cycle
        axes(haph)
        plot(iwhisk_params.twhisk(whiskstart(iph):whiskend(iph)), iwhisk_params.phase(whiskstart(iph):whiskend(iph)), 'g.');
        if ~any(diff(iphase)<0)
            
            % check if phase changes monotonically, if not, it won't go through
            % the phase analysis part.
            
            phVm=[phVm iphase];
            t_prefph=t_iphase(iphase>=prefph-pi/6 & iphase<=prefph+pi/6);
            ind_vm_prefph=[ind_vm_prefph {find(tvm>=min(t_prefph) & tvm<=max(t_prefph))}]; % corresponding index in tvm
            ind_whisk_prefph=[ind_whisk_prefph {find(iwhisk_params.twhisk>=min(t_prefph) & iwhisk_params.twhisk<=max(t_prefph))}];
            axes(haph)
            plot(iwhisk_params.twhisk(whiskstart(iph):whiskend(iph)), iwhisk_params.phase(whiskstart(iph):whiskend(iph)), '.', 'color', [0 .6 0]);
            plot(iwhisk_params.twhisk(ind_whisk_prefph{end}), iwhisk_params.phase(ind_whisk_prefph{end}), 'color', [0 .8 .9], 'marker', '.');
            axes(havm)
            % whisking phase and corresponding Vm
            plot(tvm(ind_vm_prefph{end}),ivm(ind_vm_prefph{end}), 'color', [0 .8 .9], 'marker', '.')
            Vmph=[Vmph {ivmnoap(ind_vm_cycle)}];
            Spkph=[Spkph {spk(ind_vm_cycle)}];
            
            % check if spike occurs, if so, cut the depolarization to spikes
            vmorg_prefph=Vm((ind_vm_prefph{end}), i); % raw
            
            if length(vmorg_prefph)>5 && any(find(spikespy(vmorg_prefph, 10000, 20, 4))) % spikes occurs
                
                spktime=Vth.spktime{Vth.trials==itrialnum}-0.01;
                spkth=Vth.threshold{Vth.trials==itrialnum}(spktime>=min(t_prefph) & spktime<=max(t_prefph));
                spktime=spktime(spktime>=min(t_prefph) & spktime<=max(t_prefph));
                
                [peak_PSP_prefph, indminspkth]=min(spkth);
                
                if ~isempty(peak_PSP_prefph)
                    PSP_prefph=[PSP_prefph; peak_PSP_prefph-baseline(i)];
                    
                    line([spktime(indminspkth) spktime(indminspkth)], [baseline(i) peak_PSP_prefph],'color', [0 .8 .9]);
                end;
                
            else
                
                [peak_PSP_prefph, loc_prefph]=max(ivmnoap(ind_vm_prefph{end})); % here I collect max Vm dep at pref. phase
                
                if ~isempty(peak_PSP_prefph)
                    
                    PSP_prefph=[PSP_prefph; peak_PSP_prefph-baseline(i)];
                    
                    line([tvm(ind_vm_prefph{end}(loc_prefph)) tvm(ind_vm_prefph{end}(loc_prefph))], [baseline(i) peak_PSP_prefph],'color', [0 .8 .9]);
                    
                end;
                
            end;
            
        end;
        
        % the whole cycle:
        vmorg_cycle=Vm((ind_vm_cycle), i); % raw
        
        if any(find(spikespy(vmorg_cycle, 10000, 20, 4)))  % spike occurs
            
            % tvm>=iwhisk_params.twhisk(whiskstart(iph)) & tvm<=iwhisk_params.twhisk(whiskend(iph))
            spktime=Vth.spktime{Vth.trials==itrialnum}-0.01;
            spkth=Vth.threshold{Vth.trials==itrialnum}(spktime>=iwhisk_params.twhisk(whiskstart(iph)) & spktime<=iwhisk_params.twhisk(whiskend(iph)));
            spktime=spktime(spktime>=iwhisk_params.twhisk(whiskstart(iph)) & spktime<=iwhisk_params.twhisk(whiskend(iph)));
            
            [minspkth, indminspkth]=min(spkth);
            
           
            [PSP_peaks, locs]=findpeaks(ivmnoap(ind_vm_cycle), 'minpeakdistance', md);
            %             locs=locs(PSP_peaks>prctile(ivmnoap, 50));
            %             PSP_peaks=PSP_peaks(PSP_peaks>prctile(ivmnoap, 50));
            if ~isempty(minspkth)
            PSP_peaks(PSP_peaks>=minspkth)=minspkth;
            end;
            
        else
            
            try
            [PSP_peaks, locs]=findpeaks(ivmnoap(ind_vm_cycle), 'minpeakdistance', md);
            %             locs=locs(PSP_peaks>prctile(ivmnoap, 50));
            %             PSP_peaks=PSP_peaks(PSP_peaks>prctile(ivmnoap, 50));
            %
            
            catch err
                PSP_peaks=[];
            end;
        end;
        
        if ~isempty(PSP_peaks)
            axes(havm)
            
            line([tvm(ind_vm_cycle(locs)); tvm(ind_vm_cycle(locs))], [baseline(i)*ones(1, length(PSP_peaks)); PSP_peaks'],'color', 'g');
            
            PSP_wh=[PSP_wh; PSP_peaks-baseline(i)]; % here i collect max Vm dep across a whisking cycle
            
            
        end;
    end;
    
    set(havm, 'children', flipud(get(havm, 'Children')));
    
    axes(haph)
    
    plot(iwhisk_params.twhisk(indnearph0), iwhisk_params.phase(indnearph0), 'm*', 'markersize', 6);
    
    if rand<(1-plot_ratio)
        close(hf(i))
    end;
    
    
    
end;

save vm_ph_coupling Vmph Spkph phVm

hfsum=figure;
set(hfsum, 'units', 'centimeter', 'position', [1 3 18 18], 'paperpositionmode', 'auto')


ha1=subplot(2, 1, 1);
plot(rand(1, length(PSP_nw)), -PSP_nw, 'k.'); hold on
plot(2+rand(1, length(PSP_wh)), -PSP_wh, 'g.')
plot(4+rand(1, length(PSP_prefph)), -PSP_prefph, '.', 'color', [0 0.8 0.9])
plot(6+rand(1, length(PSP_touch{wid+1})), -PSP_touch{wid+1}, 'r.')
set(gca, 'xlim', [-1 8], 'xtick', [.5, 2.5, 4.5 6.5])
ylabel('Depolarization (mV)')

ha2=subplot(2, 1, 2);

PSPall=-[PSP_nw; PSP_wh; PSP_prefph; PSP_touch{wid+1}];
conds_all=[repmat(.5, length(PSP_nw), 1); repmat(2.5, length(PSP_wh), 1); repmat(4.5, length(PSP_prefph), 1); repmat(6.5, length(PSP_touch{wid+1}), 1)];

boxplot(PSPall, conds_all);

toc

PSP.cell=[T.cellNum T.cellCode];
PSPout.nw=-PSP_nw;
PSPout.wh=-PSP_wh;
PSPout.prefph=-PSP_prefph;
PSPout.touch=cellfun(@(x)-x, PSP_touch, 'UniformOutput', false)
PSPout.vmph=cellfun(@(x)-x, Vmph, 'UniformOutput', false)
PSPout.Spkph=Spkph
PSPout.phVm=phVm;

phaseout=phasematching(phVm, cellfun(@(x)-x, Vmph, 'UniformOutput', false), Spkph);

save PSPout PSPout

% export_fig noise_distribution.eps
saveas(hfsum, 'noise_distribution', 'fig')


function indout=findclosest(tin, tref)

for i=1:length(tin)
    [~, indout(i)]=min(abs(tin(i)-tref));
end;



