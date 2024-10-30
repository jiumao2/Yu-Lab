function [isolation_distance, d_prime, nn_miss_rate, nn_hit_rate, l_ratio] = calculate_pc_metrics_one_cluster(cluster_peak_channels, idx, cluster_id, cluster_ids, ...
    half_spread, pc_features, pc_feature_ind, spike_clusters, spike_templates, ...
    max_spikes_for_cluster, max_spikes_for_nn, n_neighbors, chanMap)

    peak_channel = cluster_peak_channels(idx);
    num_spikes_in_cluster = sum(spike_clusters == cluster_id);

%     half_spread_down = min(peak_channel, half_spread);
%     half_spread_up = min(max(pc_feature_ind) - peak_channel, half_spread);
% 
%     channels_to_use = peak_channel - half_spread_down : peak_channel + half_spread_up;

    % channels_to_use should be determined by the location
    is_connected = chanMap.connected == 1;
    xcoords = chanMap.xcoords(is_connected);
    ycoords = chanMap.ycoords(is_connected);

    x_dist = abs(xcoords - xcoords(peak_channel+1));
    y_dist = abs(ycoords - ycoords(peak_channel+1));
    [~, idx_sort] = sort(sqrt(x_dist.^2 + y_dist.^2));
    channels_to_use = idx_sort(1:1+half_spread*2) - 1;

    units_in_range = cluster_ids(ismember(cluster_peak_channels, channels_to_use));

    spike_counts = zeros(size(units_in_range));

    for idx2 = 1:length(units_in_range)
        cluster_id2 = units_in_range(idx2);
        spike_counts(idx2) = sum(spike_clusters == cluster_id2);
    end

    if num_spikes_in_cluster > max_spikes_for_cluster
        relative_counts = spike_counts / num_spikes_in_cluster * max_spikes_for_cluster;
    else
        relative_counts = spike_counts;
    end

    all_pcs = zeros(0, size(pc_features, 2), length(channels_to_use));
    all_labels = [];

    for idx2 = 1:length(units_in_range)
        cluster_id2 = units_in_range(idx2);
        subsample = round(relative_counts(idx2));

        pcs = get_unit_pcs(cluster_id2, spike_clusters, spike_templates, ...
            pc_feature_ind, pc_features, channels_to_use, subsample);

        if ~isempty(pcs) && ndims(pcs) == 3
            labels = ones(size(pcs, 1), 1) * cluster_id2;

            all_pcs = cat(1, all_pcs, pcs); % Concatenate along the first dimension
            all_labels = [all_labels; labels]; % Concatenate labels
        end
    end

    all_pcs = reshape(all_pcs, size(all_pcs, 1), size(pc_features, 2) * length(channels_to_use));

    if size(all_pcs, 1) > 10 && ...
        ~all(all_labels == cluster_id) && ... % Not all labels are this cluster
        sum(all_labels == cluster_id) > 20 && ... % No fewer than 20 spikes in this cluster
        ~isempty(channels_to_use)
        
        [isolation_distance, l_ratio] = mahalanobis_metrics(all_pcs, all_labels, cluster_id);
        
        try
            d_prime = lda_metrics(all_pcs, all_labels, cluster_id);
        catch
            d_prime = NaN;
        end

        [nn_hit_rate, nn_miss_rate] = nearestNeighborHitRate(all_pcs, all_labels, ...
            cluster_id, max_spikes_for_nn, n_neighbors);
    else
        % Too few spikes or cluster doesn't exist
        isolation_distance = NaN;
        d_prime = NaN;
        nn_miss_rate = NaN;
        nn_hit_rate = NaN;
        l_ratio = NaN;
    end
end
