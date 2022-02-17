function plotbAll(bAll)

gcolor=[0 .5 0];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 18], 'paperpositionmode', 'auto' )


%% compile presses
presson=(arrayfun(@(x)x.PressTime, bAll, 'uniformoutput', false));
pressoff=(arrayfun(@(x)x.ReleaseTime, bAll, 'uniformoutput', false));

presson_stack=[];
pressoff_stack=[];
quality_stack=[];
rt_stack = [];
il_stack = [];

tags=[1 2 3 4]; % 1. correct, 2. premature, 3. late, 4, dark
% 
% rt=cell2mat(arrayfun(@(x)x.ReactionTime, bAll, 'uniformoutput', false));
% il=cell2mat(arrayfun(@(x)x.IndToneLate, bAll, 'uniformoutput', false));
% 
% ind_rt=[1:length(rt)];

step=0;

for i=1:length(presson)
    i_index     =       zeros(1, length(presson{i}));
    i_index(bAll(i).Correct)=1;
    i_index(bAll(i).Premature)=2;
    i_index(bAll(i).Late)=3;
    i_index(bAll(i).Dark)=4;
    presson_stack   = [presson_stack step+presson{i}];
    pressoff_stack  = [pressoff_stack step+pressoff{i}];
    quality_stack   = [quality_stack i_index];

        rt_stack = [rt_stack        bAll(i).ReactionTime        zeros(1, 20)];
        il_stack  = [il_stack         bAll(i).IndToneLate         2*ones(1, 20)];

    step = step+max(pressoff{i})+500;
    
end;

pressdur_stack=pressoff_stack-presson_stack;

subplot(2, 5, [1:4])
set(gca, 'nextplot', 'add', 'yscale', 'log')
ind_rtstack=[1:length(rt_stack)];

plot(ind_rtstack(il_stack==1), rt_stack(il_stack==1), 'ro', 'markerfacecolor', 'r');
plot(ind_rtstack(il_stack==0), rt_stack(il_stack==0), 'o', 'markeredgecolor', gcolor);

set(gca, 'xlim', [0 length(rt_stack)])
xlabel ('Release')
ylabel ('Reaction time (ms)')
title(sprintf('%s', upper(bAll(1).Metadata.SubjectName)))

subplot(2, 5, [5, 10])  % metadata 

set(gca, 'xlim', [1.5 10], 'ylim', [0 30], 'nextplot', 'add')

for i=1:length(bAll)
    mdata=bAll(i).Metadata;
    text(1, 30-i, sprintf('%s %s %s', mdata.Date, strrep(mdata.ProtocolName, '_', '-')), 'fontsize', 8)
end;


plot(2, 4, 'o', 'linewidth', 1, 'color', gcolor)
text(3, 4, 'Correct')

plot(2, 3, 'ro', 'linewidth', 1)
text(3, 3, 'Premature')

plot(2, 2 , 'ro', 'linewidth', 1, 'markerfacecolor', 'r')
text(3, 2, 'Late')

plot(2, 1, 'ko', 'linewidth', 1)
text(3, 1, 'Dark')
axis off

subplot(2, 5, [6:9])
set(gca, 'nextplot', 'add', 'yscale', 'log')

plot(pressoff_stack(quality_stack==2), pressdur_stack(quality_stack==2), 'ro', 'linewidth', 1);
plot(pressoff_stack(quality_stack==3), pressdur_stack(quality_stack==3), 'ro', 'linewidth', 1, 'markerfacecolor', 'r');
plot(pressoff_stack(quality_stack==4), pressdur_stack(quality_stack==4), 'ko', 'linewidth', 1);
plot(pressoff_stack(quality_stack==1), pressdur_stack(quality_stack==1), 'o', 'linewidth', 1, 'color', gcolor);

set(gca, 'xlim', [0 max(pressoff_stack)])
xlabel ('Time (s)')
ylabel ('Press time (s)')

savename = ['bAll_'  upper(bAll(1).Metadata.SubjectName)];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])