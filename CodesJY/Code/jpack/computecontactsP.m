function touch=computecontactsP(iwdata2, params, passivetouches)
 % passtivetouches=checkpassivetouches(T, contacts, 1), 1 is the whisker
    % id
if nargin<3
    passivetouches=[];
end;

% this is the data format:
% iwdata2 = 
% 
%         cellname: 'JY0861AAAA'
%          mainwid: 0
%           allwid: 0
%        trialnums: [1x62 double]
%                k: 62
%                t: [1x5000 double]
%              tvm: [1x52000 double]
%              Vth: [1x1 struct]
%        Vthparams: [4x1 double]
%            S_ctk: [11x5000x62 double]
%     featuresName: {1x11 cell}
%               Vm: [2x5000x62 double]
%            Vmorg: [52000x62 double]
%              Spk: [5000x62 double]
%           Spkorg: [52000x62 double]

% Here is the params:
% params.Vm=1; % if 1, it is membrane potential data. 
% params.wid=0; % whisker to use
% params.t_range=[0 5]; % time used for computing touch
% params.prct_speed=2.5; % speed cut off. Low speed corresponding to slow approach to pole, not good for onset detection, etc.
% params.stimtype=[]; % if stimtype [], no stim data to be computed; possible stim type would be 'VPMinactivation'
% params.stimcolor='blue'; % blue for blue light and orange for yellow light
% params.minITI=0.025; %min inter touch interval is 25 ms
% params.tlim=[-0.05 0.05]; % when plotting, this is the range of t. 

set(0, 'defaultaxesfontsize', 10);

%
Fs=10000;

tpre=.2*Fs-1; % 200 ms before touch onset/offset
tpost=.5*Fs; % 500 ms after touch onset/offset
spkbin=1;
touch.cellname=iwdata2.cellname;
touch.mainwid=iwdata2.mainwid;
touch.contactwid=params.wid;
touch.params=params;

touch.t=[-tpre:tpost]/Fs;
% These are the on activity
touch.PSPorg=[];
touch.PSPnoap=[];
touch.Spk=[];
% These are the off activity
touch.PSPoff=[];
touch.Spkoff=[];

touch.Rank=[];
touch.ITI=[]; % pre-touch inter-touch interval
touch.TrialNum=[];

touch.speed=[];
% touch.distance=[];
touch.passive=[];
touch.onset=[];
touch.offset=[];
touch.dur=[];
touch.directiondescrpt={'1: retraction; 2: protraction'};
touch.direction=[];

touch.dKappa=[];
touch.Kappa=[];
touch.theta=[];
touch.phase=[];


