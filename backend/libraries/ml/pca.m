function [U, S] = pca(X)
    % PCA Principal Component Analysis
    % [U, S] = pca(X)
    
    [m, n] = size(X);
    
    % Normalize X
    mu = mean(X, 1);
    X_norm = X - mu;
    
    % Covariance matrix
    sigma = (X_norm' * X_norm) ./ m;
    
    % SVD
    [U, S, V] = svd(sigma);
end
