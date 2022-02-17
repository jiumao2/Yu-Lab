function sessions = FPvsRTSingleMixed(bMixedFPs, RTrange, name, post)
% will calculate both single and Mixed

if nargin<4
    post = [];
    if nargin<3
        RTrange = [250 500];
        if nargin<2
            name = [];
        end;
    end;
end;

FPMixed = [500 750 1000 1250 1500 1750 2000];
 
nFP = length(FPMixed);
RTmin = 150;   % minimal RT

Performance = zeros (4, length(FPMixed)); 

% row 1: trial num
% row 2: correct num
% row 3: premature num
% row 4: late num

% Collection of press durations
RT_FPMixed          =   cell(1, length(FPMixed));
Premature_FPMixed   =   cell(1, length(FPMixed));
Late_FPMixed        =   cell (1, length(FPMixed));
PressDur_FPMixed    =   cell(1, length(FPMixed));

RTevo_FPMixed       =   cell(length(FPMixed), length(FPMixed));  % change of RT as a function of FP
Performance_evo = zeros (4, length(bMixedFPs)); % performance over different sessions

date_list=cell(1, length(bMixedFPs));

RTevo_FPOthers      =   cell(1, length(bMixedFPs));  
Performance_evoFPOthers = zeros (4, length(bMixedFPs)); % performance over different sessions
 
for i = 1:length(bMixedFPs)
    b = bMixedFPs(i);
    date_list{i} = bMixedFPs(i).Metadata.Date(end-3:end);
    
    % FPs that are not found in FPMixed
    
    if isempty(b.FPs)
        RT_FPOthers{i} = b.ReactionTime(b.IndToneLate==0)/1000;
        
        Performance_evo(1, i) = length(b.Correct)+length(b.Premature)+length(b.Late);
        Performance_evo(2, i) = length(b.Correct);
        Performance_evo(3, i) = length(b.Premature);
        Performance_evo(4, i) = length(b.Late);
    else
        [C,indotherFPs] = setdiff(b.FPs, FPMixed);
        [ind_FPcorrectOthers, ~] = intersect(indotherFPs, b.Correct);
        RT_FPOthers{i} = [-b.FPs(ind_FPcorrectOthers)/1000+b.ReleaseTime(ind_FPcorrectOthers)-b.PressTime(ind_FPcorrectOthers)];
    end;
    
    for j = 1:length(FPMixed)
        
        ind_FP                  =   find(b.FPs == FPMixed(j));  % includes all presses
        ind_FP                  =   ind_FP(ind_FP>20); % counting from the 20th press onwards.  
        
        if i == 16
            display('here');
        end;
        
        Performance(1, j)       =   Performance(1, j)+length(ind_FP);
        PressDur_FPMixed{j}     =   [PressDur_FPMixed{j} -b.PressTime(ind_FP)+b.ReleaseTime(ind_FP)];
        Performance_evo(1, i) = Performance_evo(1, i) + length(ind_FP);
        
        % correct
        [ind_FPcorrect, ~]      =   intersect(ind_FP, b.Correct);
        Performance(2, j)       =   Performance(2, j)+length(ind_FPcorrect);
        RT_FPMixed{j}           =   [RT_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPcorrect)-b.PressTime(ind_FPcorrect)];
        
        Performance_evo(2, i) = Performance_evo(2, i) +length(ind_FPcorrect);
        RTevo_FPMixed{j, i} = -FPMixed(j)/1000+b.ReleaseTime(ind_FPcorrect)-b.PressTime(ind_FPcorrect);
        
        % early
        [ind_FPearly, ~]        =   intersect(ind_FP, b.Premature);
        Performance(3, j)       =   Performance(3, j)+length(ind_FPearly);
        Premature_FPMixed{j}    =   [Premature_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPearly)-b.PressTime(ind_FPearly)];
        
        Performance_evo(3, i) = Performance_evo(3, i) +length(ind_FPearly);
        % late
        [ind_FPlate, ~]         =   intersect(ind_FP, b.Late);
        Performance(4, j)       =   Performance(4, j)+length(ind_FPlate);
        Late_FPMixed{j}         =   [Late_FPMixed{j} -FPMixed(j)/1000+b.ReleaseTime(ind_FPlate)-b.PressTime(ind_FPlate)];
        
        Performance_evo(4, i) = Performance_evo(4, i) +length(ind_FPlate);
        
    end;
    
end;

%% plot the changes of RT over sessions
figure(20); clf(20)
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 15], 'paperpositionmode', 'auto' )

ha=subplot(5, 1, 1)
set(ha, 'nextplot', 'add', 'xlim', [0 size(RTevo_FPMixed, 2)+1], 'ylim', [100 500], 'xgrid', 'on', 'fontsize', 8)
title(bMixedFPs(1).Metadata.SubjectName)

for i = 1:size(RTevo_FPMixed, 2) % different sessions
    
    for j = 1:size(RTevo_FPMixed, 1)  % FPx
        
        RTij= RTevo_FPMixed{j, i}*1000;
        RTevomean(j, i)=median(RTij);
        RTstdij = std(RTij);
        %         % 95 confidence intervals
        try
            ci95ij=bootci(1000, {@median, RTij}, 'type','per');
            line([i i],ci95ij, 'color', 'b', 'linewidth', 1)
            plot(i, RTevomean(j, i), 'o', 'markersize', 5, 'linewidth', 0.5*j, 'color', 'k');
            
        end;
    end;
    
end;

