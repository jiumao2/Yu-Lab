function Vmtrialtypesnormal(T, plotrange, trialnums, contacts, tosave)
% made around 2013 sfn 
% nice way to show contact, lick and avg neural responses

% only no stim trials
set(0,'DefaultAxesFontSize',12)
close all;

    if isempty(trialnums)
        trialnums=setdiff(T.trialNums, T.stimtrialNums);
    end;

yrange=plotrange(1, :);
yrange2=plotrange(2, :);

bin_centers=[0:0.1:5.2];
indspk=find(bin_centers>=0 & bin_centers<=5);
tbins=bin_centers(indspk);

vref=yrange(1)+2/3*abs(diff(yrange));
spkref=yrange2(1)+2/3*abs(diff(yrange2));

% Vm averages according to trial types)

% Hit, no stim
ind_hit_nostim=intersect(trialnums, setdiff(T.hitTrialNums, T.stimtrialNums));

[Vm_hit_nostim, dum, tvm]=findvmtrials(T, ind_hit_nostim);

h_hit_nostim = T.PSTH(ind_hit_nostim, bin_centers)

pole_on_hit=median(T.pinDescentOnsetTimes([ind_hit_nostim]));
pole_off_hit_nostim=T.pinAscentOnsetTimes([ind_hit_nostim]);
hitcontacts={};
crcontacts={};
hitlicktimes={};
crlicktimes={};

% get touch times
for i=1:length(ind_hit_nostim);
    icontacts=contacts{T.trialNums==ind_hit_nostim(i)};
     twhisk=T.trials{T.trialNums==ind_hit_nostim(i)}.whiskerTrial.time{2};
     
     hitcontacts{i}=[];
    if ~isempty(icontacts.segmentInds{2})
    hitcontacts{i}=[hitcontacts{i} twhisk(icontacts.segmentInds{2}(:, 1))+0.01];
    end;
  
    hitlicktimes{i}=T.trials{T.trialNums==ind_hit_nostim(i)}.behavTrial.beamBreakTimes;
end;


% CR, no stim
ind_cr_nostim=intersect(trialnums, setdiff(T.correctRejectionTrialNums, T.stimtrialNums));
[Vm_cr_nostim, dum]=findvmtrials(T, ind_cr_nostim);
h_cr_nostim = T.PSTH(ind_cr_nostim, bin_centers)
pole_on_cr=median(T.pinDescentOnsetTimes([ind_cr_nostim]));
pole_off_cr_nostim=T.pinAscentOnsetTimes([ind_cr_nostim]);

for i=1:length(ind_cr_nostim);
    icontacts=contacts{T.trialNums==ind_cr_nostim(i)};
    twhisk=T.trials{T.trialNums==ind_cr_nostim(i)}.whiskerTrial.time{2};
    if ~isempty(icontacts.segmentInds{2})
    crcontacts{i}=twhisk(icontacts.segmentInds{2}(:, 1))+0.01;
    else
        crcontacts{i}=[];
    end;
    crlicktimes{i}=T.trials{T.trialNums==ind_cr_nostim(i)}.behavTrial.beamBreakTimes;
end;


hf=figure;
set(hf, 'units', 'centimeters', 'position', [2 2 8 12], 'paperpositionmode', 'auto', 'color', 'w');

ha1=axes('units', 'centimeters', 'position', [2 6 4 4], 'nextplot', 'add');
set(ha1, 'nextplot', 'add', 'xlim', [tvm(1)+.01 5-0.05], 'fontsize', 10, 'ylim', yrange, 'xtick', [1:4]);
plot(tvm, mean(medfilt1(Vm_hit_nostim, 50), 2),  'k');
plot(tvm, mean(medfilt1(Vm_cr_nostim, 50), 2),  'r');

delay1=0.35;
delay2=0.2;

line([pole_on_hit pole_on_hit+delay1], [vref+4 vref+2], 'color', [.75 .75 .75], 'linewidth', 2);
line([pole_on_hit+delay1 median(pole_off_hit_nostim)], [vref+2 vref+2], 'color', 'k', 'linewidth', 2)
line([ median(pole_off_hit_nostim),   median(pole_off_hit_nostim)+delay2], [vref+2 vref+4], 'color', [.75 .75 .75], 'linewidth', 2);


line([4 4], [yrange(2)-12 yrange(2)-2], 'color', 'k')
line([0 1], [-55 -55], 'color', 'k');
text(0.1, -57, '-55 mV')
text(4.2, yrange(2)-10, '10 mV')
line([3 4], [yrange(1)+2 yrange(1)+2], 'color', 'k')
text(3.5, yrange(1)+1, '1 s')

axis off

hl=legend('Hit', 'CR');
set(hl, 'fontsize', 6, 'box', 'off');
xlabel('sec'); ylabel('mV')

title([T.cellNum])
chH = get(gca,'Children')
set(gca,'Children',[chH(end);chH(1:end-1)])

ha2=axes('units', 'centimeters', 'position', [2 4 4 3], 'nextplot', 'add');

set(ha2, 'nextplot', 'add', 'xlim', [tvm(1) 5], 'fontsize', 10, 'ylim', yrange2, 'xtick', [1:4]);
bar(tbins, h_hit_nostim(indspk), 'barwidth', 1, 'facecolor', 'k', 'edgecolor', 'k');
bar(tbins, h_cr_nostim(indspk), 'barwidth', 1, 'facecolor', 'r', 'edgecolor', 'r');
bar(tbins, zeros(size(tbins)), 'barwidth', 1, 'facecolor', 'k', 'edgecolor', 'k')
vref=spkref;
line([4  4], [yrange2(1)+1 yrange2(1)+6], 'color', 'k')
text(4.2, yrange2(1)+11.5, '5 Hz');

axis off

ha3=axes('units', 'centimeters', 'position', [2 0.5 4 3], 'nextplot', 'add', 'xlim', get(ha1, 'xlim'));
for i=1:length(ind_hit_nostim);
    if ~isempty(hitcontacts{i})
        plot(hitcontacts{i}, i, 'cx');
    end;
    
    if ~isempty(hitlicktimes{i})
        plot(hitlicktimes{i}, i, 'm.');
    end;
end;

for i=1:length(ind_cr_nostim);
    if ~isempty(crcontacts{i})
        plot(crcontacts{i}, i+length(ind_hit_nostim), 'cx');
    end
    if ~isempty(crlicktimes{i})
        plot(crlicktimes{i}, i+length(ind_hit_nostim), 'm.');
    end
end;

line([4 4], [1 length(ind_hit_nostim)], 'color','k');
line([4 4], [length(ind_hit_nostim)+1 length(ind_cr_nostim)+length(ind_hit_nostim)], 'color', 'r')

axis off
   

%%

if tosave
    saveas(hf, ['trial_comparison'], 'fig')
    export_fig(hf, ['trial_comparison'], '-eps')
     export_fig(hf, ['trial_comparison'], '-tiff')
end;