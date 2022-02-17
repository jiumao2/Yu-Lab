function [PSPonset, peaktime, PSPsize]=detectIPSPonset(t, v)

if size(t, 1)<size(t, 2)
t=t';
end;

if size(v, 2)>1
    v=mean(v, 2);
end;

figure(22); clf
set(22, 'units', 'normalized', 'position',[0.05 0.1 0.3 0.75])

ha1=subplot(3, 1, 1)
set(ha1, 'nextplot', 'add', 'xlim', [-0.05 0.1], 'xgrid', 'on','ygrid', 'on')
hpv=plot(t(t>=-0.05 & t<=0.1), v(t>=-0.05 & t<=0.1)); axis tight
set(hpv, 'tag', 'psp');
hold on;

ha2=subplot(3, 1, 2)
set(ha2, 'nextplot', 'add', 'xlim', [-0.05 0.1])
dv=smooth([0; diff(v)/0.001], 'moving', 3);
std_dv=std(dv(t<=0&t>=-0.1));
ddv=smooth([0; diff(dv)], 'moving', 3);

plot(t(t>=-0.05 & t<=0.1), dv(t>=-0.05 & t<=0.1));
line([t(1) t(end)], [3*std_dv 3*std_dv], 'color', 'r');
line([t(1) t(end)], [-3*std_dv -3*std_dv], 'color', 'r');
line([t(1) t(end)], [0 0], 'color', 'k');

ha3=subplot(3, 1, 3)
set(ha3, 'nextplot', 'add', 'xlim', [-0.05 0.1])
plot(t(t>=-0.05 & t<=0.1), ddv(t>=-0.05 & t<=0.1))
line([-0.05 0.1], [0 0], 'color', 'k')

tfirst=find(dv<=-3*std_dv & t>0);

if ~isempty(tfirst)
tfirst=tfirst(1);
plot(ha1, t(tfirst), v(tfirst), 'rx');
plot(ha2, t(tfirst), dv(tfirst), 'rx');
plot(ha3, t(tfirst), ddv(tfirst), 'rx')
% 
% % then trace back to a point when ddv==0
% 
% tfirst2=find(ddv>=0 & t<=t(tfirst)+0.002 & t>0);
% tfirst2onset=tfirst2([1; 1+find(diff(tfirst2)>1)]);
% tfirst2onset=tfirst2onset(end);
% 
% % find peaks
% inds=[tfirst2onset:tfirst2(end)];
% imax=inds(ddv(inds)==max(ddv(inds)));

onset=tfirst;

plot(ha3, t(onset), ddv(onset), 'r.')

PSPonset=t(onset); % this is where PSP started. 

plot(ha2, t(onset), dv(onset), 'm', 'marker',  '.', 'markersize', 5)
plot(ha3, t(onset), ddv(onset), 'm', 'marker',  '.', 'markersize', 5)

plot(ha1, t(onset), v(onset), 'm', 'marker', '.', 'markersize', 5)
text(0.03, mean(get(ha1, 'ylim')), num2str(1000*PSPonset))

linkaxes([ha1, ha2, ha3], 'x')
set(ha1, 'xlim', [-0.02 0.05])
PSPonset=PSPonset*1000;
end;

bb='no';
bb=questdlg('accept onset?', 'Accept onset' );

if strcmp(bb, 'No')
    set(ha1, 'xlim', [-0.02 0.05]);
    set(ha2, 'xlim', [-0.02 0.05]);
    [x, y]=ginput(1);
    PSPonset=x*1000;
    line([x x], get(ha1, 'ylim'));
    axes(ha2);
    line([x x], get(ha2, 'ylim'));
    axes(ha3);
    line([x x], get(ha3, 'ylim'));
    
    [~, onset]=min(abs(t-x));
end;
    
% find out trough
% now find out when the peak occurs
fs=round(1/(t(2)-t(1)));
newind=onset:onset+0.05*fs;

below_zero=find(dv(newind)<=0);
offsets=find([diff(below_zero)>1; below_zero(end)]);

peak_ind=newind(offsets(1));
peaktime=1000*t(peak_ind);

plot(ha2, t(peak_ind), dv(peak_ind), 'g', 'marker',  '^', 'markersize', 5)
plot(ha3, t(peak_ind), ddv(peak_ind), 'g', 'marker',  '^', 'markersize', 5)
plot(ha1, t(peak_ind), v(peak_ind), 'g', 'marker', '^', 'markersize', 5)

bb2='no';
bb2=questdlg('accept peak?', 'Accept peak' );

if strcmp(bb2, 'No')
    set(ha1, 'xlim', [-0.02 0.05]);
    set(ha2, 'xlim', [-0.02 0.05]);
    [x, y]=ginput(1);
    
    peaktime=x*1000;
    line([x x], get(ha1, 'ylim'));
    axes(ha2);
    line([x x], get(ha2, 'ylim'));
    axes(ha3);
    line([x x], get(ha3, 'ylim'));
    
    [~, peak_ind]=min(abs(t-x));
    
end;

PSPsize=v(peak_ind)-v(onset);
axes(ha1)

text(0.04, mean(get(ha1, 'ylim'), 2), num2str(peaktime), 'color', 'r')
    
  