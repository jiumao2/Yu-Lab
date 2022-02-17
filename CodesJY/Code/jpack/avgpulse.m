function v=avgpulse(vin, onset, pulsedur, pulsenum)

fs=10000;
onset=onset*10;
cycdur=250*10;
ncyc=pulsenum;

vin=vin(onset+1:onset+ncyc*cycdur, :);
v=reshape(vin, cycdur, []);

tcyc=[1:cycdur]/10;
figure;
plot(tcyc, mean(v, 2))
export_fig(gcf, 'pulses', '-tiff')
set(gcf, 'userdata', v);
saveas(gcf, 'pulses', 'fig')