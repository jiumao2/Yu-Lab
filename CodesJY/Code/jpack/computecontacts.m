function touch=computecontacts(T, contacts, th, badtrials, xlims, spkbin, minITI, whiskid, opgtype, opgcomtype, plotstim, ci,  stimtype, prct_speed, t_range, useVth)
% touch=computecontacts(T, contacts, th, badtrials, xlims, spkbin)

% new program for computing touch-evoked activity based on "contacts"
% meanwhile, correcting touch time in whiskingvmout
if nargin<16
    useVth=0;
if nargin<15
    t_range=[0 4];
    if nargin<14
        prct_speed=2.5;
        if nargin<13
            stimtype=[];
            if nargin<12
                ci=0;
                if nargin<11
                    plotstim=0;
                    if nargin<10
                        opgcomtype=[];
                        if nargin<9
                            opgtype='blue';
                            if nargin<8
                                whiskid=0;
                                if nargin<7
                                    minITI=0.2;
                                    if nargin<6
                                        spkbin=5;
                                        if nargin<5
                                            xlims=[];
                                            if nargin<4
                                                badtrials=[];
                                            end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;
end;

set(0, 'defaultaxesfontsize', 10);
% compute touch-evoked PSP from whiskingvmout and contacts (manually scored)
% results could either from any first touch or the first touch of a
% specific whisker
% tpre:50 ms, tpost: 200 ms;
% seperate stim versus no stim trials
% seperate go versus nogo touch

%
Fs=10000;
tpre=.2*Fs-1; % 200 ms before touch onset/offset
tpost=.5*Fs; % 500 ms after touch onset/offset
touch.cellname=[T.cellNum T.cellCode];
touch.t=[-tpre:tpost]/Fs;
% These are the on activity
touch.PSP=[];
touch.PSPorg=[];
touch.PSPnoap=[];
touch.Spk=[];
touch.FP=[];

% These are the off activity
touch.PSPoff=[];
touch.Spkoff=[];
touch.FPoff=[];
touch.Rank=[];
touch.ITI=[]; % pre-touch inter-touch interval
touch.TrialNum=[];
touch.trialTypes={};
touch.GoNogo=[]; % 1, Go, 2, NOGo
touch.trialCorrect=[]; % 1, correct, 2, noncorrect
touch.Prelick=[]; % 1 means before the first lick, 0 means no
touch.meandeltaKappa=[]; % mean kappa minus kappa in 3 frams before the touch, one can set up a threshold to determine whether it is pro or ret
touch.kappas={};
touch.speed=[];
touch.distance=[];
touch.passive=[];
touch.whiskid=[];
touch.onset=[];
touch.dur=[];
touch.direction=[];

