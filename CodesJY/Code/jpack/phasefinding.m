function phaseout=phasefinding(wxcorr, stim, tosave)

% take the product of neuralphase to determine the preferred phase of avg
% Vm

if stim==1
 stimcol=[255 159 0]/255;
elseif stim==2
stimcol=[0 0 0.75];
end;

if nargin<3
    tosave=0;
    if nargin<2
        stim=0;
    end;
end;

twhiskavg=wxcorr.twhiskavg;
whiskavg=mean(wxcorr.whiskavg_nostim, 2);
vmavg=mean(removeAP(wxcorr.whiskvmavg_nostim, 10000, 5, 8, 100, 8), 2);
tvmavg=wxcorr.tvmavg;

if stim % if stim condition is considered
    whiskavg_stim=mean(wxcorr.whiskavg_stim, 2);
    vmavg_stim=mean(removeAP(wxcorr.whiskvmavg_stim, 10000, 5, 8, 100, 8), 2);
end;

figure;
subplot(2, 1, 1)
plot(wxcorr.tvmavg, vmavg, 'k')
if stim
    hold on
    plot(wxcorr.tvmavg, vmavg_stim, 'color', stimcol);
    hold off
end;

subplot(2, 1, 2)
plot(wxcorr.twhiskavg, whiskavg, 'k')
if stim
    hold on
    plot(wxcorr.twhiskavg, whiskavg_stim, 'color', stimcol);
    hold off
end;

ind=find(abs(twhiskavg)<=0.05);
twhiskavg=twhiskavg(ind);
whiskavg=detrend(whiskavg(ind));

if stim
    whiskavg_stim=detrend(whiskavg_stim(ind));
end;

% make a damping sin function
dsf=@(a, x)a(1)*cos(2*pi*x/a(2))+a(3);
dsf_nd=@(a, x)a(1)*cos(2*pi*x/a(2));
a0(1)=max(whiskavg);

[dum, indtmin]=min(whiskavg);
tmin=abs(twhiskavg(indtmin));

a0(2)=2*tmin;
a0(3)=mean(whiskavg);

xrange=[-.1:0.001:.1];

