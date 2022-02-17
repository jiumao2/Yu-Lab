function whiskcorr=neuralphase(T, w, wid, wth, stim, stimmatch, tosave)

% w is whiskingvmout, which contains information such as contact time
% separating stim trials and non-stim trials
% non_stim trials

% add stimmatch 1.22.2014, 
% stimmatch limits the nostim data to where stim data are collected. 

% stim=1: blue, stim=2: orange

delay=0.05;
Fs=10000;

twhiskorg=[0:1/1000:4.999];
num_nostim=w.nostimtrialnums;
num_stim=w.stimtrialnums;

whiskvmxcorr_nostim=[];
whiskvmxcorr_stim=[];
whiskvmavg_nostim=[];
whiskavg_nostim=[];

whiskvmavg_stim=[];
whiskavg_stim=[];

whiskspk_nostim=[];
whiskwhiskxcorr_nostim=[];
whiskwhiskavg_nostim=[];

whiskspk_stim=[];
whiskwhiskxcorr_stim=[];
whiskwhiskavg_stim=[];

tvmavg=[-0.2*Fs:0.2*Fs]/10000;
twhiskavg=[-200:200]/1000;

whiskingstamp=w.whiskingstamp;

phasebins=[-180:30:180]*pi/180;

Vmphase_nostim=[];
spkphase_nostim=[];
Vmphase_stim=[];
spkphase_stim=[];
ncycle=0;
ncycle_stim=0;

