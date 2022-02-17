function SRTSpikesAllV3(r, FRrange)

for i =1: length(r.Units.SpikeTimes)
    SRTSpikesV3(r, i, 'FRrange', FRrange); 
    
close all;
end;
