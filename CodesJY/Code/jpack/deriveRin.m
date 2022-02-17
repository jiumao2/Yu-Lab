function deriveRin(iwdata)
% using the genetic data format to derive Rin, compare Rin with and without
% opto-stimulation
%         structure of iwdata
%         cellname: 'JY1008AAAD'
%          mainwid: 0
%           allwid: [0 1]
%        trialnums: [1x32 double]
%                k: 32
%                t: [1x5000 double]
%              tvm: [1x52000 double]
%              Vth: [1x1 struct]
%        Vthparams: [4x1 double]
%            S_ctk: [4-D double]
%     featuresName: {1x11 cell}
%               Vm: [2x5000x32 double]
%            Vmorg: [52000x32 double]
%              Spk: [5000x32 double]
%           Spkorg: [52000x32 double]
%              AOM: [52000x32 double]
Fs=10000;

params.delay=1; % 0.5 sec after AOM onset.

% Here are for current pulses
params.pulse_onset=500; % onset of pulse train.
params.pulse_dur=0.1; % length of pulse
params.pulse_freq=4;
params.pulse_amp=0.1; % 0.1 nA is the usual
params.pulse_num=20; % 20 pulses in total

ntr=size(iwdata.Vmorg, 2);

vpulse_control=[];
whisk_control={};
vpulse_stim=[];
whisk_stim={};

whiskamp_control=[];
whiskamp_stim=[];

cdir=pwd;

% not going to include pulse during which touch occurs, touch should proceed pulase onset for at least 100 ms.

