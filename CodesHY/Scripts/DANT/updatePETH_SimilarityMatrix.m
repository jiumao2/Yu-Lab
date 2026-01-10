function similarity_matrix_all = updatePETH_SimilarityMatrix(similarity_matrix_all, feature_names_all, PETH_features)
max_similarity = 6;

idx_PETH = find(strcmpi(feature_names_all, 'PETH'));
mat_this = similarity_matrix_all(:,:,idx_PETH);

idx_nan_units = find(any(isnan(PETH_features), 2));

idx_valid_PETH = find(all(~isnan(PETH_features), 1));
corr_new = corr(PETH_features(idx_nan_units, idx_valid_PETH)', PETH_features(:, idx_valid_PETH)');

corr_new(isnan(corr_new)) = 0;
corr_new = atanh(corr_new);
corr_new(corr_new > max_similarity) = max_similarity;

mat_this(idx_nan_units, :) = corr_new;
mat_this(:, idx_nan_units) = corr_new';

similarity_matrix_all(:,:,idx_PETH) = mat_this;
end