% first, go through contacts
for i=1:length(iwdata2.trialnums)
    
    stim_mask=[];
    
    if isfield(iwdata2, 'opto')
        aom=iwdata2.opto(:, i);
        if isempty(params.stimtype)
            stim_mask=ones(1, length(aom));
        else
            stim_mask=zeros(1, length(aom));
            stim_mask(aom>1)=1;
            % for high frequency stim, eg.>20 Hz, merge the gaps
            stim_mask=mergegaps(stim_mask, 500, 2);
        end;
    else
        stim_mask=ones(1, length(iwdata2.Vmorg(:, i)));
    end;
    
    t=iwdata2.t;  % in seconds
    
    if length(iwdata2.allwid)==1 % more than one whisker
        itouchonsets=   find(squeeze(iwdata2.S_ctk(9, :, i))); % could be an index or could be empty
        itouchoffsets=  find(squeeze(iwdata2.S_ctk(10, :, i)));
        Kappa=  squeeze(iwdata2.S_ctk(6, :, i));
        theta=  squeeze(iwdata2.S_ctk(1, :, i));
        phase=  squeeze(iwdata2.S_ctk(3, :, i));
    else
        itouchonsets=   find(squeeze(iwdata2.S_ctk(9, :, i, params.wid+1))); % could be an index or could be empty
        itouchoffsets=  find(squeeze(iwdata2.S_ctk(10, :, i, params.wid+1)));
        Kappa=  squeeze(iwdata2.S_ctk(6, :, i, params.wid+1));
        theta=  squeeze(iwdata2.S_ctk(1, :, i, params.wid+1));
        phase=  squeeze(iwdata2.S_ctk(3, :, i, params.wid+1));
    end;
    
    if ~isempty(itouchonsets) % there are contacts, so continue
        
        tVm=    iwdata2.tvm;
        Vm=     iwdata2.Vmorg(:, i); % This is the membrane potential with spikes intact;
        Spk=    iwdata2.Spkorg(:, i);% this is the spikes
        
        if params.Vm
            [Vmnoap]=sgolayfilt(removeAPnew(Vm, Fs,0.33, params.Vthparams, 10000,0), 3, 21); % Vmnoap is the spike-removed membrane potential
        else
            Vmnoap=Vm;
        end;
        
        for k=1:length(itouchonsets) % go through each touch
            
            cbeg=itouchonsets(k);
            tcbeg=t(cbeg); % this is in seconds
            
            cend=itouchoffsets(k);
            tcend=t(cend);
            
            [~, ibeg]=min(abs(tVm-tcbeg));
            [~, iend]=min(abs(tVm-tcend));
            
            if k==1
            last_offset=tcend;
            end;
            
            if iend+tpost<50000 && stim_mask(ibeg)==1
                
                indVmbeg=[ibeg-tpre:ibeg+tpost];
                indVmend=[iend-tpre:iend+tpost];
                touch.onset=[touch.onset tcbeg];
                touch.offset=[touch.offset tcend];
                touch.dur=[touch.dur tcend-tcbeg];
                touch.TrialNum=[touch.TrialNum iwdata2.trialnums(i)];
                
                touch.PSPorg=[touch.PSPorg Vm(indVmbeg)];
                touch.PSPnoap=[touch.PSPnoap Vmnoap(indVmbeg)];
                
                touch.Spk=[touch.Spk Spk(indVmbeg)];
                
                touch.PSPoff=[touch.PSPoff Vm(indVmend)];
                touch.Spkoff=[touch.Spkoff Spk(indVmend)];
                
                if k==1
                    touch.ITI=[touch.ITI tcbeg];
                else
                    touch.ITI=[touch.ITI -last_offset+tcbeg];
                end;
                
                last_offset=tcend;
                
                touch.Rank=[touch.Rank k];
                
                if ~isempty(passivetouches)
                    if any(find(passivetouches==iwdata2.trialnums(i))) && k==1
                        touch.passive=[touch.passive 1];
                    else
                        touch.passive=[touch.passive 0];
                    end;
                else
                    touch.passive=[touch.passive 0];
                end;
                
                
                touch.Kappa=    [touch.Kappa {Kappa(cbeg-3:cend)}];
                touch.dKappa=   [touch.dKappa median(Kappa(cbeg:cend), 2)-mean(Kappa(cbeg-2:cbeg-1))];
                touch.speed=    [touch.speed median(abs(diff(theta(cbeg-3:cbeg))), 2)]; % diff distanc-to-pole 3 ms to 0 ms before the touch
                touch.theta=    [touch.theta theta(cbeg)];
                touch.phase=    [touch.phase mean(phase(cbeg-3:cbeg-1))];
            end;
        end;
    end;
end;

% use k-mean cluster to seperate protraction and retraction touch
[idx, centers]=kmeans([touch.dKappa' touch.phase'], 2); % positive dKappa and  positive phase corresponding to retraction touch. 

hf0=figure;

[~, ret_idx]    =max(centers(:, 2)); ret_idx=find(idx==ret_idx);
[~, prot_idx]   =min(centers(:, 2)); prot_idx=find(idx==prot_idx);
ha1=subplot(2, 1, 1)
plot(touch.dKappa(ret_idx), touch.phase(ret_idx), 'ko');
hold on
plot(touch.dKappa(prot_idx), touch.phase(prot_idx), 'ro')
legend('ret', 'prot')
axis tight
xlabel('dKappa')
ylabel('Phase')
title(iwdata2.cellname)

ha2=subplot(2, 1, 2)
trials=unique(touch.TrialNum);

