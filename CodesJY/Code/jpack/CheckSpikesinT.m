function CheckSpikesinT(T, trialnum)


ind=find(T.trialNums==trialnum);

x=T.trials{ind}.spikesTrial;


figure;
subplot(2, 1, 1)
plot(x.rawSignal, 'k')

hold on

plot(x.spikeTimes, x.rawSignal(x.spikeTimes), 'ro')


subplot(2, 1, 2)
[b, a]=butter(4, 300*2/10000, 'high');

v2=filtfilt(b, a, detrend(x.rawSignal));

plot(v2, 'k')

hold on

plot(x.spikeTimes, v2(x.spikeTimes), 'ro')
