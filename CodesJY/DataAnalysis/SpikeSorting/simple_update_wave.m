function simple_update_wave(chid)
% update waveclust result based on the output from simple clust

% load culstering result 
load(['ch' chid '_clustered']);
spksimplesort = spikes;

simplecluster_ids = spikes.cluster_is;
% (0: not clustered, 1-N: clusters)

% load sorting results from simple clust
waveclust1 = dir(['times_chdat_' chid '.mat']);
if isempty(waveclust1)
    waveclust1 = dir(['chdata_meansub' chid '.mat']);
end;

load(waveclust1.name);

figure;