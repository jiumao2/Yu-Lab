load spikeTable.mat

k = 1;
while k<=height(spikeTable)
    channel = spikeTable(k,:).ch;
    j = k+1;
    while j<=height(spikeTable) && spikeTable(j,:).ch == channel
        j = j+1;
    end
    
    clusters = [];
    spike_times = [];
    spikes = [];
    for i = k:j-1
        cluster_id = i-k+1;
        spike_times = [spike_times, spikeTable(i,:).spike_times_r{1}];
        clusters = [clusters,cluster_id*ones(1,length(spikeTable(i,:).spike_times{1}))];
        spikes = [spikes, spikeTable(i,:).waveforms{1}'];
    end
    [spike_times_sorted, sort_idx] = sort(spike_times,'ascend');
    clusters_sorted = clusters(sort_idx);
    cluster_class = [clusters_sorted',spike_times_sorted'];
    spikes = spikes(:,sort_idx)';
    
    par = [];
    inspk = [];
    Temp = [];
    forced = [];
    gui_status = [];
    ipermut = [];
    save(['times_chdat',num2str(channel)],'cluster_class','spikes','par','gui_status','Temp','forced','inspk','ipermut');
    
    k = j;
end
        
