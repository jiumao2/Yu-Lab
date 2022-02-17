function vmout=computetouch(T, whiskingvmout, th, wid, type, nbins, toplot,range, tosave, plotstim, yrange)

set(0, 'defaultaxesfontsize', 10);
% compute touch-evoked PSP from whiskingvmout
% results could either from any first touch or the first touch of a
% specific whisker
% tpre:50 ms, tpost: 200 ms;
% seperate stim versus no stim trials
% seperate go versus nogo touch

spikewidth=4;
if nargin<11
    yrange=[];
if nargin<10
    plotstim=1;
    if nargin<9
        tosave=0;
        if nargin<8
            range=[-100 500];
            if nargin<7
                toplot=0;
                if nargin<6
                    nbins=60;
                    if nargin<5
                        type='go';
                        if nargin<4
                            wid=[];
                            if nargin<3
                                th=5;
                            end;
                        end
                    end;
                end;
            end;
        end;
    end;
end;
end;

if isempty(th)
    th=whiskingvmout.spkth;
end;
psp.gonostim=[];
psp.nogonostim=[];
psp.gostim=[];
psp.nogostim=[];

spk.gonostim=[];
spk.gostim=[];
spk.nogonostim=[];
spk.nogostim=[];

tvm=whiskingvmout.tvm;

alltouchtrials=whiskingvmout.trialnum_touch;
alltouchtime=whiskingvmout.t_touch;
alltouchids=whiskingvmout.wid_contact;
stimnum=whiskingvmout.stimtrialnums;
nostimnum=whiskingvmout.nostimtrialnums;

touch_go_nums=intersect(alltouchtrials, [T.hitTrialNums T.missTrialNums]);
touch_nogo_nums=intersect(alltouchtrials, [T.correctRejectionTrialNums T.falseAlarmTrialNums]);

tvmtouch=[range(1):0.1:range(2)];

spkgostim=[];
spkgonostim=[];
spknogostim=[];
spknogonostim=[];

