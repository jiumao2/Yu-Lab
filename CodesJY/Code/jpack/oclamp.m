function oclamp(v,vavg, aom)

% v is from [v, avgpulse]=avgpulses(T)

% v.stim
% v.nostim

% connecting stable v 
% subtracting voltage offset due to series resistance, calculated from avgpulses
fs=10000;
tpulseon=50; % ms
istep=-100; % -100 pA current injection

tavg=[0:length(vavg.vnostim)-1]/10; % in ms

vnostim=vavg.vnostim-mean(vavg.vnostim(tavg<=50));
vstim=vavg.vstim-mean(vavg.vstim(tavg<=50));
[Re.nostim, Rm.nostim, taue.nostim, taum.nostim]=fitvstep(vnostim, istep, tavg);

figure;
ha=axes;
set(ha, 'nextplot', 'add');
plot(tavg, vnostim, 'k');
plot(tavg, vstim, 'b')
