function SRTSpikesAll(r, FRrange)

for i =1: length(r.Units.SpikeTimes)
    SRTSpikes(r, i, 'FRrange', FRrange); 
    
close all;
end;
