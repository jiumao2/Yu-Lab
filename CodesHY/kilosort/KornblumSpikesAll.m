function KornblumSpikesAll(r)

for i =1: length(r.Units.SpikeTimes)
   KornblumSpikes(r, i);  
close all;
end;
