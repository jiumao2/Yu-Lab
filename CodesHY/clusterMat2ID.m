function idx_clusters = clusterMat2ID(cluster_matrix)
n_units = size(cluster_matrix, 1);
idx_clusters = nan(1, n_units);

cluster_matrix(eye(n_units) == 1) = 1;

count_cluster = 0;
for k = 1:n_units
    if isnan(idx_clusters(k))
        count_cluster = count_cluster + 1;
        idx_clusters(cluster_matrix(k,:) == 1) = count_cluster;
    end
end

end