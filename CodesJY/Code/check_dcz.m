all_cells = {
    % filename, filename, clusterid
    'chdat4.mat'         'times_chdat_meansub4.mat'         1
    'chdat8.mat'         'times_chdat_meansub8.mat'         1
    'chdat14.mat'       'times_chdat_meansub14.mat'       1
};

AllRateOut = [];

for i =1:size(all_cells, 1)

    icell = all_cells{i, 1};
    icell = icell(1:end-4);
 
    if i==1
   AllRateOut = PlotDCZEffectSingleCell(all_cells(i, :), 'tDCZ', 21*60, 'cluster', all_cells{i, 3}, 'KernelSize', 10000,  'filename', [icell '_' num2str(all_cells{i, 3})],...
       'TimeSegments', [10 1100; 1330 2200; 5718 6710]);
    else
   AllRateOut(i) = PlotDCZEffectSingleCell(all_cells(i, :), 'tDCZ', 21*60, 'cluster', all_cells{i, 3}, 'KernelSize', 10000,  'filename', [icell '_' num2str(all_cells{i, 3})],...
       'TimeSegments', [10 1100; 1330 2200; 5718 6710]);
    end;
 
end;

save AllRateOut AllRateOut


hf=24;
figure(hf); clf(hf) 
set(gcf, 'unit', 'centimeters', 'position', [2 2 8 5], 'paperpositionmode', 'auto','renderer','Painters')
ha1= axes('unit', 'centimeters', 'position', [1.5 1 5.5 3], ...
    'xlim', [0 4],'xtick', [1 2 3], 'xticklabel', {'Pre', 'Post1', 'Post2'}, 'yscale', 'linear',...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);

for i =1:length(AllRateOut)
    line([1 2 3],AllRateOut(i).MeanSpks, 'color', 'k', 'linewidth', 1)
     plot([1 2 3], AllRateOut(i).MeanSpks, 'o', 'color', 'k')
end
ylabel('Firing rate (spk per sec)')

thisFolder = fullfile(pwd, 'Fig');

tosavename= fullfile(thisFolder,  ['DCZ_effect']);

print (hf,'-dpng', tosavename);
print (hf,'-depsc2', tosavename);
