function dur=halfdur(t, PSPt, dir)

if nargin<3
    dir=1;
end;

% derive half duration of touch PSP

hf=figure(88); clf

PSPt=(PSPt-mean(PSPt(t<0.003 & t>=-0.01)));
if dir<0
    PSPt=-PSPt;
end;
ha=axes('nextplot', 'add', 'xlim', [min(t) max(t)]);
plot(t, PSPt)
halfamp=0.5*max(PSPt(t>0));
line([min(t) max(t)], [halfamp halfamp], 'linestyle', '--', 'color', 'k')

twindow=find(t>0 & t<0.2);
above=find(PSPt(twindow)>halfamp);

diff_above=diff(above);
if any(diff_above>1)
    above=above(1:find(diff_above>1));
end;

plot(t(twindow(above)), PSPt(twindow(above)), 'r.')
dur=length(above)/10
if dur<5
    dur=nan;
end;


