function d_prime = lda_metrics(all_pcs, all_labels, this_unit_id)

    % Calculates d-prime based on Linear Discriminant Analysis
    % Based on metric described in Hill et al. (2011) J Neurosci 31: 8699-8705

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
    % d_prime : float
    %     d-prime value for this unit

    X = all_pcs;

    y = false(size(X, 1), 1);
    y(all_labels == this_unit_id) = true;

    % Fit Linear Discriminant Analysis
    lda = fitcdiscr(X, y, 'DiscrimType', 'linear');

    % Predict scores for both classes
    scores = predict(lda, X);

    % Separate projections for this unit and others
    flda_this_cluster = scores(y);
    flda_other_cluster = scores(~y);

%     % Project data onto LDA space
%     X_flda = lda.Coefficients * X';
% 
%     flda_this_cluster = X_flda(y, :);
%     flda_other_cluster = X_flda(~y, :);

    d_prime = (mean(flda_this_cluster) - mean(flda_other_cluster)) / ...
              sqrt(0.5 * (std(flda_this_cluster)^2 + std(flda_other_cluster)^2));

end
