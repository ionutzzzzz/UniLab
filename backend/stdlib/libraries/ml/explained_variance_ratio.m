function ratio = explained_variance_ratio(S)
    % EXPLAINED_VARIANCE_RATIO Ratio of variance explained by each principal component
    % S is the diagonal matrix of singular values from PCA
    variances = diag(S).^2;
    ratio = variances / sum(variances);
end