% axis 'auto y'

% plot other FPs
for i = 1:length(RT_FPOthers)
    
    if length(RT_FPOthers{i})>20
        RTij_others= RT_FPOthers{i}*1000;
        RTevomean_others(i)=median(RTij_others);
        RTstdij = std(RTij);
        try
            ci95ij=bootci(1000, {@median, RTij_others}, 'type','per');
            line([i i],ci95ij, 'color', 'b', 'linewidth', 1)
            plot(i, RTevomean_others(i), 'o', 'markersize', 5, 'linewidth', 1, 'color', 'b');
        end;
    end;
end;



ylabel ('Reaction time (ms)')
set(gca, 'xtick', [1:size(Performance_evo, 2)], 'xticklabel', [])

% add time of lesion
allsessions = arrayfun(@(x)x.SessionName, bMixedFPs, 'UniformOutput', false);
allsessions = allsessions';

ind_map=[];

if ~isempty(post)
    for i =1:length(post)
        ind_i = find(strcmp(strrep(post{i}, '_', '-'), allsessions)); 
        ind_map = [ind_map ind_i];
        line([ind_i ind_i]-0.5, [100 600], 'color', 'm', 'linestyle', ':', 'linewidth', 2) 
    end; 
end;

    
% track press number of each session
ha1=subplot(5, 1, 2)
set(ha1, 'nextplot', 'add', 'xlim', [0 size(Performance_evo, 2)+1], 'ylim', [100  500], 'fontsize', 8, 'xgrid', 'on');
plot([1:size(Performance_evo, 2)], Performance_evo(1, :), 'o-', 'color', 'k', 'linewidth', 1, 'markersize', 6)
set(gca, 'xtick', [1:size(Performance_evo, 2)], 'xticklabel', [])
 
ylabel('Trials')
axis 'auto y'

if ~isempty(ind_map)
    for i =1:length(ind_map)
        ind_i = ind_map(i);
        line([ind_i ind_i]-0.5, get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 2) 
    end; 
end;

% track performance over time
ha2=subplot(5, 1, 3)
set(ha2, 'nextplot', 'add', 'xlim', [0 size(Performance_evo, 2)+1], 'ylim', [0.2 1], 'fontsize', 8, 'xgrid', 'on')

for i = 1:size(Performance_evo, 2) % different sessions
    Correct_rate (i) = Performance_evo(2, i)/sum(Performance_evo([2:4], i));
end;

line([0 size(Performance_evo, 2)+1], [.7 .7], 'color', 'k', 'linestyle', ':')
text(1, .65, '70%')
plot([1:size(Performance_evo, 2)], Correct_rate, 'o-', 'markersize', 5, 'linewidth', 1, 'color', [51 150 0]/255)

set(gca, 'xtick', [1:size(Performance_evo, 2)], 'xticklabel', [])

ylabel('Performance')
 
   
if ~isempty(ind_map)
    for i =1:length(ind_map)
        ind_i = ind_map(i);
        line([ind_i ind_i]-0.5, get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 2) 
    end; 
end;


 %% tracking late rate: 
ha4=subplot(5, 1, 5)
set(ha4, 'nextplot', 'add', 'xlim', [0 size(Performance_evo, 2)+1], 'ylim', [0 0.5], 'fontsize', 8, 'xgrid', 'on')

for i = 1:size(Performance_evo, 2) % different sessions
    Late_rate (i) = Performance_evo(4, i)/sum(Performance_evo([2:4], i));
end; 
 
plot([1:size(Performance_evo, 2)], Late_rate, 'o-', 'markersize', 5, 'linewidth', 1, 'color', [.25 .25 .25])

set(gca, 'xtick', [1:size(Performance_evo, 2)], 'xticklabel', date_list)

 xtickangle(90)
 
 xlabel('Date')
 ylabel('Late')
 
 if ~isempty(ind_map)
    for i =1:length(ind_map)
        ind_i = ind_map(i);
        line([ind_i ind_i]-0.5, get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 2) 
    end; 
end;
 
 %% tracking premature rate: 
ha3=subplot(5, 1, 4)
set(ha3, 'nextplot', 'add', 'xlim', [0 size(Performance_evo, 2)+1], 'ylim', [0 0.5], 'fontsize', 8, 'xgrid', 'on')

for i = 1:size(Performance_evo, 2) % different sessions
    Premature_rate (i) = Performance_evo(3, i)/sum(Performance_evo([2:4], i));
end; 
 
plot([1:size(Performance_evo, 2)], Premature_rate, 'o-', 'markersize', 5, 'linewidth', 1, 'color', 'r')

set(gca, 'xtick', [1:size(Performance_evo, 2)], 'xticklabel', [])

 ylabel('Premature')
 
 if ~isempty(ind_map)
    for i =1:length(ind_map)
        ind_i = ind_map(i);
        line([ind_i ind_i]-0.5, get(gca, 'ylim'), 'color', 'm', 'linestyle', ':', 'linewidth', 2) 
    end; 
end;

savename = ['History'  upper(bMixedFPs(1).Metadata.SubjectName) '_Results' name];

print (gcf,'-dpng', [savename])
print (gcf,'-dpdf', [savename])


%% print out session names 
 x=arrayfun(@(x)x.Metadata.ProtocolName, bMixedFPs, 'UniformOutput', false)';
 x2=arrayfun(@(x)x.Metadata.Date, bMixedFPs, 'UniformOutput', false)';
 
 sessions = [x2 x];
 