set(gca, 'ylim', [trials(1)-1 trials(end)+1], 'xlim', [0 5], 'nextplot', 'add')

ret_new=[];
prot_new=[];

% implement a winner-take-all approach. If in a trial, most touches are one
% direction, the rest touches are also in that direction. 
touch.direction=zeros(1, length(touch.TrialNum));  
for itrial=1:length(trials)
    alltouches_itrials=find(touch.TrialNum==trials(itrial));
    direction_idx=[];
    
    axes(ha2)
    for k=1:length(alltouches_itrials)
        if find(ret_idx==alltouches_itrials(k))
            direction_idx=[direction_idx 1];
             plot(touch.onset(alltouches_itrials(k)), trials(itrial), 'ko')
        else
            direction_idx=[direction_idx 2];
           plot(touch.onset(alltouches_itrials(k)), trials(itrial), 'ro')
        end;
    end;
    
    direction_idx(direction_idx~=mode(direction_idx))=mode(direction_idx);
    
    touch.direction(alltouches_itrials)=direction_idx;
end;

axes(ha1)

plot(touch.dKappa(touch.direction==1), touch.phase(touch.direction==1), 'ko','markersize', 3, 'markerfacecolor', 'k',  'linewidth', 1);
hold on
plot(touch.dKappa(touch.direction==2), touch.phase(touch.direction==2), 'ro','markersize', 3,'markerfacecolor', 'r', 'linewidth', 1)

prct_speed=params.prct_speed;
speedcutoff=prctile(touch.speed(touch.passive~=1), prct_speed); % larger than 25 percentiles

hf=figure(100);
set(100, 'units', 'centimeters', 'position', [2 2 12 15], 'paperpositionmode', 'auto',...
    'color', 'w', 'name', [iwdata2.cellname 'wid' num2str(params.wid) params.stimtype])
clf;

subplot(3, 2, 1);
hold on

t_range=params.t_range;
minITI=params.minITI;

ind_ret=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==1  & touch.passive==0 & touch.speed>=speedcutoff & touch.ITI>=minITI);

if ~isempty(ind_ret)
    plot(touch.t,touch.PSPorg(:, ind_ret(randsample(length(ind_ret), min(10, length(ind_ret))))), 'color',[0.75 0.75 0.75], 'linewidth', 0.5);
    alpha(0.5)
end;

ind_prot=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==2 &touch.passive==0& touch.speed>=speedcutoff & touch.ITI>=minITI);
if ~isempty(ind_prot)
    plot(touch.t,touch.PSPorg(:, ind_prot(randsample(length(ind_prot), min(10, length(ind_prot))))), 'color',[185 255 0]/255, 'linewidth', 0.5);
    alpha(0.5)
end;

if ~isempty(ind_ret)
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:,  ind_ret), 3, 21), 2), 'k', 'linewidth', 2);
end;

if ~isempty(ind_prot)
   plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind_prot), 3, 21), 2), 'color', [0 85 0]/255, 'linewidth', 2);
end;


axis tight
line([0 0], get(gca, 'ylim'), 'color', 'k', 'linewidth', 1, 'linestyle', ':')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1, 'linestyle', '-')
ylim=get(gca, 'ylim');
title (['Ret (blk) and Prot (green)'])
hold off
box off
set(gca, 'xlim', params.tlim);
xlabel('Time (s)')
ylabel('Vm (mV)')

h=[];
subplot(3, 2, 2);
if ~isempty(ind_ret)
    [spk.ret, spk.thist]=spikehisto(touch.Spk(:, ind_ret), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.ret,'k');
    hold on
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor', 'k','EdgeColor', 'none','facealpha',0.75)
    
end;
if ~isempty(ind_prot)
    [spk.prot, spk.thist]=spikehisto(touch.Spk(:, ind_prot), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.prot, 'facecolor',[0 85 0]/255, 'edgecolor', [0 85 0]/255);
    h2 = findobj(gca,'Type','patch');
    set(setdiff(h2, h),'FaceColor', [0 85 0]/255,'EdgeColor', 'none','facealpha',0.75)
end;