% first, go through contacts
for i=1:length(contacts)
    ic=contacts{i};
    it=T.trials{i};
    if ~isempty(it.whiskerTrial)
        if isempty(intersect(it.trialNum, badtrials))
            % multiple whisker
            for wid=1:length(ic.tid)
                time_wid=it.whiskerTrial.time{wid};
                time_Vm=[0:length(it.spikesTrial.rawSignal)-1]/it.spikesTrial.sampleRate-0.01; % 0.01 is the 10 ms offset between ephys and frame acquisition
                tvm=[0:length(it.spikesTrial.rawSignal)-1]/10;
                FP=it.spikesTrial.FP;
                Vm=it.spikesTrial.rawSignal;
                Spk=sparse([], [], [], size(Vm, 1), size(Vm, 2));
                
                load('spikes.mat')
                
                spike_trial=spikes.time(find(spikes.trialnums==i));
                
                if ~isempty(spike_trial)
                    
                    for iap=1:length(spike_trial)
                        Spk(tvm==spike_trial(iap))=1;
                    end;
                end;
                
                % for whole-cell data:
                if median(Vm(:))<-30 || useVth==1
                    cfile=dir(['VthJY' '*.mat']);
                    if ~isempty(cfile) 
                        load(cfile.name);
                        [Vmnoap]=removeAPnew(Vm,Fs,0.33, Vth.Vbound, 10000,0);
                    else
                        [Vmnoap]=removeAPnew(Vm,Fs,0.33, [-55 -45 100 10], 10000,0);
                    end;
                    
                    % for cell-attached data:
                else
                    Vmnoap=medfilt1(Vm, 11);
                end;
                
                if ~isempty(ic.contactInds{wid}) % there are contacts
                    segs=ic.segmentInds{wid};
                    for k=1:size(segs, 1)
                        cbeg=segs(k, 1);
                        tcbeg=time_wid(cbeg);
                        cend=segs(k, 2);
                        tcend=time_wid(cend);
                        
                        [~, ibeg]=min(abs(time_Vm-tcbeg));
                        [~, iend]=min(abs(time_Vm-tcend));
                        
                        if iend+tpost<size(Vm, 1)
                            indVmbeg=[ibeg-tpre:ibeg+tpost];
                            indVmend=[iend-tpre:iend+tpost];
                            touch.onset=[touch.onset tcbeg];
                            touch.dur=[touch.dur tcend-tcbeg];
                            
                            touch.PSP=[touch.PSP sgolayfilt(Vm(indVmbeg), 3, 5)];
                            touch.PSPorg=[touch.PSPorg Vm(indVmbeg)];
                            touch.PSPnoap=[touch.PSPnoap Vmnoap(indVmbeg)];
                            
                            touch.Spk=[touch.Spk Spk(indVmbeg)];
                            if ~isempty(FP)
                                touch.FP=[touch.FP FP(indVmbeg)];
                                touch.FPoff=[touch.FPoff FP(indVmend)];
                            end;
                            
                            touch.PSPoff=[touch.PSPoff Vm(indVmend)];
                            touch.Spkoff=[touch.Spkoff Spk(indVmend)];
                            
                            if k==1
                                touch.ITI=[touch.ITI tcbeg];
                            else
                                touch.ITI=[touch.ITI tcbeg-time_wid(segs(k-1, 2))];
                            end;
                            
                            touch.TrialNum=[touch.TrialNum it.trialNum];
                            touch.whiskid=[touch.whiskid ic.tid(wid)];
                            touch.GoNogo=[touch.GoNogo it.behavTrial.trialType]; % 'hit', 'cr', 'fa', 'ms'
                            touch.trialCorrect=[touch.trialCorrect it.behavTrial.trialCorrect];
                            touch.trialTypes{end+1}=it.behavTrial.trialTypeorg;
                            
                            touch.Rank=[touch.Rank k];
                            
                            if k==1 && isfield(ic, 'passive') && ic.passive==1
                                touch.passive=[touch.passive 1];
                            else
                                touch.passive=[touch.passive 0];
                            end;
                            
                            if isempty(it.behavTrial.beamBreakTimes)
                                touch.Prelick=[touch.Prelick 1];
                            elseif tcbeg<it.behavTrial.beamBreakTimes(1)
                                touch.Prelick=[touch.Prelick 1];
                            else
                                touch.Prelick=[touch.Prelick 0];
                            end;
                            touch.meandeltaKappa    =   [touch.meandeltaKappa median(it.whiskerTrial.kappa{wid}(cbeg:cend), 2)-mean(it.whiskerTrial.kappa{wid}(cbeg-2:cbeg-1))];
                            touch.kappas            =   [touch.kappas {it.whiskerTrial.kappa{wid}(cbeg-3:cend)}];
                            touch.speed             =   [touch.speed median(abs(diff(it.whiskerTrial.distanceToPoleCenter{wid}(cbeg-3:cbeg))), 2)]; % diff distanc-to-pole 3 ms to 0 ms before the touch
                            touch.distance          =   [touch.distance median(it.whiskerTrial.distanceToPoleCenter{wid}(cbeg:cend))];
                        end;
                    end;
                end;
            end;
        end;
    end;
end;


% figure out the direction of touch, assumption is that in the same trial,
% touch direction is the same

prot_dis=median(touch.distance(touch.distance>0));
ret_dis=median(touch.distance(touch.distance<0));

for i=1:length(touch.distance)
    trialnum_i=touch.TrialNum(i);
    distance_of_that_trial=touch.distance(touch.TrialNum==trialnum_i);
    median_dstt=median(distance_of_that_trial);
    
    if touch.distance(i)>0% closer to the protraction
        touch.direction(i)=1; % 1 is protraction
    elseif touch.distance(i)<0
        touch.direction(i)=-1;
    else
        touch.direction(i)=0; % undeterminable
    end;
