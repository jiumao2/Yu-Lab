function plotvmfpaom(whiskingvmout, xrange)

if nargin<2
    xrange=[];
end;

% plot mean traces surrounding aom

tvm=whiskingvmout.surroundAOM.tvm_stim_surround;
aom=whiskingvmout.surroundAOM.aom;
vm_stim=whiskingvmout.surroundAOM.vm_stim_surround;
vm_nostim=whiskingvmout.surroundAOM.vm_nostim_surround;
fp_stim=whiskingvmout.surroundAOM.fp_stim_surround;
fp_nostim=whiskingvmout.surroundAOM.fp_nostim_surround;

vm_stim=removeAP(sgolayfilt(vm_stim, 3, 41), 10000, 5, 4);
fp_stim=sgolayfilt(fp_stim, 3, 41)/10;
vm_nostim=removeAP(sgolayfilt(vm_nostim, 3, 41), 10000, 5, 4);
fp_nostim=sgolayfilt(fp_nostim, 3, 41)/10;

if isempty(xrange)
    xrange=[min(tvm) max(tvm)];
end;

hf=figure;
set(hf, 'unit', 'centimeters', 'position', [2 2 10 10], 'paperpositionmode', ' auto', 'color', 'w');

ha=axes;
set(ha, 'nextplot', 'add', 'unit', 'normalized', 'position', [.2 .1 .7 .3], 'xlim', xrange);
plot(tvm, mean(vm_stim, 2), 'b');
plot(tvm, mean(vm_nostim, 2), 'k')

xlabel('ms')
ylabel('mV')
ha0=axes;
set(ha0, 'nextplot', 'add', 'unit', 'normalized', 'position', [.2 .45 .7 .1], 'xlim',xrange);
plot(tvm, mean(aom, 2), 'b');
axis tight
axis off

ha1=axes;
set(ha1, 'nextplot', 'add', 'unit', 'normalized', 'position', [.2 .6 .7 .3], 'xlim', xrange, 'xtick', []);
plot(tvm, mean(fp_stim, 2), 'b');
plot(tvm, mean(fp_nostim, 2), 'color', 'k')
legend('LFP-stim', 'LFP-nostim')
linkaxes([ha, ha0, ha1], 'x')

export_fig(hf, 'vmlfpaom', '-tiff');
saveas(hf, 'vmlfpaom', 'fig')