switch type
    
    case 'go'
        
        for i=1:length(touch_go_nums)
            touchnum=touch_go_nums(i);
            t_touch=alltouchtime(alltouchtrials==touchnum);
            touch_wid=alltouchids(alltouchtrials==touchnum);
            
            [dum, ind_touch]=min(abs(tvm-t_touch));
            ind_touch_epoch=[ind_touch+10*range(1):ind_touch+10*range(2)];
            
            if isempty(wid)  | ~isempty(intersect(touch_wid, wid))
                
                if any(intersect(touchnum, stimnum))
                    % stim trials
                    cvm=whiskingvmout.vm.stim_all(:, find(stimnum==touchnum));
                    spkgostim=[spkgostim spikespy(cvm(ind_touch_epoch), 10000, th, spikewidth)];
                    cvm=sgolayfilt(cvm, 3, 21);
                    psp.gostim=[psp.gostim cvm(ind_touch_epoch)];
                    
                    if toplot
                        figure(100);
                        plot(psp.gostim(:, end));
                        hold on
                        if ~isempty(find(spkgostim(:, end), 1))
                            plot(find(spkgostim(:, end)), psp.gostim(find(spkgostim(:, end)), end), 'ro');
                            pause;
                        end;
                        clf(100)
                    end;
                    
                else
                    % no stim trials
                    cvm=whiskingvmout.vm.nostim_all(:, find(nostimnum==touchnum));
                    spkgonostim=[spkgonostim spikespy(cvm(ind_touch_epoch), 10000, th, spikewidth)];
                    cvm=sgolayfilt(cvm, 3, 21);
                    psp.gonostim=[psp.gonostim cvm(ind_touch_epoch)];
                    
                    if toplot
                        figure(100);
                        plot(psp.gonostim(:, end));
                        hold on
                        if ~isempty(find(spkgonostim(:, end), 1))
                            plot(find(spkgonostim(: , end)), psp.gonostim(find(spkgonostim(: , end)), end), 'ro');
                            pause
                        end;
                        clf(100);
                    end;
                    
                end;
            end;
        end;
        [spk.gostim, spk.thist]=spikehisto(spkgostim, 10000, nbins);
        
        [spk.gonostim]=spikehisto(spkgonostim, 10000, nbins);
        
        spk.thist=1000*(spk.thist+range(1)/1000);
        
    case 'nogo'
         for i=1:length(touch_nogo_nums)
            touchnum=touch_nogo_nums(i);
            t_touch=alltouchtime(alltouchtrials==touchnum);
            touch_wid=alltouchids(alltouchtrials==touchnum);
            
            [dum, ind_touch]=min(abs(tvm-t_touch));
            ind_touch_epoch=[ind_touch+10*range(1):ind_touch+10*range(2)];
            
            if isempty(wid)  | ~isempty(intersect(touch_wid, wid))
                
                if any(intersect(touchnum, stimnum))
                    % stim trials
                    cvm=whiskingvmout.vm.stim_all(:, find(stimnum==touchnum));
                    spknogostim=[spknogostim spikespy(cvm(ind_touch_epoch), 10000, th, spikewidth)];
                    cvm=sgolayfilt(cvm, 3, 21);
                    psp.nogostim=[psp.nogostim cvm(ind_touch_epoch)];
                    
                    if toplot
                        figure(100);
                        plot(psp.nogostim(:, end));
                        hold on
                        if ~isempty(find(spknogostim(:, end), 1))
                            plot(find(spknogostim(:, end)), psp.nogostim(find(spknogostim(:, end)), end), 'ro');
                            pause;
                        end;
                        clf(100)
                    end;
                    
                else
                    % no stim trials
                    cvm=whiskingvmout.vm.nostim_all(:, find(nostimnum==touchnum));
                    spknogonostim=[spknogonostim spikespy(cvm(ind_touch_epoch), 10000, th, spikewidth)];
                    cvm=sgolayfilt(cvm, 3, 21);
                    psp.nogonostim=[psp.nogonostim cvm(ind_touch_epoch)];
                    
                    if toplot
                        figure(100);
                        plot(psp.nogonostim(:, end));
                        hold on
                        if ~isempty(find(spknogonostim(:, end), 1))
                            plot(find(spknogonostim(: , end)), psp.nogonostim(find(spknogonostim(: , end)), end), 'ro');
                            pause
                        end;
                        clf(100);
                    end;
                    
                end;
            end;
        end;
        [spk.nogostim, spk.thist]=spikehisto(spknogostim, 10000, nbins);
        
        [spk.nogonostim]=spikehisto(spknogonostim, 10000, nbins);
        
        spk.thist=1000*(spk.thist+range(1)/1000);
        
end;

%  [ histos, ts ] = spikehisto(spikesbycycle,samplerate,nbins)
% nbins=60;
%
% if isempty(spkgostim)
%     spkgostim=sparse(size(psp.gostim));
% end;
%
% if isempty(spkgonostim)
%     spkgonostim=sparse(size(psp.gonostim));
% end;