end;

speedcutoff=prctile(touch.speed(touch.passive~=1), prct_speed); % larger than 25 percentiles
kappacutoff=0;
alltypes=cellfun(@(x)any(strfind(x, 'Stim')), touch.trialTypes); % 0, nostim; 1, stim

hf=figure(100);
set(100, 'units', 'centimeters', 'position', [2 2 20 10]*1.25, 'paperpositionmode', 'auto', 'color', 'w')
clf;

ha(1)=subplot(2, 4, 1);
%plot(touch.t, touch.PSP, 'color', [0.75 0.75 0.75]);

ind_go=find(touch.direction~=0& touch.GoNogo==1&touch.passive==0&touch.speed>=speedcutoff & alltypes==0 & touch.ITI>=minITI & touch.whiskid==whiskid & touch.onset>=t_range(1) & touch.onset<t_range(2));
if ~isempty(ind_go); hold on
    plot(touch.t, touch.PSP(:, ind_go), 'color', [0.75 0.75 0.75]);
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind_go), 3, 21), 2), 'k', 'linewidth', 2);
end;
touch.ind_go=ind_go;

axes(ha(1))
ind_nogo=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction~=0& touch.GoNogo==0&touch.passive==0&touch.speed>=speedcutoff & alltypes==0& touch.ITI>=minITI&touch.whiskid==whiskid);
if ~isempty(ind_nogo)
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind_nogo), 3, 21), 2), 'r', 'linewidth', 2);
end;
touch.ind_nogo=ind_nogo;

axis tight
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')

ylim=get(gca, 'ylim');
title(['Go (blk) and Nogo (red)'])
hold off
box off
set(gca, 'xlim', [-0.1 0.2]);
xlabel('Time (s)')
ylabel('Vm (mV)')


ha(2)=subplot(2, 4, 2);

if ~isempty(ind_nogo)
    [spk.Nogo, spk.thist]=spikehisto(touch.Spk(:,ind_nogo), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.Nogo,1, 'facecolor', 'r', 'edgecolor', 'r');
    hold on
end;

if ~isempty(ind_go)
    [spk.Go, spk.thist]=spikehisto(touch.Spk(:, ind_go), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.Go, 1, 'facecolor', 'k', 'edgecolor', 'k');
end;
set(gca, 'xlim', [-0.1 0.2]);
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
hold off
box off
xlabel('Time (s)')
ylabel('Spk (Hz)')


% protr vs retr.
ha(5)=subplot(2, 4, 5);
hold on

ind_ret=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==-1  & touch.passive==0 & touch.speed>=speedcutoff & alltypes==0& touch.ITI>=minITI&touch.whiskid==whiskid);

if ~isempty(ind_ret)
    plot(touch.t,touch.PSP(:, ind_ret(randsample(length(ind_ret), min(10, length(ind_ret))))), 'color',[0.75 0.75 0.75], 'linewidth', 0.5);
    alpha(0.5)
end;

ind_prot=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==1 &touch.passive==0& touch.speed>=speedcutoff & alltypes==0& touch.ITI>=minITI&touch.whiskid==whiskid);
if ~isempty(ind_prot)
    plot(touch.t,touch.PSP(:, ind_prot(randsample(length(ind_prot), min(10, length(ind_prot))))), 'color',[185 255 0]/255, 'linewidth', 0.5);
    alpha(0.5)
end;

if ~isempty(ind_ret)
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:,  ind_ret), 3, 21), 2), 'k', 'linewidth', 2);
end;

if ~isempty(ind_prot)
   plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind_prot), 3, 21), 2), 'color', [0 85 0]/255, 'linewidth', 2);
end;


axis tight
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
ylim=get(gca, 'ylim');
title (['Ret (blk) and Prot (green)'])
hold off
box off
set(gca, 'xlim', [-0.1 0.2]);
xlabel('Time (s)')
ylabel('Vm (mV)')

ha(6)=subplot(2, 4, 6);
if ~isempty(ind_ret)
    [spk.ret, spk.thist]=spikehisto(touch.Spk(:, ind_ret), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.ret,'k');
    hold on
