function CompareMixedRTsBpodvsPreBpod(name)
 
if ismac
    load (fullfile('/Users/jianingyu/OneDrive/Work/Behavior/BehaviorData/Animals/', name, ['RTMixed_' upper(name) '.mat']));
    olddat = RTMixed;
    
    load (fullfile('/Users/jianingyu/OneDrive/Work/Behavior/BehaviorData/Animals/', name, ['RTMixed_' upper(name) 'Bpod.mat']));
    bpoddat = RTMixed;
    
end;

 
figure(22); clf(22)
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 8], 'paperpositionmode', 'auto' )

ha4=axes('unit', 'centimeters', 'position', [2 2 6 5], 'nextplot', 'add', 'xlim', [0.5 3.5],...
    'xtick', [1 2 3], 'xticklabel', {'500', '1000', '1500'},'ylim', [225 350])


for i = 1:length(olddat.FPs)
    line([i i], olddat.RTci(i, :), 'color', 'b', 'linewidth', 1)
 
    line([i i], bpoddat.RTci(i, :), 'color', 'b', 'linewidth', 1)
end

plot([1 2 3], olddat.RTmean, 'ko-', 'linewidth', 1)
plot([1 2 3], bpoddat.RTmean, 'ko:', 'linewidth', 1)

axis 'auto y'
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

savename = ['MixedRTBpodvsPreBpod_' anm_name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

saveas(gcf, savename, 'fig')