function CompareRTs(ddat1, ddat2, name, groups)

if nargin<4
    groups={};
end;

figure(22); clf(22)
set(gcf, 'unit', 'centimeters', 'position',[2 2 12 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0.5 3.5],...
    'xtick', [1 2 3], 'xticklabel', {'500', '1000', '1500'},'ylim', [225 350])


for i = 1:length(ddat1.FPs)
    line([i i], ddat1.RTci_geo(i, :), 'color', 'b', 'linewidth', 1) 
    line([i i], ddat2.RTci_geo(i, :), 'color', 'b', 'linewidth', 1)
   
end

plot([1 2 3], ddat1.RTmean_geo, 'ko-', 'linewidth', 1)
plot([1 2 3], ddat2.RTmean_geo, 'ko:', 'linewidth', 1)

axis 'auto y'

ylims = get(gca, 'ylim');

if diff(ylims)<100
    dylim = (100-diff(ylim))/2;
    set(gca, 'ylim', [ylims(1)-dylim ylims(2)+dylim]);
end;

xlabel ('FP (ms)')
ylabel ('Reaction time (ms)');


cfolder=pwd;
if ispc
    ind=find(cfolder=='\');
else
    ind=find(cfolder=='/');
end;
anm_name = cfolder(ind(end)+1:end);

title (anm_name)

if ~isempty(groups)
    ha4=axes('unit', 'centimeters', 'position', [8.5 2 2 5], 'nextplot', 'add', 'xlim', [0 5],...
        'xtick', [1 2 3],'ylim', [0 10])
    
    axis off
    
    line([1 4], [8 8], 'linewidth', 1, 'color', 'k', 'linestyle', '-')
    text(1, 8.5, groups{1})
    
    line([1 4], [5 5], 'linewidth', 1, 'color', 'k', 'linestyle', ':')
    text(1, 5.5, groups{2})
end;


savename = ['MixedFPs_' anm_name name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')