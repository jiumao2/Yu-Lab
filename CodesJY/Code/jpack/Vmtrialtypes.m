function Vmtrialtypes(T, plotrange, spikes, badtrials, tosave, type, beh)
% Vmtrialtypes(T, plotrange, trialnums, badtrials, tosave, type)
% Vmtrialtypes(T, [-70 -30; 0 50], [], [16 17], 1, 'ms')

if nargin<7
    beh=1;
    if nargin<6
        type='5ms';
        if nargin<5
            tosave=0;
            if nargin<4
                badtrials=[];
                if nargin<3
                    spikes=[];
                    if nargin<2
                        plotrange=[-70 -40; 0 40];
                    end;
                end;
            end;
        end;
    end;
end;




    trialnums=T.trialNums;


trialnums=setdiff(trialnums, badtrials);

yrange=plotrange(1, :);
yrange2=plotrange(2, :);

bin_centers=[0:0.01:5.2];

vref=yrange(1)+2/3*abs(diff(yrange));
spkref=yrange2(1)+2/3*abs(diff(yrange2));

M1stimtrials=findM1trials(T, type);

% Vm averages according to trial types)

% Hit, no stim
if beh
    [ind_hit_nostim, index_hitnostim]=intersect(trialnums, setdiff(T.hitTrialNums, T.stimtrialNums));
    [ind_hit_stim, index_hitstim]=intersect(trialnums, intersect(T.hitTrialNums, M1stimtrials));
    
    mean_reaction_time_hitnostim=   median(cell2mat(cellfun(@(x)x.answerLickTime, T.trials(index_hitnostim), 'uniformoutput', false)));
    mean_reaction_time_hitstim=     median(cell2mat(cellfun(@(x)x.answerLickTime, T.trials(index_hitstim), 'uniformoutput', false)));
    
else
    ind_hit_nostim=intersect(trialnums, setdiff([T.hitTrialNums T.missTrialNums], T.stimtrialNums));
    ind_hit_stim=intersect(trialnums, intersect([T.hitTrialNums T.missTrialNums], M1stimtrials));
    mean_reaction_time_hitnostim=[];
    mean_reaction_time_hitstim=[];
end;
    

[Vm_hit_nostim, dum, tvm]=findvmtrials(T, ind_hit_nostim);
[Vm_hit_stim, aom1]=findvmtrials(T, ind_hit_stim);


spkmat=reconstructspikes(T, spikes);


[~, inostim]=intersect(T.trialNums, ind_hit_nostim);
spknostim=spkmat(:, inostim);
[~, istim]=intersect(T.trialNums, ind_hit_stim);
spkstim=spkmat(:, istim);

[h_hit_nostim, thist] = spikehisto(spknostim, 10000, size(spknostim, 1)/(10*10)); % 10 ms
h_hit_nostim=conv(h_hit_nostim, [0.05 0.25 0.40 0.25 0.05]);
h_hit_nostim=h_hit_nostim(3:end-2);

[h_hit_stim, thist] = spikehisto(spkstim, 10000, size(spkstim, 1)/100); % 10 ms
h_hit_stim=conv(h_hit_stim, [0.05 0.25 0.40 0.25 0.05]);
h_hit_stim=h_hit_stim(3:end-2);

pole_on_hit=median(T.pinDescentOnsetTimes([ind_hit_nostim ind_hit_stim]));
pole_off_hit_nostim=T.pinAscentOnsetTimes([ind_hit_nostim]);
pole_off_hit_stim=T.pinAscentOnsetTimes([ind_hit_stim]);

% CR, no stim
if beh
    ind_cr_nostim=intersect(trialnums, setdiff(T.correctRejectionTrialNums, T.stimtrialNums));
    ind_cr_stim=intersect(trialnums, intersect(T.correctRejectionTrialNums, M1stimtrials));
else
    ind_cr_nostim=intersect(trialnums, setdiff([T.correctRejectionTrialNums T.falseAlarmTrialNums], T.stimtrialNums));
    ind_cr_stim=intersect(trialnums, intersect([T.correctRejectionTrialNums T.falseAlarmTrialNums], M1stimtrials));
end;

