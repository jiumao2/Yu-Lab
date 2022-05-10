function mua2wave_clust(chid)
% update waveclust result based on the output from simple clust

% load culstering result 
 
load(['ch' chid '_clustered']);
spksimplesort = spikes; 

simplecluster_ids = spksimplesort.cluster_is;
% (0: not clustered, 1-N: clusters)

% load sorting results from simple clust
waveclust1 = dir(['times_chdat' chid '.mat']);
if isempty(waveclust1)
    waveclust1 = dir(['times_chdat_meansub' chid '.mat']);
end;
load(waveclust1.name);
cluster_class(:, 1) = simplecluster_ids-1;
cluster_class(:, 2) =  spksimplesort.ts;

Temp = Temp(1)*ones(max(cluster_class(:, 1)), 1);

save(waveclust1.name, 'spikes', 'cluster_class', 'par', 'gui_status', 'Temp', 'forced', 'inspk', 'ipermut');
