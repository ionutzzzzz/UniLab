function [X_poly] = polynomial_features(X, degree)
    % POLYNOMIAL_FEATURES Generate polynomial and interaction features
    % [X_poly] = polynomial_features(X, degree)
    
    [m, n] = size(X);
    X_poly = X;
    
    for d = 2:degree
        X_poly = [X_poly, X.^d];
    end
end
