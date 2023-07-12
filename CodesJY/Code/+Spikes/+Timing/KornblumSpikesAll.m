function KornblumSpikesAll(r, ComputeTimeRange, Combined)
if nargin<3
    Combined =0;
    if nargin<2
        ComputeTimeRange = [];
    end;
end;

for i =1: length(r.Units.SpikeTimes)
    Spikes.Timing.KornblumSpikes(r, i, 'ComputeTimeRange', ComputeTimeRange);
    Spikes.Timing.KornblumRamping(r, i,  'ComputeTimeRange', ComputeTimeRange, 'Combined', Combined);
    close all;
end;
