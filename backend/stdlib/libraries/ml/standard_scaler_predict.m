function X_std = standard_scaler_predict(X, mu, sigma)
    % STANDARD_SCALER_PREDICT Apply learned standardization
    if nargin < 1, X = []; end
    if nargin < 2, mu = []; end
    if nargin < 3, sigma = []; end
    X_std = (X - mu) ./ sigma;
end