for i=1:ntr
    tvm=iwdata.tvm;
    iVmorg=iwdata.Vmorg(:, i);
    % removeAPnew(Vm,Fs,ratio_dvdt, Vbound, dvdtlow, toplot)
    iVm=removeAPnew(iVmorg, 10000, 0.33, iwdata.Vthparams, 10000); % remove spikes
    AOM=iwdata.AOM(:, i);
    
    % AOM mask:
    type=0;
    AOM_mask=sparse(size(tvm, 1), size(tvm, 2));
    if any(find(AOM>2))
        type=1;
        AOM_beg=tvm(find(AOM>2, 1, 'first'))+params.delay; % with delay, in sec
        AOM_end=tvm(find(AOM>2, 1, 'last')); % when AOM ends, in sec
        AOM_mask(tvm>=AOM_beg & tvm<=AOM_end)=1;
    else
        [xx1, yy]=find(iwdata.AOM>2, 1, 'first');
        [xx2, yy]=find(iwdata.AOM>2, 1, 'last');
        AOM_beg=tvm(xx1)+params.delay;
        AOM_end=tvm(xx2);
        AOM_mask(find(tvm))=1;
    end;
    
    % construct touch mask:
    if length(size(iwdata.S_ctk))==4
        %           for two whiskers:
        %           touchoff              5000x2
        %           touchon               5000x2
        % iwdata.t(find(touchon(:, wid)))--> touch time on whisker wid
        touchon=squeeze(iwdata.S_ctk(9, :, i, :)); %
        touchoff=squeeze(iwdata.S_ctk(10, :, i, :));
    else
        touchon=squeeze(iwdata.S_ctk(9, :, i)); % is a single vector
        touchoff=squeeze(iwdata.S_ctk(10, :, i));
        
        if size(touchon, 1)<size(touchon, 2)
            touchon=touchon';
            touchoff=touchoff';
        end;
    end
    
    touch_mask=[];
    for iw=1:size(touchon, 2)
        touch_mask=[touch_mask; -0.025+iwdata.t(find(touchon(:, iw)))' 0.07+iwdata.t(find(touchoff(:, iw)))']; % in seconds
    end;
    
    % next, transform touch_mask into index that matches with tvm
    touch_mask_ind=sparse(size(tvm, 1), size(tvm, 2));
    if ~isempty(touch_mask)
        for it=1:size(touch_mask, 1)
            touch_mask_ind(tvm>=touch_mask(it, 1) & tvm<=max(touch_mask(it, 1)+0.15, touch_mask(it, 2)))=1; % all touch periods are 1, else are 0
        end;
    end;
    
    twhisk=iwdata.t;
    licks=[];
    
    if length(iwdata.allwid)>1
        whisktheta=         squeeze(iwdata.S_ctk(1, :, i, iwdata.mainwid+1));           % whisking angle
        whiskthetafilt=     squeeze(iwdata.S_ctk(5, :, i, iwdata.mainwid+1));
        whiskamp=           squeeze(iwdata.S_ctk(2, :, i, iwdata.mainwid+1));           % whisking amplitude
        whiskphase=         squeeze(iwdata.S_ctk(3, :, i, iwdata.mainwid+1));           % whisking phase
        licks=              iwdata.t(find(squeeze(iwdata.S_ctk(11, :, i, 1))));               % licks in seconds
    else
        whisktheta=         squeeze(iwdata.S_ctk(1, :, i));                                      % whisking angle
        whiskthetafilt=     squeeze(iwdata.S_ctk(5, :, i));
        whiskamp=           squeeze(iwdata.S_ctk(2, :, i));                                      % whisking amplitude
        whiskphase=         squeeze(iwdata.S_ctk(3, :, i));                                      % whisking phase
        licks=              iwdata.t(find(squeeze(iwdata.S_ctk(11, :, i))));                  % licks in seconds
    end;
    
    % licks masks are here
    lick_mask_ind=sparse(size(tvm, 1), size(tvm, 2));
    if ~isempty(licks)
        for it=1:numel(licks)
            lick_mask_ind(tvm>=licks(it)-0.10 & tvm<=licks(it)+0.10)=1; % all touch periods are 1, else are 0
        end;
    end;
    

    %% now start to go through each pulse, extract the waveform and throw it into the collection bucket if it fits the requirement.
    % params.pulse_onset=502; % onset of pulse train.
    % params.pulse_dur=0.1; % length of pulse
    % params.pulse_freq=4;
    % params.pulse_amp=0.1; % 0.1 nA is the usual
    % params.pulse_num=20; % 20 pulses in total
    % means this is a stimulation trial.
    for k=1:params.pulse_num
        pulse_index=sparse(size(tvm, 1), size(tvm, 2));
        vpulse=iVm(params.pulse_onset-400+Fs*(1/params.pulse_freq)*(k-1):params.pulse_onset+1+Fs*(1/params.pulse_freq)*(k-1)+(0.1+params.pulse_dur)*Fs);
        pulse_index(params.pulse_onset-400+Fs*(1/params.pulse_freq)*(k-1):params.pulse_onset+1+Fs*(1/params.pulse_freq)*(k-1)+(0.1+params.pulse_dur)*Fs)=1;
        whiskamp_pulse=whiskamp(iwdata.t>=tvm(params.pulse_onset-400+Fs*(1/params.pulse_freq)*(k-1)) & iwdata.t<=tvm(params.pulse_onset+1+Fs*(1/params.pulse_freq)*(k-1)+(0.1+params.pulse_dur)*Fs));
        if  ~any(find(AOM_mask(find(pulse_index))==0))% ~any(find(pulse_index.*touch_mask_ind)) &&
            type
            if ~type
                vpulse_control=[vpulse_control vpulse];
                whisk_control=[whisk_control {whiskamp_pulse}];
                whiskamp_control=[whiskamp_control mean(whiskamp_pulse)];
            else
                vpulse_stim=[vpulse_stim vpulse];
                whisk_stim=[whisk_stim {whiskamp_pulse}];
                whiskamp_stim=[whiskamp_stim, mean(whiskamp_pulse)];
            end;
        end;
        
    end;
end;
tpulse=[0:size(vpulse_stim, 1)-1]/10-40;

pulseout.cellname=iwdata.cellname;
pulseout.t=tpulse;
pulseout.vcontrol=vpulse_control;
pulseout.vstim=vpulse_stim;
pulseout.whisk_control=whiskamp_control;
pulseout.whisk_stim=whiskamp_stim;

