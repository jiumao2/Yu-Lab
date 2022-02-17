function plotbAll(bAll, name, post)

if nargin<3
    post = [];
    if nargin<2
        name = '';
    end;
end;


gcolor=[0 .5 0];

figure(21); clf(21)
set(gcf, 'unit', 'centimeters', 'position',[2 2 20  15], 'paperpositionmode', 'auto')

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

session_beg = [0 0];

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
    
    if i<length(presson)
        session_beg = [session_beg; length(rt_stack) max(step)];
    end
end;

pressdur_stack=pressoff_stack-presson_stack;
 
ha1=axes;
set(ha1, 'units', 'centimeters', 'position', [2 8.5 11  5], 'nextplot', 'add', 'yscale', 'log', 'ylim', [50 10^4])

line([session_beg(:, 1) session_beg(:, 1)], [10^1 10^4], 'color', [0.2 0.2 0.2], 'linestyle', ':')

ind_rtstack=[1:length(rt_stack)];

plot(ind_rtstack(il_stack==1), rt_stack(il_stack==1), '.','color', 'r', 'markerfacecolor', 'r', 'markersize', 6);
plot(ind_rtstack(il_stack==0), rt_stack(il_stack==0), '.', 'markeredgecolor', gcolor, 'markersize', 6);

set(gca, 'xlim', [0 length(rt_stack)])
xlabel ('Release')
ylabel ('Reaction time (ms)')
title(sprintf('%s', upper(bAll(1).Metadata.SubjectName)))

% add time of lesion
allsessions = arrayfun(@(x)x.SessionName, bAll, 'UniformOutput', false);

allsessions = allsessions';

ind_pert=[];

if ~isempty(post)
    for i =1:length(post)
        ind_i = find(strcmp(strrep(post{i}, '_', '-'), allsessions)); 
        ind_pert=[ind_pert ind_i];
        line(session_beg(ind_i, 1)*[1 1], [50 10^4], 'color', 'm', 'linestyle', '--', 'linewidth', 1) 
    end; 
end;

ha2=axes;
set(ha2, 'units', 'centimeters', 'position', [14 7 5  7], 'nextplot', 'add', 'xlim', [1.8 15], 'ylim', [20 50])
 
 if ~isempty(ind_pert)
    text(2, 50, 'Lesion', 'fontsize', 10, 'color', 'k');
    
    for i=1:length(ind_pert)
        mdata=bAll(ind_pert(i)).Metadata;
        dateinfo = sprintf('%s %s %s', mdata.Date, strrep(mdata.ProtocolName, '_', '-'));
        text(2, 50-i*3, dateinfo(1:8), 'fontsize', 10, 'color', 'm');
    end;
end;
plot(2, 34, '.', 'linewidth', 2, 'color', gcolor, 'markersize', 8)
text(2.8, 34, 'Correct')

plot(2, 32, 'ro', 'linewidth', 1, 'markersize', 4)
text(2.8, 32, 'Premature')

plot(2, 30 , '.','color','r', 'linewidth', 2,  'markersize',8)
text(2.8, 30, 'Late')
% 
% plot(2, 1, 'k.', 'linewidth', 1, 'markersize',6)
% text(2.8, 1, 'Dark')
  axis off

ha3=axes;
set(ha3, 'units', 'centimeters', 'position', [2 1.5 11  5], 'nextplot', 'add', 'yscale', 'log', 'ylim', [100 10^4])
line([session_beg(:, 2) session_beg(:, 2)], [10^2 10^4], 'color', [0.2 0.2 0.2], 'linestyle', ':')

plot(pressoff_stack(quality_stack==2), 1000*pressdur_stack(quality_stack==2), 'ro', 'linewidth', 0.25, 'markersize', 2);
plot(pressoff_stack(quality_stack==3),  1000*pressdur_stack(quality_stack==3), 'r.', 'markerfacecolor', 'r', 'markersize', 6);
% plot(pressoff_stack(quality_stack==4), pressdur_stack(quality_stack==4), 'k.', 'linewidth', 1, 'markersize', 6);
plot(pressoff_stack(quality_stack==1),  1000*pressdur_stack(quality_stack==1), '.','color', gcolor, 'markersize', 6);

set(gca, 'xlim', [0 max(pressoff_stack)])
xlabel ('Time (s)')
ylabel ('Press time (ms)')

 if ~isempty(ind_pert)
    for i =1:length(ind_pert)
        line(session_beg(ind_pert(i), 2)*[1 1], [100 10^4], 'color', 'm', 'linestyle', '--', 'linewidth', 1) 
    end; 
end;

nsession = length(bAll);

if isempty(name)
    savename = ['bAll_'  upper(bAll(1).Metadata.SubjectName) '_last' sprintf('%1.0d', nsession)];
else
    savename = ['bAll_' name '_'  upper(bAll(1).Metadata.SubjectName)];
end;

%% plot performance
ha4=axes;
set(ha4, 'units', 'centimeters', 'position', [14.5 1.5  5 5], 'nextplot', 'add', 'ylim', [20 100], 'xlim', [0 length(bAll)+1])
  

% ha=axes('unit', 'centimeters', 'position', [2 2 8 4], 'next', 'add', 'ylim', [20 100], 'xlim', [0 length(bAll)+1]);
line([0 length(bAll)+1], [70 70], 'color', 'r', 'linewidth', 1, 'linestyle', ':')
performance = zeros (1, length(bAll));
switchindex = [];
for i = 1 : length(bAll)
    performance (i) = length(bAll(i).Correct)/(length(bAll(i).Correct) + length(bAll(i).Premature) + length(bAll(i).Late));
    if i>1
        if ~strcmp (bAll(i).Metadata.ProtocolName, bAll(i-1).Metadata.ProtocolName)
            switchindex = [switchindex i];
        end;
    end;
end

% add time of lesion
allsessions = arrayfun(@(x)x.SessionName, bAll, 'UniformOutput', false);
allsessions = allsessions';

if ~isempty(post)
    for i =1:length(post)
        ind_i = find(strcmp(strrep(post{i}, '_', '-'), allsessions)); 
        line([ind_i ind_i]-0.5, [0 100], 'color', 'm', 'linestyle', '--') 
    end; 
end;
 
plot([1:length(bAll)], performance*100, 'ko-')

% line([switchindex; switchindex]-0.5, repmat([0 ; 100], 1, length(switchindex)), 'color', 'b')

xlabel ('Session #')
ylabel ('Performance (%)')

 
if isempty(name)
    savename = ['bAllperformance_'  upper(bAll(1).Metadata.SubjectName) '_last' sprintf('%1.0d', nsession)];
else
    savename = ['bAllperformance' name '_'  upper(bAll(1).Metadata.SubjectName)];
end;

set(gcf, 'name', savename)

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])