[ahat, r, J, cov. mse]=nlinfit(twhiskavg, whiskavg', dsf, a0);
if stim
[ahat_stim, r_stim, J_stim, cov_stim. mse_stim]=nlinfit(twhiskavg, whiskavg_stim', dsf, a0);
end;
ahat

figure;
plot(twhiskavg, whiskavg, 'ko');
hold on
plot(xrange, dsf(ahat, xrange), 'r');

if stim
    plot(twhiskavg, whiskavg_stim, 'o', 'color', stimcol);
    plot(xrange, dsf(ahat_stim, xrange), 'r');
end;

% plot(xrange, dsf_nd([ahat(1) ahat(3)], xrange), 'm');

hold off
%%
ind=find(abs(tvmavg)<=0.05);
tvmavg=tvmavg(ind);
%
[bf, af]=butter(2, 2/10000, 'high');

vmavg=filtfilt(bf, af, detrend(vmavg(ind)));
if stim
    vmavg_stim=filtfilt(bf, af, detrend(vmavg_stim(ind)));
end;

% make a damping sin function
dsf2=@(a, x)a(1)*cos(2*pi*x/ahat(2)-a(2))+a(3);
a0=[];

a0(1)=1;
% a0(2)=ahat(3);
a0(2)=0;
a0(3)=0;

xrange=[-.1:0.001:.1];

[ahat2, r, J, cov, mse]=nlinfit(tvmavg, vmavg', dsf2, a0);
if stim
    [ahat2_stim, r_stim, J_stim, cov_stim, mse_stim]=nlinfit(tvmavg, vmavg_stim', dsf2, a0);
end;
ahat2

ph=ahat2(2)*180/pi;
ph=findphase(ph, ahat2(1));

ph

hf=figure;
set(hf, 'unit', 'centimeters', 'position', [4 4  12 10], 'color', 'w' ,'paperpositionmode', 'auto');

ha1=axes('unit', 'normalized', 'position',[0.15 0.6 0.35 0.35],'nextplot', 'add', 'box', 'off', 'fontsize', 8, 'xlim', [min(tvmavg) max(tvmavg)])
plot(tvmavg, vmavg, 'k.');
plot(xrange, dsf2(ahat2, xrange), 'k-', 'linewidth',  1.5);

ahat3=ahat2; ahat3(2)=0; ahat3(1)=abs(ahat2(1));
plot(xrange, dsf2(ahat3, xrange), '-', 'color',[0 0.5 0], 'linewidth', 2);

if stim
    plot(tvmavg, vmavg_stim, '.', 'color', stimcol);
    plot(xrange, dsf2(ahat2_stim, xrange), '-','color', stimcol, 'linewidth', 1.5);
end;

% legend('Vm', 'Vm cos-fit', 'Angle cos-fit')

plot(xrange, 0, 'k:')

xlabel('Time (s)')
ylabel('Vm (mV)')

% spk
ha1b=axes('unit', 'normalized', 'position',[0.15 0.1 0.35 0.35],'nextplot', 'add', 'box', 'off', 'fontsize', 8, 'xlim', [min(tvmavg) max(tvmavg)])
bar(wxcorr.thist, wxcorr.whiskspkhist_nostim, 'barwidth', 1, 'facecolor', 'none', 'edgecolor', 'k');
if stim
    bar(wxcorr.thist, wxcorr.whiskspkhist_stim, 'barwidth', 1, 'facecolor', 'none', 'edgecolor', stimcol);
end;

xlabel('Time (s)')
ylabel('Spk (Hz)')

% fit spike histogram with a sinusoidal function
dsf2spk=@(asp, x)asp(1)*cos(2*pi*x/ahat(2)-asp(2))+asp(3);
asp0=[];
asp0(1)=1;
% a0(2)=ahat(3);
asp0(2)=0;
asp0(3)=mean(wxcorr.whiskspkhist_nostim);
xrange=[-.1:0.001:.1];

[ahatsp2, rsp, Jsp, covsp, msesp]=nlinfit(wxcorr.thist(wxcorr.thist>=-0.05 & wxcorr.thist<=0.05),wxcorr.whiskspkhist_nostim(wxcorr.thist>=-0.05 & wxcorr.thist<=0.05), dsf2spk, asp0);

if stim
    [ahatsp2_stim, rsp_stim, Jsp_stim, covsp_stim, msesp_stim]=nlinfit(wxcorr.thist(wxcorr.thist>=-0.05 & wxcorr.thist<=0.05), wxcorr.whiskspkhist_stim(wxcorr.thist>=-0.05 & wxcorr.thist<=0.05), dsf2spk, asp0);
end;

ahatsp2
plot(xrange, dsf2spk(ahatsp2, xrange),'color', 'k','linewidth', 1.5, 'linestyle', '-');
if stim
plot(xrange, dsf2spk(ahatsp2_stim, xrange),'color', stimcol,'linewidth', 1.5, 'linestyle', '-');
end
% preferred phase:
phsp=ahatsp2(2)*180/pi;
phsp=findphase(phsp, ahatsp2(1));
phsp

%% base on phase and Vm, not on time domain

phasebins=wxcorr.phasebincenters;
vmbins=nanmean(wxcorr.Vmphase_nostim, 2);
if stim
    vmbins_stim=nanmean(wxcorr.Vmphase_stim, 2);
end;

dsf3=@(a, x)a(1)*cos(x-a(2))+a(3);
a0=[];
a0(1)=1;
a0(2)=0;
a0(3)=mean(vmbins);

xrange2=[-pi:0.1:pi];
[ahat3, r, J, cov, mse]=nlinfit(phasebins, vmbins', dsf3, a0);
if stim
    [ahat3_stim, r_stim, J_stim, cov_stim, mse_stim]=nlinfit(phasebins, vmbins_stim', dsf3, a0);
end;

ph2=ahat3(2)*180/pi;
% prefphase=findphase(phasein, amp)
ph2=findphase(ph2, ahat3(1));

% hf2=figure;
% set(hf2, 'unit', 'centimeters', 'position', [4 4 7 7], 'paperpositionmode', 'auto');
axes('unit', 'normalized', 'position', [0.63 0.6 0.35 0.35], 'nextplot', 'add', 'box', 'off', 'xlim', [-4 4], 'xtick', [-3.14 0 3.14], 'fontsize', 8 )
plot(phasebins, vmbins, 'ko');
plot(xrange2, dsf3(ahat3, xrange2), 'k', 'linewidth', 1.5);
if stim
    plot(phasebins, vmbins_stim, 'o', 'color', stimcol);
    plot(xrange2, dsf3(ahat3_stim, xrange2), 'color', stimcol, 'linewidth', 1.5);
end;

ylim_vm=get(gca, 'ylim');
if abs(diff(ylim_vm))<1
    set(gca, 'ylim', [mean(ylim_vm)-.5 mean(ylim_vm)+.5]);
end;

rsquarevm=1-sum(r.^2)/sum((vmbins-mean(vmbins)).^2);
% legend('Vm', 'Vm cos-fit')

xlabel('Phase')
ylabel('Vm (mV)')

% spk
axes('unit', 'normalized', 'position', [0.63 0.1 0.35 0.35], 'nextplot', 'add', 'box', 'off', 'xlim', [-4 4], 'xtick', [-3.14 0 3.14], 'fontsize', 8)
plot(phasebins, wxcorr.spkphase_nostim, 'ko')
xlabel('Phase')
ylabel ('Spk/cycle')

% fit the spike phase function
dsfsp3=@(asp, x)asp(1)*cos(x-asp(2))+asp(3);
asp0=[];
asp0(1)=1;
asp0(2)=0;
asp0(3)=mean(wxcorr.spkphase_nostim);

[ahatsp3, rsp, Jsp, covsp, msesp]=nlinfit(phasebins, wxcorr.spkphase_nostim, dsfsp3, asp0);
if stim
    [ahatsp3_stim, rsp_stim, Jsp_stim, covsp_stim, msesp_stim]=nlinfit(phasebins, wxcorr.spkphase_stim, dsfsp3, asp0);
end;

phasein=ahatsp3(2)*180/pi;
prefphase=findphase(phasein, ahatsp3(1))
plot(xrange2, dsfsp3(ahatsp3, xrange2), 'k', 'linewidth', 1.5)

if stim
    plot(phasebins, wxcorr.spkphase_stim, 'o', 'color', stimcol)
    plot(xrange2, dsfsp3(ahatsp3_stim, xrange2),'color', stimcol, 'linewidth', 1.5)
end;

phaseout.whiskcycle=ahat(2);
phaseout.Vmmodulation=abs(ahat2(1));
phaseout.Vmcycle=ahat(2);
phaseout.Vmphase=ph;
phaseout.xsim=xrange;
phaseout.ysim=dsf2(ahat2, xrange);
phaseout.xreal=tvmavg;
phaseout.yreal=vmavg;

phaseout.Spkmodulation=abs(ahatsp2(1));
phaseout.Spkcycle=ahatsp2(2);
phaseout.Spkphase=phsp;

phaseout.Vmphase2=ph2;
phaseout.Vmmodulation2=abs(ahat3(1));
phaseout.xsim2=xrange2;
phaseout.ysim2=dsf3(ahat3, xrange2);
phaseout.xreal2=phasebins;
phaseout.yreal2=vmbins;
phaseout.rsquarevm=rsquarevm;

phaseout.Spkmodulation2=abs(ahatsp3(1));
phaseout.Spkcycle2=ahatsp3(2);
phaseout.Spkphase2=prefphase;

if tosave
    export_fig (hf, 'phase-tuning', '-tiff')
    export_fig (hf, 'phase-tuning', '-pdf');
    saveas(hf, 'phase-tuning', 'fig')
    save whiskingphaseout phaseout
end;

function prefphase=findphase(phasein, amp)
if amp<0
    if phasein<0
        phasein=180+phasein;
    else
        phasein=phasein-180
    end;
end;

if phasein>180
    phasein=rem(phasein, 360);
    if phasein>180
        phasein=phasein-360;
    end;
elseif phasein<-180
    phasein=rem(phasein, 360);
    if phasein<-180
        phasein=phasein+360;
    end;
end;

prefphase=phasein;