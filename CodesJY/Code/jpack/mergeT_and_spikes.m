function T=mergeT_and_spikes(T, spikes)



for i=1:length(T.trials)
    % waitbar(i/length(P.trials), h2)
    T.trials{i}.spikesTrial.spikeTimes=[];
    T.trials{i}.spikesTrial.time=[0:length(T.trials{i}.spikesTrial.rawSignal)-1]'/T.trials{i}.spikesTrial.sampleRate;
    % P.trials{i}.ephysTrial.spkmat=sparse(size(P.trials{i}.ephysTrial.spkmat, 1), size(P.trials{i}.ephysTrial.spkmat, 2));
    %T.trials{i}.spikesTrial.spkmat=sparse(size(T.trials{i}.spikesTrial.rawSignal, 1), size(T.trials{i}.spikesTrial.rawSignal, 2));
    
    if ~isempty(find(spikes.trialnums==i))
        nspk=find(spikes.trialnums==i);

        if ~isempty(spikes.choose)
            real_spike_times=spikes.time(spikes.trialnums==i & spikes.choose'==1);
        else
            real_spike_times=spikes.time(spikes.trialnums==i);
        end;
        
        if ~isempty(real_spike_times)
            for k=1:length(real_spike_times)
                [~, ind]=min(abs(T.trials{i}.spikesTrial.time*1000-real_spike_times(k)));
                T.trials{i}.spikesTrial.spikeTimes=[T.trials{i}.spikesTrial.spikeTimes T.trials{i}.spikesTrial.time(ind)];
              %  T.trials{i}.spikesTrial.spkmat(ind)=1;
            end;
        end;
    end;
end;