end;
if ~isempty(ind_prot)
    [spk.prot, spk.thist]=spikehisto(touch.Spk(:, ind_prot), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.prot, 'facecolor',[0 85 0]/255, 'edgecolor', [0 85 0]/255);
end;
line([0 0], get(gca, 'ylim'), 'color','m', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
hold off
box off
set(gca, 'xlim', [-0.1 0.2]);
xlabel('Time (s)')
ylabel('Spk (Hz)')

touch.ind_ret=ind_ret;
touch.ind_prot=ind_prot;

%first vs later touch
ha(7)=subplot(2, 4, 7);

ind_first=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction~=0& touch.passive==0&touch.Rank<=1&alltypes==0&touch.whiskid==whiskid&touch.ITI>=minITI);
ind_later=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction~=0& touch.passive==0&touch.Rank>1&alltypes==0&touch.whiskid==whiskid&touch.ITI>=minITI);

plot(touch.t, touch.PSP(:,   ind_first), 'color', [0.75 0.75 0.75]);hold on
if ~isempty(ind_later)
plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind_later), 3, 21), 2), 'c', 'linewidth', 2);
end;
plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:,   ind_first), 3, 21), 2), 'k', 'linewidth', 2);
axis tight
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
ylim=get(gca, 'ylim');
title (['First touch (blk) and late touch (cyan)'])
hold off
box off
set(gca, 'xlim', [-0.1 0.2]);
xlabel('Time (s)')
ylabel('Vm (mV)')

ha(8)=subplot(2, 4, 8);
[spk.first, spk.thist]=spikehisto(touch.Spk(:,  ind_first), 10000,700/spkbin);
bar(spk.thist-0.2, spk.first,'k');
hold on
if ~isempty(ind_later)
    [spk.later, spk.thist]=spikehisto(touch.Spk(:,  ind_later), 10000, 700/spkbin);
    bar(spk.thist-0.2, spk.later,'facecolor', 'c', 'edgecolor', 'c');
end;
set(gca, 'xlim', [-0.1 0.2]);
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
hold off
box off
xlabel('Time (s)')
ylabel('Spk (Hz)')
% chH = get(gca,'Children')
% set(gca,'Children',[chH(end);chH(1:end-1)])

touch.ind_first=ind_first;
touch.ind_later=ind_later;

uicontrol('style', 'text', 'units', 'normalized', 'position', [.8 .9 .2 .1], 'string', [T.cellNum T.cellCode '--' 'wid' num2str(whiskid)], 'fontsize', 10, 'backgroundcolor', 'w')
uicontrol('style', 'text', 'units', 'normalized', 'position', [.3 .9 .2 .1], 'string', ['bin: ' num2str(spkbin) ' (ms)'], 'fontsize', 10, 'backgroundcolor', 'w')


if ~isempty(xlims)
    for i=1:length(ha)
        if ha(i)~=0
        set(ha(i), 'xlim', xlims);
        end;
    end;
end;

%% stim comparison
 hf2=figure(200);
    set(200, 'units', 'centimeters', 'position', [2 2 12 12]*0.85, 'paperpositionmode', 'auto', 'color', 'w')
    clf;
    if plotstim
        ha=axes;
        % only stimulaiton trials
        switch opgtype
            case 'blue'
                stimcol=[0 0 .75];
            case 'orange'
                stimcol=[255 95 0]/255;
            otherwise
                stimcol=[1 1 1];
        end;

if ~isempty(opgcomtype)
    switch opgcomtype
        case 'ret'
            ind1=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==-1  &alltypes==0 &touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
            ind2=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==-1  &alltypes==1 & touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
        case 'prot'
            ind1=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==1 &alltypes==0 &touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
            ind2=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction==1 &alltypes==1 & touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
        otherwise
            return;
    end;
else
    ind1=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction~=0 & alltypes==0 &touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
    ind2=find(touch.onset>=t_range(1) & touch.onset<t_range(2)& touch.direction~=0& alltypes==1 & touch.passive==0&touch.speed>=speedcutoff & touch.ITI>=minITI&touch.whiskid==whiskid);
end;

% get rid of touches that are outside of stimulation period

