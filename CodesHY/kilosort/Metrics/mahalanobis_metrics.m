function [isolation_distance, l_ratio] = mahalanobis_metrics(all_pcs, all_labels, this_unit_id)

    % Calculates isolation distance and L-ratio (metrics computed from Mahalanobis distance)
    % Based on metrics described in Schmitzer-Torbert et al. (2005) Neurosci 131: 1-11

    % Inputs:
    % -------
    % all_pcs : array (num_spikes x PCs)
    %     2D array of PCs for all spikes
    % all_labels : array (num_spikes x 0)
    %     1D array of cluster labels for all spikes
    % this_unit_id : int
    %     ID for the unit for which these metrics will be calculated

    % Outputs:
    % --------
    % isolation_distance : float
    %     Isolation distance of this unit
    % l_ratio : float
    %     L-ratio for this unit

    pcs_for_this_unit = all_pcs(all_labels == this_unit_id, :);
    pcs_for_other_units = all_pcs(all_labels ~= this_unit_id, :);

    mean_value = mean(pcs_for_this_unit, 1);

    try
        VI = inv(cov(pcs_for_this_unit)); % inverse of covariance matrix
    catch
        isolation_distance = NaN;
        l_ratio = NaN;
        return;
    end

%     mahalanobis_other = sort(pdist2(mean_value, pcs_for_other_units, 'mahalanobis', 'Cov', VI));
% 
%     mahalanobis_self = sort(pdist2(mean_value, pcs_for_this_unit, 'mahalanobis', 'Cov', VI));

    % Compute Mahalanobis distance manually
    mahalanobis_other = sort(sqrt(sum((pcs_for_other_units - mean_value) * VI .* (pcs_for_other_units - mean_value), 2)));
    mahalanobis_self = sort(sqrt(sum((pcs_for_this_unit - mean_value) * VI .* (pcs_for_this_unit - mean_value), 2)));

    n = min(size(pcs_for_this_unit, 1), size(pcs_for_other_units, 1)); % number of spikes

    if n >= 2
        dof = size(pcs_for_this_unit, 2); % degrees of freedom (number of features)
        
        l_ratio = sum(1 - chi2cdf(mahalanobis_other.^2, dof)) / size(mahalanobis_self, 1); % L-ratio
        isolation_distance = mahalanobis_other(n).^2; % Isolation distance
    else
        l_ratio = NaN;
        isolation_distance = NaN;
    end
end