for i=1:length(num_nostim)
    trialnum=num_nostim(i);
    
    [vm, vaom, tvm]=findvmtrials(T, trialnum);
    vm2=removeAP(vm, Fs, w.spkth, 4, 100, 8);
    spk=spikespy(vm, Fs, w.spkth, 4);
    
    aom_onset=find(vaom<0, 1, 'first')/10000+delay;
    aom_offset=find(vaom<0, 1, 'last')/10000;
    
    if ~stimmatch
        aom_onset=0.33;
        aom_offset=4;
    end;
    
    [wpos, tpos]=T.get_whisker_position(wid, trialnum);
    w_params=whiskdecomposej(wpos, tpos, twhiskorg);
    twhisk=w_params.twhisk+0.01;
    wpos=w_params.whiskpos;
    wposfilt=w_params.filtsignal;
    wphase=w_params.phase;
    
    phasecycle_begs=1+find(diff(wphase)<-3);
    phasecycle_ends=find(diff(wphase)<-3);
    
    phasecycle_begs=phasecycle_begs([1:end-1]);
    phasecycle_ends=phasecycle_ends([2:end]);
    
    if any(find(trialnum==whiskingstamp(:, 1)))
        whiskepochs_i=whiskingstamp(whiskingstamp(:, 1)==trialnum, [2 3]);
        t_touch=w.t_touch(w.trialnum_touch==trialnum);
        if isempty(t_touch)
            t_touch=5;
        end;
        for k=1:size(whiskepochs_i, 1)
            whisk_beg=whiskepochs_i(k, 1);
            whisk_end=min(whiskepochs_i(k, 2), t_touch-0.1);
            
            if whisk_end-whisk_beg>0.2 && whisk_beg>=aom_onset && whisk_end<=aom_offset % long enough to be counted as whisking bout
                indwhisk=find([twhisk>=whisk_beg & twhisk<=whisk_end]);
                indvm=find([tvm>=whisk_beg & tvm<=whisk_end]);
                twhiskbout=twhisk(indwhisk);
                whiskboutpos=wpos(indwhisk);
                phaseboutpos=wphase(indwhisk);
                whiskboutposfilt=wposfilt(indwhisk);
                vmbout=resample(detrend(removeAP(vm(indvm),Fs, w.spkth, 4, 100, 8), 'constant'), 1, 10);
                if length(whiskboutpos)>length(vmbout)
                    vmbout=padarray(vmbout, [length(whiskboutpos)-length(vmbout),0], 'post');
                else
                    whiskboutpos=padarray(whiskboutpos, [length(vmbout)-length(whiskboutpos), 0], 'post');
                end;
                [c, lags]=xcorr(vmbout, whiskboutpos, 200, 'coeff');
                c_whisk=xcorr(whiskboutpos, whiskboutpos, 200, 'coeff');
                whiskvmxcorr_nostim=[whiskvmxcorr_nostim c];
                whiskwhiskxcorr_nostim=[whiskwhiskxcorr_nostim c_whisk];
                if length(whiskboutposfilt)<10
                    pause
                end;
                [x, ix]=findpeaks(whiskboutposfilt, 'minpeakheight', wth, 'minpeakdistance', 10);
                
                if ~isempty(ix)
                    tpeaks=twhiskbout(ix);
                    for kp=1:length(ix)
                       [~, ind_peak]=min(abs(tvm-(tpeaks(kp)))); % peak index in Vm trace
                       [~, ind_peak2]=min(abs(tpeaks(kp)-twhisk)); % peak index in whisk trace
                    
                        if tvm(ind_peak)-0.2> min (tvm) && tvm(ind_peak)+0.2<max(tvm) && twhisk(ind_peak2)+0.2< max(twhisk) && twhisk(ind_peak2)-0.2>min(twhisk)
                            whiskvmavg_nostim=[whiskvmavg_nostim vm(ind_peak-0.2*Fs:ind_peak+0.2*Fs)];
                            whiskavg_nostim=[whiskavg_nostim wpos(ind_peak2-200:ind_peak2+200)];
                            
                            phasebeg_ind=phasecycle_begs(find(phasecycle_begs<ind_peak2,1, 'last'));
                            phaseend_ind=phasecycle_ends(find(phasecycle_ends>ind_peak2,1, 'first'));
                            
                            [Vmphase_nostim(:, end+1), aa , phasebincenter]=divideVmonphase(vm2(tvm>=twhisk(phasebeg_ind) & tvm<=twhisk(phaseend_ind)),  spk(tvm>=twhisk(phasebeg_ind) & tvm<=twhisk(phaseend_ind)), wphase(phasebeg_ind:phaseend_ind), phasebins);
                            
                            if isempty(spkphase_nostim)
                                spkphase_nostim=aa;
                            else
                                spkphase_nostim =  spkphase_nostim + aa;
                            end;
                            ncycle=ncycle+1;
                        end;
                    end;               
                end;
            end;
        end;
    end;
end;

% [spk.gostim, spk.thist]=spikehisto(spkgostim, 10000, nbins);
% whiskspkhist_nostim
whiskspk_nostim=spikespy(whiskvmavg_nostim, Fs, w.spkth, 4);
[whiskspkhist_nostim, thist]=spikehisto(whiskspk_nostim, 10000, 80);
thist=thist-0.2;


