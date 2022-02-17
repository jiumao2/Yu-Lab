function spkmat=reconstructspikes(T, spikes)

% re-construct spike matrix from spikes and T

spkmat=sparse([], [], [], length(T.trials{1}.spikesTrial.rawSignal), length(T.trials));
tvm=[0:length(T.trials{1}.spikesTrial.rawSignal)-1]/10;

if ~isempty(spikes)
    
    for i=1:length(T.trials)
        
        spkn=find(spikes.trialnums==i);
        
        if ~isempty(spikes.choose)
            spkn(spikes.choose(spkn)==0)=[];
        end;
        
        spkn=round(spikes.time(spkn)*10);
        
        spkmat(spkn, i)=1;
    end;
    
end;