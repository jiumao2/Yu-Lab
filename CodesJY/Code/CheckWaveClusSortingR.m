function CheckWaveClusSortingR(r, tbegorg)
% chname can ben chdat2
if nargin<2
    tbegorg=[];
end;

figure(23); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 15], 'paperpositionmode', 'auto' )

tdur=10;
toplot=1;

tLeverPress = r.Behavior.Onset{find(strcmp(r.Behavior.EventLabels, 'GoodPress'))};
tGoodRelease = r.Behavior.Onset{find(strcmp(r.Behavior.EventLabels, 'GoodRelease'))};
tTrigger = r.Behavior.Onset{find(strcmp(r.Behavior.EventLabels, 'Trigger'))};
if size(tTrigger, 1)<size(tTrigger,2)
    tTrigger=tTrigger';
end;
tPoke= r.Behavior.Onset{find(strcmp(r.Behavior.EventLabels, 'Poke'))};
tRew= r.Behavior.Onset{find(strcmp(r.Behavior.EventLabels, 'Valve'))};

    if isempty(tbegorg)
        tbeg = 0;
    else
        tbeg=tbegorg;
    end;
while toplot
    clf(23)
    set(gcf, 'unit', 'centimeters', 'position',[2 2 15 15], 'paperpositionmode', 'auto' )


    tend =[tbeg+tdur];
    tplot=[tbeg tend];
    
    % spike channels
    ha0 =axes; cla (ha0, 'reset')
    set(ha0, 'units', 'normalized', 'position', [.85 .65 .1 .3], 'xlim',[0 5], 'ylim', [0 10], 'nextplot', 'add', 'fontsize', 8)
    
    
    text(0, 1, 'LeverPress', 'color', 'k', 'fontsize', 9)
    text(0, 2, 'Poke', 'color', 'b', 'fontsize', 9)
    text(0, 3, 'GoodRelease', 'color', 'm', 'fontsize', 9)
    text(0, 4, 'Trigger', 'color', 'c', 'fontsize', 9)
    text(0, 5, 'Reward', 'color', 'g', 'fontsize', 9)
    axis off
    
    % spike channels
    ha1 =axes; cla (ha1, 'reset')
    set(ha1, 'units', 'normalized', 'position', [.1 .55 .7 .4], 'xlim', tplot, 'ylim', [0 size(r.Units.SpikeReg, 1)], 'nextplot', 'add', 'fontsize', 8)
    xlabel('Time (s)')
    
    line([tLeverPress tLeverPress]'/1000, get(gca, 'ylim'),'color', 'k', 'linestyle', ':', 'linewidth', 1)
    line([tPoke tPoke]'/1000, get(gca, 'ylim'),'color', 'b', 'linestyle', ':', 'linewidth', 1)
    line([tGoodRelease tGoodRelease]'/1000, get(gca, 'ylim'),'color', 'm', 'linestyle', ':', 'linewidth', 1)
    line([tTrigger tTrigger]'/1000, get(gca, 'ylim'),'color', 'c', 'linestyle', ':', 'linewidth', 1)
    line([tRew tRew]'/1000, get(gca, 'ylim'),'color', 'g', 'linestyle', ':', 'linewidth', 1)
    
     
    spkchs = unique(r.Units.SpikeReg(:, 1));
    allcolors = varycolor(length(spkchs));
    % put spikes to spike matrix
    for i = 1:size(r.Units.SpikeReg, 1)
        
        channel_id = r.Units.SpikeReg(i, 1);
        spkmat = r.Units.SpikeMat(i, :);
        tspkmat= r.Units.tSpk;
        % load spike time:
        
        spktimes_i =tspkmat(find(spkmat));  % in ms
        
        x_plot = spktimes_i(spktimes_i>=tplot(1)*1000 & spktimes_i<=tplot(2)*1000);
        x_plot = [x_plot; x_plot]/1000;
        y_plot = [i i+0.8]-1;
        
        if ~isempty(x_plot)
            plot(ha1, x_plot, y_plot, 'color', allcolors(spkchs==channel_id, :),'linewidth', 1);
        end;
        text(tplot(2), mean(y_plot), num2str(channel_id), 'fontsize', 7)
    end;
    
    %% add behavior events 
    % LFP channels
    ha2 =axes; cla (ha2, 'reset')
    set(ha2, 'units', 'normalized', 'position', [.1 .2 .7 .25],...
        'xlim', tplot, 'ylim', [-300 100*size(r.FP.channels, 1)+400], 'nextplot', 'add', 'fontsize', 8)

    for i = 1:size(r.FP.channels, 1)
        
        fpi=r.FP.data{i};
        tfpi = fpi(:, 1);
        ch_id = r.FP.channels(i);
        plotindex = find(tfpi>=tplot(1)*1000 & tfpi<=tplot(2)*1000);
        
        [b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
        data_plot_hp = filtfilt(b_detect, a_detect, fpi(plotindex, 2)); % band pass 2-200 hz
         
        
        [b_detect,a_detect] = butter(2, [2 200]*2/30000, 'bandpass');  % field potential
        data_plot_band = filtfilt(b_detect, a_detect, fpi(plotindex, 2)); % band pass 2-200 hz 
        
        tfpi = tfpi(plotindex);
        
        if ch_id<17
            plot(tfpi/1000, i*100+data_plot_band/5, 'k');
        else
            plot(tfpi/1000, i*100+data_plot_band/5, 'b');
        end;
        
        text(tplot(2), mean(i*100+data_plot_band/5), num2str(ch_id), 'fontsize', 7)
    end;
    
    reply = input('Keep showing Y/N [Y]:', 's');
    if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
        toplot =1;
    else
        toplot=0;
    end;
    
    
    tbeg = tend;
    
end;
% 
% linkaxes([ha1 ha4], 'x')
% 
% reply = input('Save this pic? Y/N [Y]:', 's');
% if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
%     print (gcf,'-dpng', ['waveclus_chdat' chname '_t' num2str(round(tbeg)) 's'])
% end;
% 
