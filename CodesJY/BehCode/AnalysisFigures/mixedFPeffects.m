function mixedFPeffects

RTmixedall = struct('FPs', [], 'RTmean', [], 'RTci', [], 'RTHistory', [], 'SequentialRTmean', [], 'SequentialRTci', []);

% Steve
if ispc
    load(fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Steve', 'RTMixed_STEVE.mat'));
else
    load(fullfile('/Users/jianingyu/OneDrive/Work/Behavior/BehaviorData/Steve', 'RTMixed_STEVE.mat'));
end;

RTmixedall(1) = RTMixed;

% John
if ispc
    load(fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\John', 'RTMixed_JOHN.mat'));
else
    load(fullfile('/Users/jianingyu/OneDrive/Work/Behavior/BehaviorData/John', 'RTMixed_JOHN.mat'));
end;
RTmixedall(2) = RTMixed;

% Bob
if ispc
    load(fullfile('C:\Users\jiani\OneDrive\Work\Behavior\BehaviorData\Bob', 'RTMixed_BOB.mat'));
else
    load(fullfile('/Users/jianingyu/OneDrive/Work/Behavior/BehaviorData/Bob', 'RTMixed_BOB.mat'));
end;
RTmixedall(3) = RTMixed;

figure(25); clf(25)
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0.5 3.5],...
    'xtick', [1 2 3], 'xticklabel', {'500', '1000', '1500'},'ylim', [250 400])


for k = 1:length(RTmixedall)
    for i = 1:length(RTmixedall(k).FPs)
        line([i i]+0.0*k, RTmixedall(k).RTci(i, :), 'color', 'b', 'linewidth', 1)
    end
        plot([1 2 3]+0.0*k, RTmixedall(k).RTmean, 'ko-', 'linewidth', 1)

end;

xlabel ('FP (ms)')
ylabel ('Reaction time (ms)');

if ispc
    tosave= 'C:\Users\jiani\OneDrive\Work\Behavior\Figures'
    
    savename = fullfile(tosave, 'RTvsMixedFPs');
    print (gcf,'-dpng', [savename])
    print (gcf,'-dpdf', [savename])
    saveas(gcf, savename, 'fig')
    
else
    tosave= '/Users/jianingyu/OneDrive/Work/Behavior/Figures'
    
    savename = fullfile(tosave, 'RTvsMixedFPs');
    print (gcf,'-dpng', [savename])
    print (gcf,'-dpdf', [savename])
    saveas(gcf, savename, 'fig')
    
    
end;

saveas(gcf, savename, 'fig')




%                   RTMixed = 
%                   FPs: [500 1000 1500]
%                   RTmean: [286.6378 274.2830 266.1466]
%                   RTci: [3�2 double]
%                   SequentialRTmean: [3�3 double]
%                   SequentialRTci: [3�3�2 double]

figure(26); clf(26)
set(gcf, 'unit', 'centimeters', 'position',[2 2 17 8], 'paperpositionmode', 'auto' )




for k = 1:length(RTmixedall)
    RT=RTmixedall(k);
    nFP=length(RT.FPs);
    FPMixed = RT.FPs;
    ciRT = RT.SequentialRTci;
    meanRT=RT.SequentialRTmean;
    
    ha1(k)=axes('unit', 'centimeters', 'position', [2+(k-1)*5 2 4 4],...
        'nextplot', 'add', 'xlim', [250 1750], 'xtick', [500:500:2000], 'ylim', [250 400], 'ytick', [200:50:500])
    
    for i = 1:nFP
        
        for j = 1:nFP  % current
            ciRTj = squeeze(ciRT(i, j, :));
            
            line([FPMixed(j) FPMixed(j)], ciRTj, 'color', 'b', 'linewidth', 1)
            
        end;
        
        plot(FPMixed, meanRT(i, :), 'ko',  'linewidth',1)
        plot(FPMixed, meanRT(i, :), 'k-',  'linewidth', i*0.5)
        
    end;
    if k==1
    ylabel ('RT (ms)')
    elseif k ==2
          xlabel ('FP (ms)')
    end;
end;

if ispc
    tosave= 'C:\Users\jiani\OneDrive\Work\Behavior\Figures'
    
    savename = fullfile(tosave, 'RTvsFPSequential');
    print (gcf,'-dpng', [savename])
    print (gcf,'-dpdf', [savename])
    saveas(gcf, savename, 'fig')
    
else
    tosave= '/Users/jianingyu/OneDrive/Work/Behavior/Figures'
    savename = fullfile(tosave, 'RTvsFPSequential');
    print (gcf,'-dpng', [savename])
    print (gcf,'-dpdf', [savename])
    saveas(gcf, savename, 'fig')
    
end;

saveas(gcf, savename, 'fig')
