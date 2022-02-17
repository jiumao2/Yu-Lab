function fitvstep_new(pulseout, type, fixedRs, selected)

if nargin<4
    selected=[];
    if nargin<3
        fixedRs=[];
    end;
end;

% pulseout = 
% 
%          cellname: 'JY1008AAAD'
%                 t: [1x2502 double]
%          vcontrol: [2502x261 double]
%             vstim: [2502x124 double]
%     whisk_control: [1x261 double]
%        whisk_stim: [1x124 double]
%         stimindex: [1x118 double]
%      controlindex: [1x248 double]
     
% fit vm step to find out these parameters

% current injection starts from t=0
% current is shown as I
Fs=10000;
params.Iinj=-.1;
params.tmax=100; % 100 ms
params.stepbeg=401; % onset of pulses. 
params.pulsedur=0.1;
tmax=100;

switch type
    case 'control'
        figure; plot(mean(pulseout.vcontrol(params.stepbeg+100:params.stepbeg+900, :), 1)-mean(pulseout.vcontrol(1:params.stepbeg, :), 1))
        
        if any(selected)
            v=pulseout.vcontrol(params.stepbeg+1: end, intersect(selected, pulseout.controlindex));
            vbase=repmat(mean(pulseout.vcontrol(1:params.stepbeg, intersect(selected, pulseout.controlindex)), 1), size(v, 1), 1);
        else
            v=pulseout.vcontrol (params.stepbeg+1: end, pulseout.controlindex);
            vbase=repmat(mean(pulseout.vcontrol(1:params.stepbeg, pulseout.controlindex), 1), size(v, 1), 1);
        end;
    case 'stim'
        figure; plot(mean(pulseout.vstim(params.stepbeg+100:params.stepbeg+900, :), 1)-mean(pulseout.vstim(1:params.stepbeg, :), 1))
        
        if any(selected)
            v=pulseout.vstim(params.stepbeg+1: end, intersect(selected, pulseout.stimindex));
            vbase=repmat(mean(pulseout.vstim(1:params.stepbeg, intersect(selected, pulseout.stimindex)), 1), size(v, 1), 1);
        else
            v=pulseout.vstim (params.stepbeg+1: end, pulseout.stimindex);
            vbase=repmat(mean(pulseout.vstim(1:params.stepbeg, pulseout.stimindex), 1), size(v, 1), 1);
        end
end;

t=[0:size(v, 1)-1]'/10;

v1=v(t<tmax, :);
t1=t(t<tmax);
v2=v(t>tmax, :);
t2=t(t>tmax)-tmax;
vb1=vbase(t<tmax, :); mean(vb1(:))
vb2=vbase(t>tmax, :);

% fit (t1, v1) and (t1, v2) 
hf=figure; clf
set(hf, 'units', 'centimeters', 'position', [2 1 18 10],'paperpositionmode', 'auto', 'color', 'w')

ha1=subplot(2, 2, 1); plot(t1, mean(v1, 2), 'ko')
title('onset')
ha2=subplot(2, 2, 3); plot(t2, mean(v2, 2), 'ko')
title('offset')

% here is the function

% if isempty(fixedRs)
%     a0=[120, 1, 50, 5]; % Rs, tau_s, Rin, tau_in
%     [aout, ypred1, ypred2, delta1, delta2]=fitpulseonoff(t1, v1, t2, v2, params.Iinj, a0, fixedRs);
%     
% else
%     a0=[1, 80, 10];
%     [aout, ypred1, ypred2, delta1, delta2]=fitpulseonoff(t1, v1, t2, v2, params.Iinj, a0, fixedRs);
% end;

if isempty(fixedRs)
    a0=[120, 1, 80, 5]; % Rs, tau_s, Rin, tau_in
    [aout, ypred1, delta1]=fitpulseon(t1, v1, vb1, params.Iinj, a0, fixedRs);
else
    a0=[1, 80, 5];
    [aout, ypred1, delta1]=fitpulseon(t1, v1, vb1,  params.Iinj, a0, fixedRs);
end;

% Plot results
figure(hf)
ha3=subplot(2, 2, [2 4]);
hold all;
box on;

scatter(t1,mean(v1-vb1, 2), 'k');

plot(t1,ypred1,'Color','blue', 'linewidth', 2);
plot(t1,ypred1+delta1,'Color','blue','LineStyle',':');
plot(t1,ypred1-delta1,'Color','blue','LineStyle',':');

% if ~isempty(fixedRs)
%     aout=[fixedRs aout];
% end;

text(20, -5, num2str(round(10*aout(1, 1:2))/10))
text(20, -10, num2str(round(10*aout(1, 3:4))/10))

saveas(gcf, ['VpulseFitting_' type], 'fig')
