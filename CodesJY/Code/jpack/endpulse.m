function rin=endpulse(T, tstart, ntrials)
if nargin<3
    vm=findvmtrials(T, T.trialNums);
else
    vm=findvmtrials(T, T.trialNums(ntrials));
end;
vm2=medfilt1(vm, 31);

t=[0:size(vm2, 1)-1]/10000;

figure; 
subplot(3, 1, 1)
plot(mean(vm2, 2));
ylabel('mV')
axis tight

subplot(3, 1, 2)
plot(T.trials{2}.spikesTrial.FP)
Iinj=round(prctile(abs(T.trials{2}.spikesTrial.FP), 99)/0.25)*0.1;

axis tight

Iinj=0.1;
subplot(3, 1, 3)
vmpulse=mean(vm2(tstart*10000:tstart*10000+0.4*10000, :), 2);
vmpulse=vmpulse-mean(vmpulse(1:0.1*0.05*10000));
vmpulse=-vmpulse/Iinj;
plot([0:length(vmpulse)-1]/10, vmpulse);
legend(T.cellNum)
ylabel('Mohm')
axis tight

rin=max(vmpulse)

text(250, rin/2, sprintf('%4.1f',rin))