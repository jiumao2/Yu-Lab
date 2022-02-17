function width=psthwidth(t, psthdata)

% based on PSTH, derive width of touch-evoked spiking. 
% psthdata

t2=[min(t):0.1:max(t)];
psthdata2=interp1(t, psthdata, t2);

figure; plot(t2, psthdata2, '.-')
hold on
line([min(t2) max(t2)], [max(psthdata2)/2 max(psthdata2)/2], 'color', 'k', 'linestyle', ':', 'linewidth', 2);
ind_above_half=find(psthdata2>=max(psthdata2)/2 & t2>=0);
plot(t2(ind_above_half), psthdata2(ind_above_half), 'r.')

baseline=std(psthdata2(t2<0))*2.5;

line([min(t2) max(t2)], [baseline baseline], 'color', 'k')
text(-10, baseline*1.25, 'baseline')

if max(psthdata2)/2>baseline % otherwise it is just noise
    
    width=t2(ind_above_half(end))-t2(ind_above_half(1));
      
end;