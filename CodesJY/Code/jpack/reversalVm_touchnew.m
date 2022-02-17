function touchVm=reversalVm_touchnew(touch, trials, tpeak, driftcorr, Vrange)

% sampling rate:
Fs= round(1/(touch.t(2)-touch.t(1)));
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
else
    [~, trials]=intersect(touch.TrialNum(touch.ind_all), trials);
    trials=trials';
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
kappa=touch.Kappa(intersect(touch.ind_all,trials));
Spksall=touch.Spk(:, intersect(touch.ind_all,trials));

t=touch.t;
[~, inds]=find(PSP(t>=-0.1 & t<0.1, :)<Vrange(1)  | PSP(t>=-0.1 & t<0.1, :)>Vrange(2));
inds=unique(inds);
PSP(:, inds)=[];
PSPorg(:, inds)=[];
Spksall(:, inds)=[];

Vmpre=mean(PSP(t>=-0.005 & t<=0, :), 1);

% when searching for peak PSP, need to consider the spike threshold. 

if isempty(tpeak)
    PSPavg=abs(mean(PSP, 2)-mean(mean(PSP(1:2000, :), 2)));
    [ind_peak]=find(PSPavg==max(PSPavg(t>0 & t<0.03)));
    tpeak=t(ind_peak);
end;

Vmpeak=zeros(3, length(Vmpre));
Vmpeaktime=zeros(1, length(Vmpre));

for i=1:size(PSPorg, 2)
    spks=Spksall(:, i);
    if ~isempty(find(spks))
        spks=find(spks);
        if any(t(spks)>=0.005 & t(spks)<=0.025)
            % spike occurs after touch
            ix=find(t(spks)>=0.005 & t(spks)<=0.025);
            spktime=spks(ix(1));
            Vmpeak(:, i)=[PSPorg(spktime, i); 1; mean(PSP(t>=tpeak-0.0025 &  t<=tpeak+0.0025, i))];
        else
            Vmpeak(:, i)=[mean(PSP(t>=tpeak-0.001 &  t<=tpeak+0.001, i)); 0; mean(PSP(t>=tpeak-0.0025 &  t<=tpeak+0.0025, i))];
        end;
    else
        Vmpeak(:, i)=[mean(PSP(t>=tpeak-0.001 &  t<=tpeak+0.001, i)); 0; mean(PSP(t>=tpeak-0.0025 &  t<=tpeak+0.0025, i))];
    end;
end;

if ~isempty(PSPorg)
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
end;

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
path=finddropbox;
pathname=[path 'Work\'];

print(gcf, '-dpng', [pathname 'Experiment_results\WhiskingTouchTransition\New\' touch.cellname 'reversalVm'] );

touchVm.cellname=touch.cellname;
touchVm.t=t;
touchVm.PSP=PSP;
touchVm.PSPorg=PSPorg;
touchVm.kappa=kappa;
touchVm.pretouch=Vmpre;
touchVm.posttouch=Vmpeak;
touchVm.deltaVm=Vmpeak(1, :)-Vmpre;
touchVm.peaktime=Vmpeaktime;
touchVm.linearfit=p;
touchVm.Vmrev=Vmrev;