outside_stim=[];
for i=1:length(ind2)
    [~, aom]=findvmtrials(T, touch.TrialNum(ind2(i)));
    
    stim_mask=zeros(1, length(aom));
    stim_mask(aom>1)=1;
    % for high frequency stim, eg.>20 Hz, merge the gaps
    stim_mask=mergegaps(stim_mask, 500, 2); 
    [~, ind_in_aom]=min(abs(time_Vm-touch.onset(ind2(i))));
    
    if stim_mask(ind_in_aom)==0
        outside_stim=[outside_stim i];
    end;
end;

if ~isempty(outside_stim)
    ind2(outside_stim)
    ind2(outside_stim)=[];
end;

ha2(1)=subplot(2, 2, 1)
set(gca, 'nextplot', 'add', 'tickdir', 'in', 'ticklength', [0.02 0.05])
plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind1), 3, 21), 2), 'k', 'linewidth', 1.5);
hold on
% confidence interval
if ci
    psp=sgolayfilt(removeAP(touch.PSP(:, ind1), Fs, th, 4), 3, 21);
    PSP_nostimci=bootci(1000, @(x)mean(x), psp')';
    plot(touch.t, PSP_nostimci, 'k--', 'linewidth', .5);
else
    PSP_nostimci=[];
end;

touch.PSP_nostim=[mean(sgolayfilt(touch.PSPnoap(:, ind1), 3, 21), 2) PSP_nostimci];
plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind2), 3, 21), 2), 'color', stimcol, 'linewidth', 1.5);
if ci
    psp=sgolayfilt(removeAP(touch.PSP(:, ind2), Fs, th, 4), 3, 21);
    PSP_stimci=bootci(1000, @(x)mean(x), psp')';
    plot(touch.t, PSP_stimci,'color', stimcol, 'linestyle', '--', 'linewidth', .5);
else
    PSP_stimci=[];
end;
touch.PSP_stim=[mean(sgolayfilt(touch.PSPnoap(:, ind2), 3, 21), 2) PSP_stimci];

axis tight
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')

ylim=get(gca, 'ylim');
title (['Go Nostim (blk) vs ' strrep(stimtype, '_', '-') '(' opgtype ')' '-' opgcomtype '-ISI ' num2str(minITI)])
hold off
box off
set(gca, 'xlim', [-0.1 0.2]);
xlabel('Time (s)')
ylabel('Vm (mV)')
title(['minITI' num2str(round(minITI*1000)) 'ms'])


ha2(2)=subplot(2, 2, 3)
set(gca, 'nextplot', 'add', 'tickdir', 'in', 'ticklength', [0.02 0.05])
[spk.Nostim, spk.thist]=spikehisto(touch.Spk(:, ind1), 10000, 700/1);
if ~isempty(ind2)
[spk.Stim, spk.thist]=spikehisto(touch.Spk(:, ind2), 10000, 700/1);
else
    spk.Stim=zeros(size(spk.Nostim));
end;

% if ci
%     spk_nostim_ci=bootci(1000, @(x)spikehisto(x, 10000, 700/spkbin), touch.Spk(:, ind1))';
%     spk_stim_ci=bootci(1000, @(x)spikehisto(x, 10000, 700/spkbin), touch.Spk(:, ind2))';
% else
    spk_nostim_ci=[];
    spk_stim_ci=[];
% end;

touch.spk_nostim=[spk.Nostim' spk_nostim_ci];
touch.spk_stim=[spk.Stim' spk_stim_ci];
touch.spk_t=spk.thist-0.2;

if sum(spk.Stim)>sum(spk.Nostim)
    
    bar(spk.thist-0.2, spk.Stim, 1, 'edgecolor',stimcol, 'facecolor', stimcol, 'linewidth', .5);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor', stimcol,'EdgeColor', 'none','facealpha',0.75)
    
    bar(spk.thist-0.2, spk.Nostim, 1, 'edgecolor', [0 0 0], 'facecolor', [0 0 0], 'linewidth', .5);
    h1 = findobj(gca,'Type','patch');
    set(setdiff(h1, h),'FaceColor',[0 0 0],'EdgeColor', 'none','facealpha',0.75)
    
else
    bar(spk.thist-0.2, spk.Nostim, 1, 'edgecolor', [0 0 0], 'facecolor', [0 0 0], 'linewidth', .5);
    h1 = findobj(gca,'Type','patch');
    set(h1,'FaceColor',[0 0 0],'EdgeColor', 'none','facealpha',0.75)
    
    bar(spk.thist-0.2, spk.Stim, 1, 'edgecolor',stimcol, 'facecolor', stimcol, 'linewidth', .5);
    h = findobj(gca,'Type','patch');
    set(setdiff(h, h1),'FaceColor', stimcol,'EdgeColor', 'none','facealpha',0.75)
end;

if ci
plot(spk.thist-0.2, spk_nostim_ci, 'k--', 'linewidth', .5);
plot(spk.thist-0.2, spk_stim_ci, 'color', stimcol, 'linestyle', '--', 'linewidth', .5);
end;
line([0 0], get(gca, 'ylim'), 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], get(gca, 'ylim'), 'color', 'g', 'linewidth', 1, 'linestyle', '-')
hold off
box off
xlabel('Time (s)')
ylabel('Spk (Hz)')


ha2(3)=subplot(2, 2, 2)
set(gca, 'nextplot', 'add', 'tickdir', 'in', 'ticklength', [0.02 0.05])

if length(ind1)>25
    plot(touch.t,touch.PSP(:, ind1(randsample(length(ind1), 25))), 'color',[0.75 0.75 0.75], 'linewidth', 1);
else
    plot(touch.t,touch.PSP(:, ind1), 'color',[0.75 0.75 0.75], 'linewidth', 1);
end;

hold on
plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind1), 3, 21), 2), 'k', 'linewidth', 2);
axis tight
set(gca, 'xlim', [-0.1 0.2])

