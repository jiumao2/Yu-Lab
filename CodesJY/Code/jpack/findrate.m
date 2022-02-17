function rateout = findrate (ratein)

Fs=10000;
nseg=length(ratein);
Nboot=1000;

h=@calrate;

rateout(1)=h(ratein);

ci=bootci(Nboot, h, ratein);

rateout ([2 3])=ci';

function datout=calrate(datin)
Fs=10000;

n=length(datin);

allspks=0;
alltimes=0;

for i=1:n
    allspks=allspks+length(find(datin{i}));
    alltimes=alltimes+length(datin{i});
end;

datout=allspks/(alltimes/Fs);