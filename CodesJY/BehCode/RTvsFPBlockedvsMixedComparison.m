function RTvsFPBlockedvsMixedComparison(name, mixedRT, varargin)

if nargin<2
    error('Need data')
end;

figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0 2500],...
    'xtick', [0:500:2500], 'ylim', [200 400])

FPall = [];
RTall = [];

if length(varargin)>0
    
    for i = 1:length(varargin)
        FPall = [FPall varargin{i}.FPs];
        RTall = [RTall varargin{i}.RTmean_geo];
        
        line([varargin{i}.FPs varargin{i}.FPs], [varargin{i}.RTci_geo], 'color', 'b');
        
    end;
    
    plot(FPall, RTall, 'ko-', 'markersize', 6)
    
    text (FPall(end)+100, RTall(end), 'const')
end;

xlabel ('Foreperiod (ms)')
ylabel ('Reaction time (ms)')

%% add mixed FP data
for i = 1:length(mixedRT.FPs)
    
   line([mixedRT.FPs(i) mixedRT.FPs(i)], [mixedRT.RTci_geo(i, :)], 'color', 'b');
  
end;

plot(mixedRT.FPs, mixedRT.RTmean_geo, 'ko:', 'markersize', 6, 'linewidth', 2)
text (mixedRT.FPs(end)+100, mixedRT.RTmean_geo(end), 'mixed')

axis 'auto y'

if abs(diff(get(gca, 'ylim')))<100
    
    ylims = get(gca, 'ylim');
    dylims = (100-diff(ylims))/2;
    
    set(gca, 'ylim', [ylims(1)-dylims ylims(2)+dylims]);
end;
title(name)

savename = ['RTvsFPFixed_' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])
saveas(gcf, savename, 'fig')