[Vm_cr_nostim, dum]=findvmtrials(T, ind_cr_nostim);
[Vm_cr_stim, aom2]=findvmtrials(T, ind_cr_stim);


[~, inostim]=intersect(T.trialNums, ind_cr_nostim);
spknostim=spkmat(:, inostim);
[~, istim]=intersect(T.trialNums, ind_cr_stim);
spkstim=spkmat(:, istim);

[h_cr_nostim, thist] = spikehisto(spknostim, 10000, size(spknostim, 1)/100); % 10 ms
h_cr_nostim=conv(h_cr_nostim, [0.05 0.25 0.40 0.25 0.05]);
h_cr_nostim=h_cr_nostim(3:end-2);

[h_cr_stim, thist] = spikehisto(spkstim, 10000, size(spkstim, 1)/100); % 10 ms
h_cr_stim=conv(h_cr_stim, [0.05 0.25 0.40 0.25 0.05]);
h_cr_stim=h_cr_stim(3:end-2);


pole_on_cr=median(T.pinDescentOnsetTimes([ind_cr_nostim ind_cr_stim]));
pole_off_cr_nostim=T.pinAscentOnsetTimes([ind_cr_nostim]);
pole_off_cr_stim=T.pinAscentOnsetTimes([ind_cr_stim]);

hf=figure;
set(hf, 'units', 'centimeters', 'position', [2 2 24 12], 'paperpositionmode', 'auto');

ha1=subplot(2, 4, 1);
set(ha1, 'nextplot', 'add', 'xlim', [tvm(1)+.01 5-0.5], 'fontsize', 10, 'ylim', yrange, 'xtick', [1:4]);
plot(tvm, mean(medfilt1(Vm_hit_nostim, 50), 2),  'k');

if ~isempty(Vm_cr_nostim)
plot(tvm, mean(medfilt1(Vm_cr_nostim, 50), 2),  'r');
end;

plot(pole_on_hit, vref, 'k*');
plot(pole_on_hit+0.25, vref, 'ko');

plot(median(pole_off_hit_nostim), vref, 'k*');
plot(median(pole_off_cr_nostim), vref, 'r*');

if ~isempty(mean_reaction_time_hitnostim)
    plot(mean_reaction_time_hitnostim, vref+0.5, 'm^')
end;

line([pole_on_hit+0.25 median(pole_off_hit_nostim)], [vref+2 vref+2], 'color', 'k', 'linewidth', 2)

if beh
    hl=legend('Hit', 'CR');
else
    hl=legend('Go', 'Nogo')
end;
set(hl, 'fontsize', 6, 'box', 'off');
xlabel('sec'); ylabel('mV')
title([T.cellNum])
chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])


ha2=subplot(2, 4, 2);
set(ha2, 'nextplot', 'add', 'xlim', [tvm(1)+.01 5-0.5], 'fontsize', 10, 'ylim', yrange, 'xtick', [1:4]);
if ~isempty(Vm_hit_stim)
    plot(tvm, mean(medfilt1(Vm_hit_stim, 50), 2),  'color', [.5 .5 .5]);
end;

if ~isempty(Vm_cr_stim)
    plot(tvm,mean(medfilt1(Vm_cr_stim, 50), 2),  'color', [1 .5 0]);
    plot(median(pole_off_cr_stim), vref, 'r*');
end;

line([pole_on_hit+0.25 median(pole_off_hit_stim)], [vref+2 vref+2], 'color', 'k', 'linewidth', 2)
plot(pole_on_hit, vref, 'k*');
plot(pole_on_hit+0.25, vref, 'ko');
plot(median(pole_off_hit_stim), vref, 'k*');

if ~isempty(mean_reaction_time_hitstim)
    plot(mean_reaction_time_hitnostim, vref+0.5, 'm^')
end;

if beh
    hl=legend('Hit', 'CR');
else
    hl=legend('Go', 'Nogo')
end;
 set(hl, 'fontsize', 6, 'box', 'off');
aom=[aom1 aom2];

plot(tvm, mean(aom, 2)/2+yrange(1)+2, 'b');
xlabel('sec'); ylabel('mV')
title ('Stim')
chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

