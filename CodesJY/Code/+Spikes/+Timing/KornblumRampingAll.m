function KornblumRampingAll(r)

for i =1: length(r.Units.SpikeTimes)
    KornblumRampingPressDur(r, i)
close all;
end;


 