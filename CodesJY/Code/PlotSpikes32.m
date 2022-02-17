function PlotSpikes32(r)

% plot spikes across 16 channels

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 28 15], 'paperpositionmode', 'auto' ,'color', 'w')

cluster_colors = {'b', 'r', 'g', 'c', 'm', 'k', 'b', 'r', 'g', 'c', 'm', 'k'};

chs = [1:16 33:48];

for i =1:32
    if i<=16
        ha(i) =  subplot(4, 16, i);
    else
        ha(i) =  subplot(4, 16, (i-16)+32);
    end;
    set(ha(i), 'xlim', [0 65], 'ylim', [-1000 1000],'xtick',  [], 'ytick', [], 'nextplot', 'add')
    title(['#', num2str(chs(i))], 'fontsize', 8)
    box on
end;

for i =1:32
    if i<=16
        ha2(i) =  subplot(4, 16, i+16);
    else
        ha2(i) =  subplot(4, 16, (i-16)+16*3);
    end;
    set(ha2(i), 'xlim', [0 20], 'ylim', [0 200],'xtick', [5 10 15], 'ytick', [], 'nextplot', 'add')
    box on
end;

% plot spikes

for j =1:size(r.Units.SpikeNotes, 1)
    
    ich = r.Units.SpikeNotes(j, 1);
    
    ind_axes = find(chs == ich);
    
    icl = r.Units.SpikeNotes(j, 2);  
    
    spkwave = r.Units.SpikeTimes(j).wave;
    
    if size(spkwave, 2)>64
        spkwave=spkwave(:, 1:64);
    end;
    
    wave_std = std(spkwave, [], 1);
    wave_se = wave_std;
    spkwavemean = mean(spkwave, 1);
    
    axes(ha(ind_axes))
    plot([1:64], [spkwavemean-wave_se], 'k:'); hold on
    plot([1:64], [spkwavemean+wave_se], 'k:')
    
    plot([1:64], spkwavemean, 'linewidth',1.5, 'color', cluster_colors{icl})
    
    axis tight 
    
    %%
    axes(ha2(ind_axes))
    spktime = r.Units.SpikeTimes(j).timings;
    isi = diff(spktime);
    
    edges = [0:1:25];
    cen = mean(edges(1:end-1), edges(2:end));
    
    histogram(isi, edges);
    
end;

uicontrol('parent', gcf, 'style', 'text', 'unit', 'normalized',...
    'position', [0.02 0.4 0.1 0.1], 'string', [r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)])

print (gcf,'-dpng', ['SpikeOverview' ]) 