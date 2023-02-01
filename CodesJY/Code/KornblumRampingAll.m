function KornblumRampingAll(r)

for i =1: length(r.Units.SpikeTimes)
    KornblumRamping(r, i)
close all;
end


 