%% stim trials
for i=1:length(num_stim)
    trialnum=num_stim(i);
    
    [vm, aom, tvm]=findvmtrials(T, trialnum);
    tvm=tvm-0.01;
    vm2=removeAP(vm, Fs, w.spkth, 4, 100, 8);
    spk=spikespy(vm, Fs, w.spkth, 4);
    
    aom_onset=find(aom>1, 1, 'first')/10000+delay;
    aom_offset=find(aom>1, 1, 'last')/10000;
    
    [wpos, tpos]=T.get_whisker_position(wid, trialnum);
    w_params=whiskdecomposej(wpos, tpos, twhiskorg);
    twhisk=w_params.twhisk+0.01;
    wpos=w_params.whiskpos;
    wposfilt=w_params.filtsignal;
    wphase=w_params.phase;
    
    phasecycle_begs=1+find(diff(wphase)<-3);
    phasecycle_ends=find(diff(wphase)<-3);
    
    if any(find(trialnum==whiskingstamp(:, 1)))
        whiskepochs_i=whiskingstamp(whiskingstamp(:, 1)==trialnum, [2 3]);
        t_touch=w.t_touch(w.trialnum_touch==trialnum);
        if isempty(t_touch)
            t_touch=5;
        end;
        for k=1:size(whiskepochs_i, 1)
            whisk_beg=whiskepochs_i(k, 1);
            whisk_end=min(whiskepochs_i(k, 2), t_touch-0.1);
            
            if whisk_end-whisk_beg>0.2 && whisk_beg>=aom_onset && whisk_end<=aom_offset % long enough to be counted as whisking bout
                
                indwhisk=find([twhisk>=whisk_beg & twhisk<=whisk_end]);
                indvm=find([tvm>=whisk_beg & tvm<=whisk_end]);
                
                twhiskbout=twhisk(indwhisk);
                whiskboutpos=wpos(indwhisk);
                phaseboutpos=wphase(indwhisk);
                
                whiskboutposfilt=wposfilt(indwhisk);
                %
                vmbout=resample(detrend(removeAP(vm(indvm),Fs, w.spkth, 8, 100, 8), 'constant'), 1, 10);
                
                if length(whiskboutpos)>length(vmbout)
                    vmbout=padarray(vmbout, [length(whiskboutpos)-length(vmbout),0], 'post');
                else
                    whiskboutpos=padarray(whiskboutpos, [length(vmbout)-length(whiskboutpos), 0], 'post');
                end;
                
                [c, lags]=xcorr(vmbout, whiskboutpos, 200, 'coeff');
                c_whisk=xcorr(whiskboutpos, whiskboutpos, 200, 'coeff');
                
                whiskvmxcorr_stim=[whiskvmxcorr_stim c];
                whiskwhiskxcorr_stim=[whiskwhiskxcorr_stim c_whisk];
                
                [x, ix]=findpeaks(whiskboutposfilt, 'minpeakheight', wth, 'minpeakdistance', 10);
                
                if ~isempty(ix)
                    tpeaks=twhiskbout(ix);
                    for kp=1:length(ix)
                        [~, ind_peak]=min(abs(tvm-(tpeaks(kp)))); % peak index in Vm trace
                        [~, ind_peak2]=min(abs(tpeaks(kp)-twhisk)); % peak index in whisk trace
                        if tvm(ind_peak)-0.2> min (tvm) && tvm(ind_peak)+0.2<max(tvm) && twhisk(ind_peak2)+0.2< max(twhisk) && twhisk(ind_peak2)-0.2>min(twhisk)
                            whiskvmavg_stim=[whiskvmavg_stim vm(ind_peak-0.2*Fs:ind_peak+0.2*Fs)];
                            whiskavg_stim=[whiskavg_stim wpos(ind_peak2-200:ind_peak2+200)];
                            phasebeg_ind=phasecycle_begs(find(phasecycle_begs<ind_peak2,1, 'last'));
                            phaseend_ind=phasecycle_ends(find(phasecycle_ends>ind_peak2,1, 'first'));
                            [Vmphase_stim(:, end+1), aa, phasebincenter]=divideVmonphase(vm2(tvm>=twhisk(phasebeg_ind) & tvm<=twhisk(phaseend_ind)),  spk(tvm>=twhisk(phasebeg_ind) & tvm<=twhisk(phaseend_ind)), wphase(phasebeg_ind:phaseend_ind), phasebins);
                            if isempty(spkphase_stim)
                                spkphase_stim=aa;
                            else
                                spkphase_stim = spkphase_stim + aa;
                            end;
                            ncycle_stim=ncycle_stim+1;
                        end;
                    end;                   
                end;
                
            end;
        end;
    end;
end;

whiskspk_stim=spikespy(whiskvmavg_stim, Fs, w.spkth, 4);

tlags=lags/1000;

