function spkmat=reconstructspikesnew(T)

% re-construct spike matrix from spikes and T

spkmat=sparse([], [], [], length(T.trials{1}.spikesTrial.rawSignal), length(T.trials));

for i=1:length(T.trials)
    time=T.trials{i}.spikesTrial.time;
    if ~isempty(T.trials{i}.spikesTrial.spikeTimes)
        [~, ia, ib]=intersect(time, T.trials{i}.spikesTrial.spikeTimes);
        spkmat(ia, i)=1;
    end;
end;