line([0 0], get(gca, 'ylim'), 'color', 'k', 'linewidth', 1, 'linestyle', ':')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1, 'linestyle', '-')
hold off
box off
set(gca, 'xlim', params.tlim);
xlabel('Time (s)')
ylabel('Spk (Hz)')

touch.ind_ret=ind_ret;
touch.ind_prot=ind_prot;

title(iwdata2.cellname)

subplot(3, 2, 5);
hold on

ind_all=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.passive==0 & touch.speed>=speedcutoff & touch.ITI>=minITI);
touch.ind_all=ind_all;

if ~isempty(ind_all)
    plot(touch.t,touch.PSPorg(:, ind_all(randsample(length(ind_all), min(10, length(ind_all))))), 'color',[0.75 0.75 0.75], 'linewidth', 0.5);
    alpha(0.5)
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:,  ind_all), 3, 21), 2), 'k', 'linewidth', 2);
end;

axis tight
line([0 0], get(gca, 'ylim'), 'color', 'k', 'linewidth', 1, 'linestyle', ':')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
ylim=get(gca, 'ylim');
title (['all touches'])
hold off
box off
set(gca, 'xlim', params.tlim);
xlabel('Time (s)')
ylabel('Vm (mV)')

subplot(3, 2, 6);
if ~isempty(ind_all)
    [spk.all]=spikehisto(touch.Spk(:, ind_all), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.all,'k');
    hold on
end;
line([0 0], get(gca, 'ylim'), 'color', 'k', 'linewidth', 1, 'linestyle', ':')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1, 'linestyle', '-')
hold off
box off
set(gca, 'xlim', params.tlim);
xlabel('Time (s)')
ylabel('Spk (Hz)')

spk.thist=spk.thist-0.2;
touch.PSTH=spk;


subplot(3, 2, 3);
hold on
% phase tuning
phasebins=[-pi:pi/3:pi];
allcolors=varycolor(length(phasebins)-1);
touch.phaseindex=zeros(1, length(touch.phase));
touch.PSPphasemean=zeros(1, length(phasebins)-1);
for i=1:length(phasebins)-1
    phaserange=[phasebins(i) phasebins(i+1)];
    bincenters(i)=mean(phaserange);
    touch.phaseindex(touch.phase>=phaserange(1) & touch.phase<phaserange(2))=i;
    ind_phasei=find(touch.phase>=phaserange(1) & touch.phase<phaserange(2) & touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.passive==0 & touch.speed>=speedcutoff & touch.ITI>=minITI);
    if ~isempty(ind_phasei)
        PSPmean_phasei=mean(touch.PSPnoap(:,  ind_phasei), 2);
        plot(touch.t, PSPmean_phasei, 'color', allcolors(i, :), 'linewidth', 2);
        touch.PSPphasemean(i)=mean(PSPmean_phasei(touch.t>=0.005 & touch.t<=0.025))-mean(PSPmean_phasei(touch.t<=0.005 & touch.t>=-0.005));
    end
end;
set(gca, 'xlim', params.tlim);
line([0 0], get(gca, 'ylim'), 'color', 'k', 'linewidth', 1, 'linestyle', ':')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1, 'linestyle', '-')
touch.phasebincenters=bincenters;

subplot(3, 2, 4);
hold on

for i=1:length(bincenters)
    plot(bincenters(i), touch.PSPphasemean(i), 'o', 'color', allcolors(i, :), 'linewidth', 1.5)
end;

plot(bincenters, touch.PSPphasemean, 'k')
set(gca, 'xlim', [-pi pi])
try
    set(gca, 'ylim', [0 max(touch.PSPphasemean)]);
end
xlabel('Phase')
ylabel('PSP (mV)')
%%

cd ('C:\Users\yuj10\Dropbox (Personal)\Work\Experiment_results\touches')

figurename=[iwdata2.cellname 'wid' num2str(params.wid) params.stimtype params.filetype];

save ([figurename '.mat'], 'touch')

export_fig (hf, [figurename],'-pdf', '-tiff')
saveas (hf, figurename, 'fig')
export_fig (hf0, ['phasekappa_' figurename],'-pdf')


