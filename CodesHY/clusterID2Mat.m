function cluster_matrix = clusterID2Mat(idx_clusters)
n_units = length(idx_clusters);
cluster_matrix = zeros(n_units, n_units, 'logical');
cluster_matrix(eye(n_units) == 1) = 1;

for k = 1:length(idx_clusters)
    cluster_matrix(k, idx_clusters == idx_clusters(k)) = 1;
end

end