indbase=[{1:400} {400+400:400+1000} {400+1400:size(pulseout.vcontrol, 1)}];
varvm=std([sgolayfilt(detrend(pulseout.vstim(indbase{1} , :), 'constant'), 3, 41); sgolayfilt(detrend(pulseout.vstim(indbase{2} , :), 'constant'), 3, 41); sgolayfilt(detrend(pulseout.vstim(indbase{3} , :), 'constant'), 3, 41)]); % index.
vstep_stim=abs(mean(pulseout.vstim(400+400:400+1000, :), 1)-mean(pulseout.vstim(1:400, :), 1));
figure; subplot(2, 1, 1)
ax=plotyy([1:size(pulseout.vstim, 2)], varvm,[1:size(pulseout.vstim, 2)], vstep_stim);
hold on
axes(ax(1))
line([1 length(varvm)], [prctile(varvm, 95) prctile(varvm, 95)], 'color', 'b');
axes(ax(2))
line([1 length(varvm)], [prctile(vstep_stim, 95) prctile(vstep_stim, 95)], 'color', 'r');
stimindex=find(varvm<=prctile(varvm, 95) & vstep_stim<=prctile(vstep_stim, 95));

varvm=std([sgolayfilt(detrend(pulseout.vcontrol(indbase{1} , :), 'constant'), 3, 41); sgolayfilt(detrend(pulseout.vcontrol(indbase{2} , :), 'constant'), 3, 41); sgolayfilt(detrend(pulseout.vcontrol(indbase{3} , :), 'constant'), 3, 41)]); % index.
vstep_control=abs(mean(vpulse_control(400+400:400+1000, :), 1)-mean(vpulse_control(1:400, :), 1));

subplot(2, 1, 2)
ax=plotyy([1:size(pulseout.vcontrol, 2)], varvm,[1:size(pulseout.vcontrol, 2)], vstep_control);
hold on
axes(ax(1))
line([1 length(varvm)], [prctile(varvm, 95) prctile(varvm, 95)], 'color', 'b');
axes(ax(2))
line([1 length(varvm)], [prctile(vstep_control, 95) prctile(vstep_control, 95)], 'color', 'r');
controlindex=find(varvm<=prctile(varvm, 95) & vstep_control<=prctile(vstep_control, 95));

pulseout.stimindex=stimindex;
pulseout.controlindex=controlindex;


vpulse_stim_avg=mean(vpulse_stim(:, stimindex), 2);
vpulse_control_avg=mean(vpulse_control(:, controlindex), 2);


save (['C:\Work\Projects\BehavingVm\Data\Groupdata\Conductance\rawdata\' 'pulseout' iwdata.cellname '.mat'], 'pulseout')
cd (cdir)
save pulseout pulseout

hf=figure(10); clf
set(hf, 'units', 'centimeters', 'position', [2 1 20 10],'paperpositionmode', 'auto', 'color', 'w')
subplot(1, 2, 1)
plot(tpulse, vpulse_stim(:, stimindex)-repmat(mean(vpulse_stim(1:400, stimindex), 1), size(vpulse_stim, 1), 1), 'color', [77 178 255]/255, 'linewidth', 0.5);hold on
plot(tpulse, vpulse_control(:, controlindex)-repmat(mean(vpulse_control(1:400, controlindex), 1), size(vpulse_control, 1), 1), 'color', [0.75 0.75 0.75], 'linewidth', 0.5)


plot(tpulse, vpulse_stim_avg-mean(vpulse_stim_avg(1:400)), 'b', 'linewidth', 2)
plot(tpulse, vpulse_control_avg-mean(vpulse_control_avg(1:400)), 'k', 'linewidth', 2)


set(gca, 'xlim',[min(tpulse) 200])
xlabel('ms')
ylabel('mV')

subplot(1, 2, 2)
plot(whiskamp_stim(:, stimindex), abs(mean(vpulse_stim(400+400:400+1000, stimindex), 1)-mean(vpulse_stim(1:400, stimindex), 1)),'o', 'markersize', 1, 'color', 'b', 'markersize', 6);
hold on
plot(whiskamp_control(:, controlindex),abs(mean(vpulse_control(400+400:400+1000, controlindex), 1)-mean(vpulse_control(1:400, controlindex), 1)),  'o', 'markersize', 1, 'color', 'k', 'markersize', 6);
xlabel('Whisking amp (o)')
ylabel('Vstep size (mV)')

export_fig(gcf, ['Vpulse_' iwdata.cellname], '-tiff', '-eps');
saveas(hf, ['Vpulse_' iwdata.cellname], 'fig')
