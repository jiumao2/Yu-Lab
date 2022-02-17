function [ge, gi]=deriveGei(Rsyn, Rl, vm, vl)

% gl(vm-El)+ge(vm-EE)+gi(Vm-Ei)=0
% ge+gi=gsum;

Ee=15;
Ei=-75;

gl=1000/Rl;
gsum=1000/Rsyn-1000/Rl;


ge=(gl*(vm-vl)+gsum*(vm-Ei))/((vm-Ei)-(vm-Ee));
gi=gsum-ge;