hf=figure;
set(hf, 'unit', 'centimeters', 'position', [2 2 12 12], 'paperpositionmode', 'auto');

% plot nostim
% cross-correlation:
ha1=axes;
if max(abs(mean(whiskvmxcorr_nostim, 2)))<0.2
    ymax=0.2;
else
    ymax=max(abs(mean(whiskvmxcorr_nostim, 2)));
end;
set(ha1, 'unit', 'normalized', 'position', [0.15 0.6 0.3 0.3],'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ylim', [-ymax ymax], 'ycolor','b', 'fontsize', 8, 'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
plot(tlags, mean(whiskvmxcorr_nostim, 2), 'b')

ha1b=axes;
set(ha1b, 'unit', 'normalized', 'position', [0.15 0.6 0.3 0.3],'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','k', 'fontsize', 8, 'YAxisLocation', 'right', 'color', 'none', 'nextplot', 'add')
plot(tlags, mean(whiskwhiskxcorr_nostim, 2), 'k')
line([0 0], get(ha1b, 'ylim'), 'color', [.8 .8 .8], 'linestyle', '-')

xlabel('Lag (s)')
ylabel('Auto-correlation')
title('M1 inactivation')

% % spikes:
% [whiskspkhist_nostim, thist]=spikehisto(whiskspk_nostim, 10000, 40);
% thist=thist-0.2;

ha2c=axes;
if 2*max(whiskspkhist_nostim)>10
    ymax=2*max(whiskspkhist_nostim);
else
    ymax=10;
end;
set(ha2c, 'unit', 'normalized', 'position', [0.15 0.15 0.3 0.2], 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2], 'ylim', [0 ymax],'ycolor','r', 'fontsize', 8,'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
bar(thist, whiskspkhist_nostim, 'facecolor','c', 'edgecolor', 'c')
line([0.15 0.15], [5 10], 'linestyle', '-', 'linewidth', 2, 'color', 'k')
axis off

vmtoplot=mean(removeAP(whiskvmavg_nostim, Fs, w.spkth, 4), 2);

if max(vmtoplot)-min(vmtoplot)<5
    ylim=[mean(vmtoplot)-2.5 mean(vmtoplot)+2.5]
else
    ylim=[min(vmtoplot) max(vmtoplot)];
end;

ha2=axes;
set(ha2, 'unit', 'normalized', 'position', [0.15 0.15 0.3 0.3],'ylim', ylim, 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','r', 'fontsize', 8,'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
plot(tvmavg, mean(removeAP(whiskvmavg_nostim, Fs, w.spkth, 4), 2), 'r')

ha2b=axes;
set(ha2b, 'unit', 'normalized', 'position', [0.15 0.15 0.3 0.3], 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','k', 'fontsize', 8,'YAxisLocation', 'right', 'color', 'none', 'nextplot', 'add')
plot(twhiskavg, mean(whiskavg_nostim, 2), 'k')
line([0 0], get(ha2b, 'ylim'), 'color', [.8 .8 .8], 'linestyle', '-')
ylabel('Whisking angle')
xlabel('Lag (s)')

% plot stim
% cross-correlation:
ha1=axes;
if max(abs(mean(whiskvmxcorr_stim, 2)))<0.2
    ymax=0.2;
else
    ymax=max(abs(mean(whiskvmxcorr_stim, 2)));
end;
set(ha1, 'unit', 'normalized', 'position', [0.6 0.6 0.3 0.3],'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ylim', [-ymax ymax], 'ycolor','b', 'fontsize', 8, 'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
plot(tlags, mean(whiskvmxcorr_stim, 2), 'b')

ha1b=axes;
set(ha1b, 'unit', 'normalized', 'position', [0.6 0.6 0.3 0.3],'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','k', 'fontsize', 8, 'YAxisLocation', 'right', 'color', 'none', 'nextplot', 'add')
plot(tlags, mean(whiskwhiskxcorr_stim, 2), 'k')
line([0 0], get(ha1b, 'ylim'), 'color', [.8 .8 .8], 'linestyle', '-')

xlabel('Lag (s)')
ylabel('Auto-correlation')
title('M1 inactivation')

% spikes:
[whiskspkhist_stim, thist]=spikehisto(whiskspk_stim, 10000, 80);
thist=thist-0.2;

ha2c=axes;
if 2*max(whiskspkhist_stim)>10
    ymax=2*max(whiskspkhist_stim);
else
    ymax=10;
end;
set(ha2c, 'unit', 'normalized', 'position', [0.6 0.15 0.3 0.2], 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2], 'ylim', [0 ymax],'ycolor','r', 'fontsize', 8,'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
bar(thist, whiskspkhist_stim, 'facecolor','c', 'edgecolor', 'c')
line([0.15 0.15], [5 10], 'linestyle', '-', 'linewidth', 2, 'color', 'k')
axis off

if max(mean(whiskvmavg_stim, 2))-min(mean(whiskvmavg_stim, 2))<5
    ylim2=[mean(whiskvmavg_stim(:))-2.5 mean(whiskvmavg_stim(:))+2.5]
else
    ylim2=[min(mean(whiskvmavg_stim, 2)) max(mean(whiskvmavg_stim, 2))];
end;

ha2=axes;
set(ha2, 'unit', 'normalized', 'position', [0.6 0.15 0.3 0.3],'ylim', ylim2, 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','r', 'fontsize', 8,'YAxisLocation', 'left', 'color', 'none', 'nextplot', 'add')
plot(tvmavg, mean(removeAP(whiskvmavg_stim, Fs, w.spkth, 4), 2), 'r')

ha2b=axes;
set(ha2b, 'unit', 'normalized', 'position', [0.6 0.15 0.3 0.3], 'xlim', [-0.2 0.2], 'xtick', [-.2 -.1 0 .1 .2],'ycolor','k', 'fontsize', 8,'YAxisLocation', 'right', 'color', 'none', 'nextplot', 'add')
plot(twhiskavg, mean(whiskavg_stim, 2), 'k')

line([0 0], get(ha2b, 'ylim'), 'color', [.8 .8 .8], 'linestyle', '-')
ylabel('Whisking angle')
xlabel('Lag (s)')

hcontrol=uicontrol('style', 'text', 'unit', 'normalized', 'position', [.3 .01 .4 .05],...
    'string', [T.cellNum T.cellCode], 'backgroundcolor', [1 1 1])

hf2=figure;

set(hf2, 'unit', 'centimeters', 'position', [4 2 5 12], 'paperpositionmode', 'auto');


ha1=axes;
set(ha1, 'unit', 'normalized', 'position', [0.3 0.1 0.6 0.1], 'xlim', [-100 100], 'xtick', [-200:100:200],'ycolor','k', 'fontsize', 10,'YAxisLocation', 'left', 'nextplot', 'add')
bar(thist*1000, whiskspkhist_nostim, 'facecolor','k', 'edgecolor', 'k')
axis 'auto y'

y2=get(gca, 'ylim');
if y2(2)-y2(1)<5
    set(gca, 'ylim', [0 5]);
end;

xlabel('Lag (ms)')
ylabel('Spk/s')

ha2=axes;
set(ha2, 'unit', 'normalized', 'position', [0.3 0.3 0.6 0.25],'ylim', ylim, 'xlim', [-100 100], 'xtick', [-200:100:200],'ycolor','k', 'fontsize', 10,'YAxisLocation', 'left', 'nextplot', 'add')
plot(tvmavg*1000, mean(removeAP(whiskvmavg_nostim,Fs, w.spkth, 4, 100, 8), 2), 'k')

y2=get(gca, 'ylim');
if y2(2)-y2(1)<3
    set(gca, 'ylim', [round(mean(y2))-2 round(mean(y2))+2]);
end;

xlabel('Lag (ms)')
ylabel('Vm (mV)')

ha2b=axes;
set(ha2b, 'unit', 'normalized', 'position', [0.3 0.65 0.6 0.25], 'xlim', [-100 100], 'xtick', [-200:100:200],'ycolor','k', 'fontsize', 10,'nextplot', 'add')
plot(twhiskavg*1000, mean(whiskavg_nostim, 2), 'k')
line([0 0], get(ha2b, 'ylim'), 'color', [.8 .8 .8], 'linestyle', '-')
ylabel('Whisking angle')
xlabel('Lag (ms)')


whiskcorr.cell=[T.cellNum T.cellCode];
whiskcorr.whiskvmavg_nostim=whiskvmavg_nostim;
whiskcorr.whiskvmavg_stim=whiskvmavg_stim;
whiskcorr.tvmavg=tvmavg;

whiskcorr.whiskvmxcorr_nostim=whiskvmxcorr_nostim;
whiskcorr.whiskvmxcorr_stim=whiskvmxcorr_stim;

whiskcorr.whiskavg_nostim=whiskavg_nostim;
whiskcorr.whiskavg_stim=whiskavg_stim;
whiskcorr.twhiskavg=twhiskavg;

whiskcorr.whiskspk_nostim=whiskspk_nostim;
whiskcorr.whiskspkhist_nostim=whiskspkhist_nostim;
whiskcorr.whiskspk_stim=whiskspk_stim;
whiskcorr.whiskspkhist_stim=whiskspkhist_stim;
whiskcorr.thist=thist;

whiskcorr.phasebincenters=phasebincenter;
whiskcorr.Vmphase_nostim=Vmphase_nostim;
whiskcorr.Vmphase_stim=Vmphase_stim;
whiskcorr.spkphase_nostim=spkphase_nostim(1, :)./ncycle;
whiskcorr.spkphase_stim=spkphase_stim(1, :)./ncycle_stim;

set(gcf, 'userdata', whiskcorr);

phasefinding(whiskcorr, stim, 1)

if tosave
    
    save whiskcorr whiskcorr
    
    if ~stim
        saveas(hf, ['whiskingvmxcorr'], 'fig')
        saveas(hf2, ['whiskingvmxcorr2'], 'fig')
        
        export_fig(hf, ['whiskingvmxcorr'], '-tiff')
        export_fig (hf2,  ['whiskingvmxcorr2', '-tiff']);
        
    else
        
        saveas(hf, ['whiskingvmxcorr_stim'], 'fig')
        saveas(hf2, ['whiskingvmxcorr2_stim'], 'fig')
        
        export_fig(hf, ['whiskingvmxcorr_stim'], '-tiff')
        export_fig (hf2,  ['whiskingvmxcorr2_stim', '-tiff']);
        
        
    end
end;


function   [vmphasebin, spkphasebin, phasebincenter]=divideVmonphase(vm, spk, phaseall, phasebins)

tphase=[0:length(phaseall)-1];
tvm=[0:length(vm)-1]/10;
spkphasebin=zeros(2, length(phasebins)-1);

for i=1:length(phasebins)-1
    ind=find(phaseall>=phasebins(i) & phaseall<phasebins(i+1));
    if ~isempty(ind)
        indvm=[tvm>=tphase(ind(1)) & tvm<tphase(ind(end))];
        if ~isempty(indvm)
            vmphasebin(i)=mean(vm(indvm));
            spkphasebin(:, i)=[length(find(spk(indvm))); ((length(find(indvm))/10000))]; % [number of spikes length of data]
        else
            vmphasebin(i)=NaN;
            spkphasebin(:, i)=[0; 0];
        end;
    else
        vmphasebin(i)=NaN;
        spkphasebin(:, i)=[0; 0];
    end;
    
    phasebincenter(i)=mean([phasebins(i), phasebins(i+1)]);
    
end;
