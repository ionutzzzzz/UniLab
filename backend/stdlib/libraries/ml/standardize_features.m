function [X_std, mu, sigma] = standardize_features(X)
    % STANDARDIZE_FEATURES Scales features to have zero mean and unit variance
    
    mu = mean(X, 1);
    sigma = std(X, 1);
    
    % Avoid division by zero
    sigma(sigma == 0) = 1;
    
    X_std = (X - mu) ./ sigma;
end
