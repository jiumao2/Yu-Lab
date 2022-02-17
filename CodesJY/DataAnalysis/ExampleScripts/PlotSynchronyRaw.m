ch1 = 8;
ch2 = 11;
trange =[200 205];
% 
% load(['chdat' num2str(ch1) '.mat'])
% v1=data;
% load(['chdat' num2str(ch2) '.mat'])
% v2=data;
[b_detect,a_detect] = ellip(4,0.1,40,[250 10000]*2/30000);  % high pass
v1filt=filtfilt(b_detect, a_detect, v1);
v2filt=filtfilt(b_detect, a_detect, v2);

% allcolors                                          = varycolor(length(r.Units.Channels));

figure(26); clf(26)
set(gcf, 'unit', 'centimeters', 'position',[2 2 15 10], 'paperpositionmode', 'auto' ,'color', 'w')


thiscolor1 = [1 0 0];
thiscolor2 = [0 0 1];


%% plot example trace
tspk = [0:length(v1filt)]/30;
indplot = find(tspk>=trange(1)*1000 & tspk<=trange(2)*1000);

ha1=axes;
set(ha1, 'nextplot', 'add', 'units', 'centimeters', 'position', [2 2 12 6], 'xlim', trange*1000, 'ylim', [-1200 1000]);

plot(tspk(indplot), v1filt(indplot)+400, 'color', thiscolor1);
plot(tspk(indplot), v2filt(indplot)-500, 'color', thiscolor2);

spk1=load(['times_chdat_meansub' num2str(ch1) '.mat'])
spk2=load(['times_chdat_meansub' num2str(ch2) '.mat'])

tspk1 = spk1.cluster_class(spk1.cluster_class(:,1)==1, 2);
tspk1=tspk1(find(tspk1>=trange(1)*1000 & tspk1<=trange(2)*1000));

tspk2 = spk2.cluster_class(spk2.cluster_class(:,1)==1, 2);
tspk2=tspk2(find(tspk2>=trange(1)*1000 & tspk2<=trange(2)*1000));

plot(tspk1,600, 'o', 'markersize', 3, 'color', thiscolor1, 'linewidth', 1)
plot(tspk2, -100, 'o', 'markersize', 3, 'color', thiscolor2, 'linewidth', 1)

line([trange(1) trange(1)+0.5]*1000, [-1200 -1200], 'color', 'k', 'linewidth', 3)  
text((trange(1)+0.15)*1000, -1400, '500 ms')
axis off

% 
% uicontrol('style', 'text', 'units', 'normalized', 'position', [.01 .9 .1 .3], 'string', ([r.Meta(1).Subject r.Meta(1).DateTime]), 'BackgroundColor','w', 'fontsize', 10)
print (gcf,'-dpng', ['SpikeSynchronyCh8Ch11'])