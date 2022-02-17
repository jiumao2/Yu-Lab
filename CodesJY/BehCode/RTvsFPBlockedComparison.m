function RTvsFPBlockedComparison(name, varargin)

if nargin<2
    error('Need data')
end;

figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0 2500],...
    'xtick', [0:500:2000], 'ylim', [200 400])

FPall = [];
RTall = [];

for i = 1:length(varargin)
    
    FPall = [FPall varargin{i}.FPs];
    RTall = [RTall varargin{i}.RTmean_geo];
    
    line([varargin{i}.FPs varargin{i}.FPs], [varargin{i}.RTci_geo], 'color', 'b');
    
end;

plot(FPall, RTall, 'ko-', 'markersize', 6)
xlabel('FP (ms)')
ylabel('RT (ms)')
axis 'auto y'

if abs(diff(get(gca, 'ylim')))<100
    set(gca, 'ylim', [-50 50]+mean(RTall));
end;
title(name)

savename = ['RTvsFPFixed_' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])
saveas(gcf, savename, 'fig')



