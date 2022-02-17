ch1 = 8;
ch2 = 13;
trange =[100 102];
% 
load(['chdat' num2str(ch1) '.mat'])
v1=data;
load(['chdat' num2str(ch2) '.mat'])
v2=data;
[b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
v1filt=filtfilt(b_detect, a_detect, v1);
v2filt=filtfilt(b_detect, a_detect, v2);

allcolors                                          = varycolor(length(r.Units.Channels));

figure(26); clf(26)
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 10], 'paperpositionmode', 'auto' ,'color', 'w')

ku1 = ch1;
indku1 = find(r.Units.SpikeNotes(:, 1)==ku1);
thiscolor1 = allcolors(find(r.Units.Channels== ku1), :);
kutime1 = r.Units.SpikeTimes(indku1).timings;
kutime01 = zeros(1, max(kutime1));
kutime01(kutime1)=1;

% plot spike waveform

ha00=subplot(2, 3, 1)
set(ha00, 'nextplot', 'add', 'xtick', [-2:2], 'ytick', [-1000:500:500], 'ylim', [-1000 500])
xlabel('ms')
ylabel('uV')
allwaves = r.Units.SpikeTimes(indku1).wave;

if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=[1:size(allwaves, 1)];
end;

wave2plot = allwaves(nplot, :);

plot([1:64]/30, wave2plot, 'color', [0.8 .8 0.8]);
plot([1:64]/30, mean(allwaves, 1), 'color', thiscolor1, 'linewidth', 2)
axis([0 65/30 -1000 800])
title(['Ch' num2str(r.Units.SpikeNotes(indku1, 1))]);

ku2 = ch2;
indku2 = find(r.Units.SpikeNotes(:, 1)==ku2);
thiscolor2 = allcolors(find(r.Units.Channels== ku2), :);
kutime2 = r.Units.SpikeTimes(indku2).timings;
kutime02 = zeros(1, max(kutime2));
kutime02(kutime2)=1;

% plot spike waveform

ha02=subplot(2, 3, 2)
set(ha02, 'nextplot', 'add', 'xtick', [], 'ytick', [], 'ylim', [-1000 500])

allwaves = r.Units.SpikeTimes(indku2).wave;

if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=[1:size(allwaves, 1)];
end;

wave2plot = allwaves(nplot, :);

plot([1:64], wave2plot, 'color', [0.8 .8 0.8]);
plot([1:64], mean(allwaves, 1), 'color', thiscolor2, 'linewidth', 2)
axis([0 65 -1000 800])
title(['Ch' num2str(r.Units.SpikeNotes(indku2, 1))]);

axis off

%% compute cross correlation
% plot cross-correlation
kutime01;
kutime02;

if length(kutime01)>length(kutime02)
    kutime02 = [kutime02 zeros(1, length(kutime01)-length(kutime02))];
else
    kutime01 = [kutime01 zeros(1, length(kutime02)-length(kutime01))];
end

ha1=subplot(2, 3, 3)

set(ha1, 'nextplot', 'add', 'xtick', [-40:20:40],  'xlim', [-20 20], 'ylim', [1500 4500])
[c, lags] = xcorr(kutime01, kutime02, 50); % max lag 100 ms

hbar= bar(lags, c); % 'k', 'linewidth', 1) 
set(hbar, 'facecolor', 'k')
xlabel('Lag (ms)')
ylabel('Count');

%% plot example trace
tspk = [0:length(v1filt)]/30;
indplot = find(tspk>=trange(1)*1000 & tspk<=trange(2)*1000);

ha1=subplot(2, 3, [4 5 6])
set(ha1, 'nextplot', 'add', 'xlim', trange*1000, 'ylim', [-1200 1000]);

plot(tspk(indplot), v1filt(indplot)+400, 'color', thiscolor1);
plot(tspk(indplot), v2filt(indplot)-500, 'color', thiscolor2);

spk1=load(['times_chdat' num2str(ch1) '.mat'])
spk2=load(['times_chdat' num2str(ch2) '.mat'])

tspk1 = spk1.cluster_class(spk1.cluster_class(:,1)==1, 2);
tspk1=tspk1(find(tspk1>=trange(1)*1000 & tspk1<=trange(2)*1000));

tspk2 = spk2.cluster_class(spk2.cluster_class(:,1)==1, 2);
tspk2=tspk2(find(tspk2>=trange(1)*1000 & tspk2<=trange(2)*1000));

plot(tspk1,600, 'o', 'markersize', 3, 'color', thiscolor1, 'linewidth', 1)
plot(tspk2, -100, 'o', 'markersize', 3, 'color', thiscolor2, 'linewidth', 1)

line([trange(1) trange(1)+0.5]*1000, [-1200 -1200], 'color', 'k', 'linewidth', 3)  
text((trange(1)+0.15)*1000, -1400, '500 ms')
axis off


uicontrol('style', 'text', 'units', 'normalized', 'position', [.01 .9 .1 .3], 'string', ([r.Meta(1).Subject r.Meta(1).DateTime]), 'BackgroundColor','w', 'fontsize', 10)
print (gcf,'-dpng', ['SpikeSynchronyCh8Ch13' ])
saveas(gcf, 'SpikeSynchronyCh8Ch13', 'fig')