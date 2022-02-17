function CheckNEVSpikes32(NEV)

allcolors = {'b', 'r', 'c', 'm', 'g'};

spktag = NEV.Data.Spikes;
nchns = [1:32];
hf=figure(100); clf;
set(gcf, 'unit', 'centimeters', 'position',[2 2 30 15], 'paperpositionmode', 'auto' )


for i = 1:length(nchns)
    ich = nchns(i);
    ha(i)=subplot(4, 8, i);
    set(ha(i), 'nextplot', 'add', 'ylim', [-500 500], 'xlim', [0 48])
    title(num2str(i))
    ind_electrodes = find(NEV.Data.Spikes.Electrode == ich);
    units_all = NEV.Data.Spikes.Unit(ind_electrodes);
    
    units_sorted = setdiff(units_all, 0);
    if ~isempty(units_sorted)
        
        sorted_waves = cell(1, length(units_sorted));
        
        for k =1:length(units_sorted)
            
            iunit = units_sorted(k);
            
            ind_spk = intersect(ind_electrodes, find(NEV.Data.Spikes.Unit==iunit));
            
            kwaves = NEV.Data.Spikes.Waveform(:, ind_spk);
            
            plot(ha(i), mean(kwaves, 2), 'color', allcolors{k})
            
            text(40, 0.25*(k-1)*max(get(gca, 'ylim')), num2str(size(kwaves, 2)), 'color', allcolors{k})
        end;
    end;
end;

print (gcf,'-dpng', ['NEV' NEV.MetaTags.Filename])

 