function CompareRTsMultiple(dat, name, groups)

if nargin<3
    groups={};
end;

figure(22); clf(22)
set(gcf, 'unit', 'centimeters', 'position',[2 2 12 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0.5 3.5],...
    'xtick', [1 2 3], 'xticklabel', {'500', '1000', '1500'},'ylim', [225 350])

for k = 1:length(dat)
    for i = 1:length(dat(k).FPs)
        line([i i], dat(k).RTci_geo(i, :), 'color', 'b', 'linewidth', 1)
    end
    plot([1 2 3], dat(k).RTmean_geo, 'k.-', 'linewidth', k)
end;

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
    for i =1:length(groups)
    line([1 3], [8 8]-2*(i-1), 'linewidth', i, 'color', 'k', 'linestyle', '-')
    text(1, 8.5-2*(i-1), groups{i})
    end;
end;


savename = ['MixedFPs_' anm_name name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')