ha3=subplot(2, 4, 5);
set(ha3, 'nextplot', 'add', 'xlim', [tvm(1)+.01 5-0.5], 'fontsize', 10, 'ylim', yrange, 'xtick', [1:4]);
plot(tvm, mean(medfilt1(Vm_hit_nostim, 50), 2),  'k');
if ~isempty(Vm_hit_stim)
    plot(tvm, mean(medfilt1(Vm_hit_stim, 50), 2),  'color', [.5 .5 .5]);
end;

line([pole_on_hit+0.25 median(pole_off_hit_nostim)], [vref+2 vref+2], 'color', 'k', 'linewidth', 2)

plot(pole_on_hit, vref, 'k*');
plot(pole_on_hit+0.25, vref, 'ko');

plot(median(pole_off_hit_nostim), vref, 'k*');
if ~isempty(aom1)
plot(tvm, mean(aom1, 2)/2+yrange(1)+2, 'b');
end;

hl=legend('Normal', 'Stim');
set(hl, 'fontsize', 6, 'box', 'off');
xlabel('sec'); ylabel('mV')
if beh
title('Hit trials')
else
    title('Go trials')
end;
chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])


ha4=subplot(2, 4, 6);
set(ha4, 'nextplot', 'add', 'xlim', [tvm(1)+.01 5-0.5], 'fontsize', 10, 'ylim', yrange, 'xtick', [1:4]);

if ~isempty(Vm_cr_nostim)
plot(tvm, mean(medfilt1(Vm_cr_nostim, 50), 2),  'r');
end;

if ~isempty(Vm_cr_stim)
    plot(tvm, mean(medfilt1(Vm_cr_stim, 50), 2),  'color', [1 .5 0]);
    plot(median(pole_off_cr_stim), vref, 'r*');
    hl=legend('Normal', 'Stim');
    plot(tvm, mean(aom2, 2)/2+yrange(1)+2, 'b');
end;

line([pole_on_cr+0.25 median(pole_off_cr_nostim)], [vref+2 vref+2], 'color', 'k', 'linewidth', 2)

plot(pole_on_cr, vref, 'r*');
plot(pole_on_cr+0.25, vref, 'ro');

set(hl, 'fontsize', 6, 'box', 'off');

chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

xlabel('sec'); ylabel('mV')
if beh
title ('CR trials')
else
    title('Nogo trials')
end;

%% spike

indspk=find(thist>=0 & thist<=5);
tbins=thist(indspk);

ha1=subplot(2, 4, 3);

set(ha1, 'nextplot', 'add', 'xlim', [tvm(1) 4.5], 'fontsize', 10, 'ylim', yrange2, 'xtick', [1:4]);

h_hit_nostim=conv(h_hit_nostim, [0.05 0.25 0.40 0.25 0.05]); h_hit_nostim=h_hit_nostim(3:end-2);
h_cr_nostim=conv(h_cr_nostim, [0.05 0.25 0.40 0.25 0.05]); h_cr_nostim=h_cr_nostim(3:end-2);

plot(tbins, h_hit_nostim(indspk), 'color', 'k', 'linewidth', 1);
plot(tbins, h_cr_nostim(indspk), 'color', 'r', 'linewidth', 1);

plot(pole_on_hit, spkref, 'k*');

plot(median(pole_off_hit_nostim), spkref, 'k*');
plot(median(pole_off_cr_nostim), spkref, 'r*');

line([pole_on_hit+0.25 median(pole_off_hit_nostim)], [spkref+2 spkref+2], 'color', 'k', 'linewidth', 2)

if ~isempty(mean_reaction_time_hitnostim)
    plot(mean_reaction_time_hitnostim, spkref+2, 'm^')
end;

hl=legend('Hit', 'CR');
set(hl, 'fontsize', 6, 'box', 'off');
xlabel('sec'); ylabel('Spk/sec')
if beh
    hl=legend('Hit', 'CR');
else
    hl=legend('Go', 'Nogo')
end;
 set(hl, 'fontsize', 6, 'box', 'off');
 
title([T.cellNum])

chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

ha2=subplot(2, 4, 4);
set(ha2, 'nextplot', 'add', 'xlim', [tvm(1) 4.5], 'fontsize', 10, 'ylim', yrange2, 'xtick', [1:4]);

