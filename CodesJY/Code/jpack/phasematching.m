function phaseout=phasematching(phVm, Vmph, Spkph, stim) % phVm is the phase, Vmph is the Vm
% 3.17.2014, 
% derive phase-Vm coupling from phVm and Vmph, these are all cell data. 

if nargin<4
    stim=[];
end;

if length(phVm) ~= length(Vmph)
    
    error ('not matching')
    
end;

phasebins=[-180:30:180]*pi/180;

Vmphasebin=zeros(1, length(phasebins)-1);
spkphasebin=zeros(1, length(phasebins)-1);

durs=zeros(1,length(phVm));

for i=1:length(phVm)
    durs(i)=length(Vmph{i});
    
end;

allowed=[prctile(durs, 10) prctile(durs, 90)];

for i=1:length(phVm)
    
    if durs(i)>=allowed(1) && durs(i)<=allowed(2)
    
    [Vmphasebin(i, :), spkphasebin(i, :), phasebincenter]=divideVmonphase(Vmph{i}, Spkph{i}, phVm{i}, phasebins);

    else
        
        Vmphasebin(i, :)=NaN;
        spkphasebin(i, :)=NaN;
    end
    
end;


Vmphasebin=nanmean(Vmphasebin, 1);
spkphasebin=nansum(spkphasebin, 1)/length(phVm);


%% next, fit Vmphasebin


phasebins=phasebincenter;
vmbins=Vmphasebin;

dsf3=@(a, x)a(1)*cos(x-a(2))+a(3);
a0=[];
a0(1)=1;
a0(2)=0;
a0(3)=mean(vmbins);

xrange2=[-pi:0.1:pi];
[ahat3, r, J, cov, mse]=nlinfit(phasebins, vmbins, dsf3, a0);


ph2=ahat3(2)*180/pi;
% prefphase=findphase(phasein, amp)
ph2=findphase(ph2, ahat3(1));


hf2=figure;
set(hf2, 'unit', 'centimeters', 'position', [4 4 15 7.5], 'paperpositionmode', 'auto');
axes('unit', 'normalized', 'position', [0.15 0.2 0.35 0.7], 'nextplot', 'add', 'box', 'off', 'xlim', [-4 4], 'xtick', [-3.14 0 3.14], 'fontsize', 10)
plot(phasebins, vmbins, 'ko');
plot(xrange2, dsf3(ahat3, xrange2), 'k', 'linewidth', 1.5);


ylim_vm=get(gca, 'ylim');
if abs(diff(ylim_vm))<1
    set(gca, 'ylim', [mean(ylim_vm)-.5 mean(ylim_vm)+.5]);
end;

rsquarevm=1-sum(r.^2)/sum((vmbins-mean(vmbins)).^2);
% legend('Vm', 'Vm cos-fit')

xlabel('Phase')
ylabel('Vm (mV)')

% spk
spkphase=spkphasebin;

axes('unit', 'normalized', 'position', [0.63 0.2 0.35 0.7], 'nextplot', 'add', 'box', 'off', 'xlim', [-4 4], 'xtick', [-3.14 0 3.14], 'fontsize', 10)
plot(phasebins, spkphase, 'ko')
xlabel('Phase')
ylabel ('Spk/cycle')

% fit the spike phase function
dsfsp3=@(asp, x)asp(1)*cos(x-asp(2))+asp(3);
asp0=[];
asp0(1)=1;
asp0(2)=0;
asp0(3)=mean(spkphase);

[ahatsp3, rsp, Jsp, covsp, msesp]=nlinfit(phasebins, spkphase, dsfsp3, asp0);


phasein=ahatsp3(2)*180/pi;
prefphase=findphase(phasein, ahatsp3(1));
plot(xrange2, dsfsp3(ahatsp3, xrange2), 'k', 'linewidth', 1.5);

phaseout.phase=phasebincenter;
phaseout.Vmphase=Vmphasebin;
phaseout.Spkout=spkphasebin;

phaseout.Vmmodulation=abs(ahat3(1));
phaseout.prefph=pi*ph2/180;
phaseout.xsim=xrange2;
phaseout.ysim=dsf3(ahat3, xrange2);
phaseout.xreal=phasebins;
phaseout.yreal=vmbins;
phaseout.rsquarevm=rsquarevm;

phaseout.Spkmodulation=abs(ahatsp3(1));
phaseout.Spkcycle=ahatsp3(2);
phaseout.Spkphase=prefphase;

if isempty(stim)
save newphaseout phaseout;
saveas (hf2, 'newphaseVmcoupling', 'fig');
export_fig(hf2, 'newphaseVmcoupling', '-tiff');
else
    phaseoutstim=phaseout;
    save newphaseoutstim phaseoutstim;
saveas (hf2, 'newphaseVmcouplingstim', 'fig');
export_fig(hf2, 'newphaseVmcouplingstim', '-tiff');
end



function   [vmphasebin, spkphasebin, phasebincenter]=divideVmonphase(vm, spk, phaseall, phasebins)

tphase=[0:length(phaseall)-1];
tvm=[0:length(vm)-1]/10;
spkphasebin=zeros(1, length(phasebins)-1);

for i=1:length(phasebins)-1
    ind=find(phaseall>=phasebins(i) & phaseall<phasebins(i+1));
    if ~isempty(ind)
        indvm=[tvm>=tphase(ind(1)) & tvm<tphase(ind(end))];
        if ~isempty(indvm)
            vmphasebin(i)=mean(vm(indvm));
            spkphasebin(i)=[length(find(spk(indvm)))]; % [number of spikes length of data]
        else
            vmphasebin(i)=NaN;
            spkphasebin(i)=[0];
        end;
    else
        vmphasebin(i)=NaN;
        spkphasebin(i)=[0];
    end;
    
    phasebincenter(i)=mean([phasebins(i), phasebins(i+1)]);
    
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
elseif phasein<-180
    phasein=rem(phasein, 360);
    
    if phasein<-180
        phasein=phasein+360;
    end;
end;

prefphase=phasein;