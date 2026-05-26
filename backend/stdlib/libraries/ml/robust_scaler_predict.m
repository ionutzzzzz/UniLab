function X_scaled = robust_scaler_predict(X, med, iqr_val)
    % ROBUST_SCALER_PREDICT Apply learned robust scaling
    X_scaled = (X - med) ./ iqr_val;
end