title('no stim')

ha2(4)=subplot(2, 2, 4)
set(gca, 'nextplot', 'add', 'tickdir', 'in', 'ticklength', [0.02 0.05])
if length(ind2)>25
    plot(touch.t,touch.PSP(:, ind2(randsample(length(ind2), 25))), 'color',[0.75 0.75 0.75], 'linewidth', 1);
else
    if ~isempty(ind2)
        plot(touch.t,touch.PSP(:, ind2), 'color',[0.75 0.75 0.75], 'linewidth', 1);
     end;
end;
hold on
if ~isempty(ind2)
    plot(touch.t, mean(sgolayfilt(touch.PSPnoap(:, ind2), 3, 21), 2), 'color', stimcol, 'linewidth', 2);
end;
axis tight
set(gca, 'xlim', [-0.1 0.2])

title('stim')

touch.ind_nostim=ind1;
touch.ind_stim=ind2;
touch.stim=stimtype;

newy=[min([get(ha2(3), 'ylim') get(ha2(4), 'ylim')]) max([get(ha2(3), 'ylim') get(ha2(4), 'ylim')])];

set(ha2(3), 'ylim', newy);
axes(ha2(3))
line([0 0], newy, 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], newy, 'color', 'g', 'linewidth', 1, 'linestyle', '-')
set(ha2(4), 'ylim', newy)
axes(ha2(4))
line([0 0], newy, 'color', 'm', 'linewidth', 1, 'linestyle', '-')
line([0.005 0.005], newy, 'color', 'g', 'linewidth', 1, 'linestyle', '-')

set(gcf, 'userdata', touch)

if ~isempty(xlims)
    for i=1:length(ha2)
        if ha2(i)~=0
            set(ha2(i), 'xlim', xlims);
        end;
    end;
end;

end;

%%

touch.minITI=minITI;
touch.t_range=t_range;

save (['ContactVm' 'wid' num2str(whiskid) 'minITI' num2str(round(minITI*1000)) 'ms' stimtype '.mat'], 'touch')

export_fig (hf, ['TouchPlot' '_wid' num2str(whiskid) 'minITI' num2str(round(minITI*1000)) 'ms'],'-pdf', '-tiff')
saveas (hf,['TouchPlot' '_wid' num2str(whiskid) 'minITI' num2str(round(minITI*1000)) 'ms'], 'fig')

if plotstim
export_fig (hf2, [stimtype 'TouchPlot' '_wid' num2str(whiskid) 'minITI' num2str(round(minITI*1000)) 'ms'],'-pdf', '-tiff', '-eps')
saveas (hf2,[stimtype 'TouchPlot' '_wid' num2str(whiskid)  'minITI' num2str(round(minITI*1000)) 'ms'], 'fig')

end;
