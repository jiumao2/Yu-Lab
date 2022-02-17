allchs = live_ch;
dead_ch = setdiff(allchs, []); % all live channels for 2 16-wire arrays

avgdata     = [];
alldata       = [];


for i =1:length(dead_ch)
    ich = dead_ch(i)
    
    load(['chdat' num2str(dead_ch(i)) '.mat']);
    if i==1
        avgdata = data;
    else
        avgdata=(avgdata*(i-1)+data)/i;
    end;
end;

ind_toplt = find(index>200*1000 & index <300*1000); % plot 10 seconds of data

figure(22); clf

ha=axes('nextplot', 'add');

for i =1:size(alldata, 1)
    vtoplot = alldata(i, ind_toplt);
    [vtoplot_resample] = resample(vtoplot, 1, 30);
    plot(vtoplot_resample-i*250, 'k')
    text(100, -i*250, ['ch' num2str(i)], 'color', 'r')
end;

vtoplot_avg = avgdata(ind_toplt);
[vtoplot_avg_resample] = resample(vtoplot_avg, 1, 30);
plot(vtoplot_avg_resample-size(alldata, 1)*250, 'b', 'linewidth', 2)
axis tight
print (gcf,'-dpng', ['AvgAllChs'])
close all;

avgdata = round(avgdata);

save('chdatavg.mat', 'avgdata', 'index');