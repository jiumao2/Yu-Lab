function touchVm=reversalVm_touch(touch, trials, tpeak, driftcorr, Vrange)
% revised 1/5/2016
% touch_out=reversalVm_touch(touch, [], [], 0, [-80 -20]);

figure; 
set(gcf, 'units', 'centimeters', 'position', [2 2 12 12], 'paperpositionmode', 'auto', 'color', 'w')

PSPall=touch.PSPnoap;

subplot(2, 2, [1 2])
set(gca, 'nextplot', 'add', 'fontsize', 8)
title(touch.cellname)
ylabel('mV')
xlabel('touches')
box off
plot(median(PSPall, 1), 'o', 'color', [.5 .5 .5], 'linewidth', 1, 'markersize', 5);

hold on

if isempty(trials) || nargin<2
    trials=touch.ind_all;
end;

PSP=touch.PSPnoap(:, trials);

t=touch.t;
if driftcorr
    PSPold=PSP;
    Vmmed=median(PSP(t>-0.05 & t<0, :), 1);
    p=polyfit(trials, Vmmed, 1);
    
    correct_dVm=polyval(p, trials)-polyval(p, trials(1));
    
    plot(trials, polyval(p, trials), '-', 'color', [.75 .75 .75], 'linewidth', 2)
    
    touch.PSPnoap(:, trials)=touch.PSPnoap(:, trials)-repmat(correct_dVm, size(touch.PSPnoap(:, trials), 1), 1);
    touch.PSPorg(:, trials)=touch.PSPorg(:, trials)-repmat(correct_dVm, size(touch.PSPorg(:, trials), 1), 1);
    
    plot(trials, median(touch.PSPnoap(:, trials)),'*', 'color', [.75 0 0], 'markersize', 4)
    
else
    plot(trials, median(PSP, 1),'*', 'markersize', 4, 'color', [.75 0 0])
end;


PSPorg=touch.PSPorg(:, intersect(touch.ind_all,trials));
PSP=sgolayfilt(touch.PSPnoap(:, intersect(touch.ind_all,trials)), 3, 21);
Spksall=touch.Spk(:, intersect(touch.ind_all,trials));

t=touch.t;
[~, inds]=find(PSP(t>=-0.1 & t<0.1, :)<Vrange(1)  | PSP(t>=-0.1 & t<0.1, :)>Vrange(2));
inds=unique(inds);
PSP(:, inds)=[];
PSPorg(:, inds)=[];
Spksall(:, inds)=[];

Vmpre=mean(PSP(t>=-0.005 & t<=0.004, :), 1);

% when searching for peak PSP, need to consider the spike threshold. 

if isempty(tpeak)
    PSPavg=abs(mean(PSP, 2)-mean(mean(PSP(1:2000, :), 2)));
    [ind_peak]=find(PSPavg==max(PSPavg(t>0 & t<0.03)));
    tpeak=t(ind_peak);
end;

Vmpeak=zeros(2, length(Vmpre));

for i=1:size(PSPorg, 2)
    spks=Spksall(:, i);
    if ~isempty(find(spks)) 
        spks=find(spks);
        if any(t(spks)>=0.005 & t(spks)<=0.025)
            % spike occurs after touch
            ix=find(t(spks)>=0.005 & t(spks)<=0.025);
            spktime=spks(ix(1));
            Vmpeak(:, i)=[PSPorg(spktime, i); 1];
        else
            Vmpeak(:, i)=[mean(PSP(t>=tpeak-0.001 &  t<=tpeak+0.001, i)); 0];
        end;
    else
        Vmpeak(:, i)=[mean(PSP(t>=tpeak-0.001 &  t<=tpeak+0.001, i)); 0];
    end;
end;


subplot(2, 2, 3)
set(gca, 'nextplot', 'add', 'fontsize', 8)
plot(touch.t, PSPorg, 'color', [0.75 0.75 0.75]);
hold on

plot(touch.t, mean(PSP, 2), 'color', 'k', 'linewidth', 2);

set(gca, 'xlim', [-0.025 0.05], 'xtick', [-0.02:0.01:0.05], 'ylim', Vrange, 'xticklabel', {'20', '10', '0', '10', '20', '30', '40', '50'})

line([0 0], Vrange)
line([tpeak tpeak], Vrange)

xlabel('Time (ms)');
ylabel('Vm (mV)')

title([touch.cellname])

p=polyfit(Vmpre, Vmpeak(1, :)-Vmpre, 1);

subplot(2, 2, 4)
set(gca, 'nextplot', 'add', 'fontsize', 8, 'xlim', [min(Vmpre) max(Vmpre)])


plot(Vmpre(Vmpeak(2, :)==0), Vmpeak(1, Vmpeak(2, :)==0)-Vmpre(Vmpeak(2, :)==0), 'o', 'color', [0.75 0.75 0.75])
plot(Vmpre(Vmpeak(2, :)==1), Vmpeak(1, Vmpeak(2, :)==1)-Vmpre(Vmpeak(2, :)==1), 'o', 'color', [0 0.45 0.74])

hold on
plot([min(Vmpre):0.1:max(Vmpre)], polyval(p, [min(Vmpre):0.1:max(Vmpre)]), 'color', 'c', 'linewidth', 2)
line(Vrange, [0 0], 'color', 'k', 'linestyle', ':')
Vmrev=-p(2)/p(1)
xlabel('Pre-touch Vm (mV)')
ylabel('deltaVm (mV)')

text(median(Vmpre), 2, num2str(round(Vmrev*10)/10), 'fontsize', 8)

% saveas(gcf, [touch.cellname 'reversalVm'], 'fig')
print (gcf,'-dpdf', [touch.cellname 'reversalVm' ]);
% print(gcf, '-depsc2', 'IONcutL4FS')
touchVm.cellname=touch.cellname;
touchVm.t=t;
touchVm.PSP=PSP;
touchVm.PSPorg=PSPorg;
touchVm.pretouch=Vmpre;
touchVm.posttouch=Vmpeak;
touchVm.deltaVm=Vmpeak(1, :)-Vmpre;
touchVm.meandVm=[mean(Vmpeak(1, :)-Vmpre), std(bootstrp(1000, @mean, Vmpeak(1, :)-Vmpre))];