switch type
    
    case 'go'
        hf=figure;
        set(hf, 'units', 'centimeters', 'position', [10 2 12 12], 'paperpositionmode', 'auto');
        ha1=axes
        set(ha1, 'unit', 'normalized', 'position', [.15 .65 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        plot(tvmtouch, psp.gonostim, 'color', [.5 .5 .5])
        hold on
        plot(tvmtouch,mean(removeAP(psp.gonostim, 10000, 5, 4), 2), 'k', 'linewidth', 2);
        box off
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        title([type '-nostim,', 'n=' num2str(size(psp.gonostim, 2))])
        
        axis tight
        
        
        ha2=axes
        set(ha2, 'unit', 'normalized', 'position', [.15 .15 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        plot(tvmtouch, psp.gostim,  'color', [.5 .5 .5])
        hold on
        plot(tvmtouch,mean(removeAP(psp.gostim, 10000, 5 , 4), 2), 'b', 'linewidth', 2);
        box off
        axis tight
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        title([type '-M1 stim,' 'n=' num2str(size(psp.gostim, 2))])

        
        ha3=axes
        set(ha3, 'unit', 'normalized', 'position', [.65 .65 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        plot(tvmtouch,smooth(mean(removeAP(psp.gonostim, 10000, th, 4), 2), 20, 'moving'), 'k', 'linewidth', 2);
                if plotstim
            plot(tvmtouch,smooth(mean(removeAP(psp.gostim, 10000, th , 4), 2), 20, 'moving'), 'b', 'linewidth', 2);
        end;
        ylim=get(gca, 'ylim');
        line([0 0], ylim, 'color', [.6 .6 .6], 'linestyle', '--')
              box off
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        if isempty(wid)
            title('Avg. PSP-widall')
        else
            title(['Avg. PSP' '-wid' num2str(wid)]);
        end;
        axis tight
        
        ha4=axes
        set(ha4, 'unit', 'normalized', 'position', [.65 .15 .3 .2], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        bar(spk.thist, spk.gonostim, 'facecolor' ,'k', 'edgecolor', 'k')
        hold on
        if plotstim
            bar(spk.thist, spk.gostim, 'facecolor', 'b', 'edgecolor', 'b'); hold on
        end;
        ylim=get(gca, 'ylim');
        box off
        line([0 0], ylim, 'color', [.6 .6 .6], 'linestyle', '--')
        hold off
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        title('Avg. PSP')
        
        xlabel('Time (ms)')
        ylabel('Spk/s')
        set(gca, 'xlim', range)
        title ('PSTH')
        
    case 'nogo'
        
        hf=figure;
        set(hf, 'units', 'centimeters', 'position', [10 2 12 12], 'paperpositionmode', 'auto');
        ha1=axes
        set(ha1, 'unit', 'normalized', 'position', [.15 .65 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        plot(tvmtouch, psp.nogonostim, 'color', [.5 .5 .5])
                plot(tvmtouch,mean(removeAP(psp.nogonostim, 10000, 5, 4), 2), 'k', 'linewidth', 2);
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        title([type '-nostim,', 'n=' num2str(size(psp.nogonostim, 2))])
        axis tight
        
        ha2=axes
        set(ha2, 'unit', 'normalized', 'position', [.15 .15 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        plot(tvmtouch, psp.nogostim,  'color', [.5 .5 .5])
        plot(tvmtouch,mean(removeAP(psp.nogostim, 10000, 5 , 4), 2), 'b', 'linewidth', 2);
  
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        title([type '-M1 stim,' 'n=' num2str(size(psp.nogostim, 2))])
        axis tight
        
        ha3=axes;
        set(ha3, 'unit', 'normalized', 'position', [.65 .65 .3 .3], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]); 
        plot(tvmtouch,smooth(mean(removeAP(psp.nogonostim, 10000, 5, 4), 2), 20, 'moving'), 'k', 'linewidth', 2);
         if plotstim
            plot(tvmtouch,smooth(mean(removeAP(psp.nogostim, 10000, 5 , 4), 2), 20, 'moving'), 'b', 'linewidth', 2);
        end;
        ylim=get(gca, 'ylim');
        line([0 0], ylim, 'color', [.6 .6 .6], 'linestyle', '--')
        xlabel('Time (ms)')
        ylabel('Vm (mV)')
        if isempty(wid)
            title('Avg. PSP-widall')
        else
            title(['Avg. PSP' '-wid' num2str(wid)]);
        end;
        axis tight
        
        ha4=axes;
        set(ha4, 'unit', 'normalized', 'position', [.65 .15 .3 .2], 'nextplot', 'add', 'xlim', [min(tvmtouch) max(tvmtouch)]);
        bar(spk.thist, spk.nogonostim,'facecolor', 'k', 'edgecolor', 'k');
   
        if plotstim
            bar(spk.thist, spk.nogostim,'facecolor', 'b', 'edgecolor', 'b');
        end;
        ylim=get(gca, 'ylim');
        line([0 0], ylim, 'color', [.6 .6 .6], 'linestyle', '--')
 
        axis tight
        xlabel('Time (ms)')
        ylabel('Spk/s')
        set(gca, 'xlim', range)
        title ('PSTH')
end;

psp.tvm=tvmtouch;
vmout.psp=psp;
vmout.spk=spk;

if tosave
    saveas (hf, ['touch_activity_' type], 'fig')
    saveas(hf, ['touch_activity_' type], 'tif');
     saveas(hf, ['touch_activity_' type], 'pdf');
    print(hf, '-depsc', ['touch_activity_' type])
    
end



