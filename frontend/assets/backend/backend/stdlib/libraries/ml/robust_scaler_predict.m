function X_scaled = robust_scaler_predict(X, med, iqr_val)
    % ROBUST_SCALER_PREDICT Apply learned robust scaling
    if nargin < 1, X = []; end
    if nargin < 2, med = []; end
    if nargin < 3, iqr_val = []; end
    X_scaled = (X - med) ./ iqr_val;
end