if ~isempty(h_hit_stim) && ~isempty(h_cr_stim)
    
    h_hit_stim=conv(h_hit_stim, [0.05 0.25 0.40 0.25 0.05]); h_hit_nostim=h_hit_nostim(3:end-2);
    h_cr_stim=conv(h_cr_stim, [0.05 0.25 0.40 0.25 0.05]); h_cr_stim=h_cr_stim(3:end-2);
    
    plot(tbins, h_hit_stim(indspk),  'color', [.5 .5 .5], 'linewidth', 1);
    plot(tbins, h_cr_stim(indspk),  'color', [1 .5 0], 'linewidth', 1);
    if beh
        hl=legend('Hit', 'CR');
    else
        hl=legend('Go', 'Nogo')
    end;
    set(hl, 'fontsize', 6, 'box', 'off');
    
    plot(median(pole_off_hit_stim), spkref, 'k*');
    line([pole_on_hit+0.25 median(pole_off_hit_stim)], [spkref+2 spkref+2], 'color', 'k', 'linewidth', 2)
    
    plot(median(pole_off_cr_stim), spkref, 'r*');
end;

plot(pole_on_hit, spkref, 'k*');

if ~isempty(mean_reaction_time_hitstim)
    plot(mean_reaction_time_hitstim, spkref+2, 'm^')
end;


plot(tvm, mean(aom, 2)/2+yrange2(1)+2, 'b');
xlabel('sec'); ylabel('Spk/sec')
title ('Stim')

chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])


ha3=subplot(2, 4, 7);
set(ha3, 'nextplot', 'add', 'xlim', [tvm(1) 4.5], 'fontsize', 10, 'ylim', yrange2, 'xtick', [1:4]);

if ~isempty(h_hit_nostim)
    plot(tbins, h_hit_nostim(indspk), 'color', 'k', 'linewidth', 1);
end;

if ~isempty(h_hit_stim)
    plot(tbins, h_hit_stim(indspk),   'color', [.5 .5 .5], 'linewidth', 1);
end;

if ~isempty(h_hit_nostim)
    line([pole_on_hit+0.25 median(pole_off_hit_nostim)], [spkref+2 spkref+2], 'color', 'k', 'linewidth', 2)
    plot(median(pole_off_hit_nostim), spkref, 'k*');
end;

plot(pole_on_hit, spkref, 'k*');

if ~isempty(aom1)
plot(tvm, mean(aom1, 2)/2+yrange2(1)+2, 'b');
end
hl=legend('Normal', 'Stim');

set(hl, 'fontsize', 6, 'box', 'off');
xlabel('sec'); ylabel('Spk/sec')
if beh
title('Hit trials')
else
    title('Go trials')
end;

chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

ha4=subplot(2, 4, 8);
set(ha4, 'nextplot', 'add', 'xlim', [tvm(1) 4.5], 'fontsize', 10, 'ylim', yrange2, 'xtick', [1:4]);

if ~isempty(Vm_cr_nostim) && ~isempty(Vm_cr_stim)
    plot(tbins, h_cr_nostim(indspk), 'color', 'r', 'linewidth', 1);
    plot(tbins, h_cr_stim(indspk),  'color', [1 .5 0], 'linewidth', 1);
     hl=legend('Normal', 'Stim');
    line([pole_on_cr+0.25 median(pole_off_cr_nostim)], [spkref+2 spkref+2], 'color', 'k', 'linewidth', 2)
    plot(median(pole_off_cr_stim), spkref, 'r*');
    plot(tvm, mean(aom2, 2)/2+yrange2(1)+2, 'b');
end;

plot(pole_on_cr, spkref, 'r*');
set(hl, 'fontsize', 6, 'box', 'off');

xlabel('sec'); ylabel('Spk/sec')
if beh
title ('CR trials')
else
    title('Nogo trials')
end;

chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

%%

if tosave
    saveas(hf, ['Vmtrial_comparison'], 'fig')
    saveas(hf, ['Vmtrial_comparison'], 'tif')
    saveas(hf, ['Vmtrial_comparison'], 'pdf')
%     export_fig (hf, ['Vmtrial_comparison'], '-tiff', '-eps')
    print (hf, '-depsc2', 'Vmtrial_comparison')
end;