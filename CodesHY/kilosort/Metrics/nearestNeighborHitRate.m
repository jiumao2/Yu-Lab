function [hit_rate, miss_rate] = nearestNeighborHitRate(pcs, cluster_ids, unit_id, max_spikes, n_neighbors)
    % Calculate unit contamination based on NearestNeighbors search in PCA space.
    %
    % Parameters
    % ----------
    % all_pcs : 2D array
    %     The PCs for all spikes, organized as [num_spikes, PCs].
    % all_labels : 1D array
    %     The cluster labels for all spikes. Must have length of number of spikes.
    % this_unit_id : int
    %     The ID for the unit to calculate these metrics for.
    % max_spikes : int
    %     The number of spikes to use, per cluster.
    %     Note that the calculation can be very slow when this number is >20000.
    % n_neighbors : int
    %     The number of neighbors to use.
    %
    % Returns
    % -------
    % hit_rate : float
    %     Fraction of neighbors for target cluster that are also in target cluster.
    % miss_rate : float
    %     Fraction of neighbors outside target cluster that are in target cluster.

    if nargin < 4
        max_spikes = 10000;
    end

    if nargin < 5
        n_neighbors = 5;
    end

    total_spikes = size(pcs, 1);
    ratio = max_spikes / total_spikes;

    % If no other units in the vicinity, return best possible option
    if numel(unique(cluster_ids)) == 1
        warning('No other units found in the vicinity of %d. Setting nn_hit_rate=1 and nn_miss_rate=0', unit_id);
        hit_rate = 1.0;
        miss_rate = 0.0;
        return;
    end

    this_unit = cluster_ids == unit_id;
    this_unit_pcs = pcs(this_unit, :);
    other_units_pcs = pcs(~this_unit, :);
    X = [this_unit_pcs; other_units_pcs];

    num_obs_this_unit = sum(this_unit);

    if ratio < 1
        inds = round(linspace(1, size(X, 1), floor(size(X, 1) * ratio)))';
        X = X(inds, :);
        num_obs_this_unit = floor(num_obs_this_unit * ratio);
    end

    % Use the 'knnsearch' function for nearest neighbors
    [indices, ~] = knnsearch(X, X, 'K', n_neighbors);

    this_cluster_nearest = indices(1:num_obs_this_unit, 2:end);
    other_cluster_nearest = indices(num_obs_this_unit+1:end, 2:end);

    hit_rate = mean(this_cluster_nearest(:) <= num_obs_this_unit);
    miss_rate = mean(other_cluster_nearest(:) <= num_obs_this_unit);

end
