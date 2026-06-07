function X_scaled = min_max_scaler_predict(X, min_val, max_val)
    % MIN_MAX_SCALER_PREDICT Apply learned min-max scaling
    range_val = max_val - min_val;
    range_val(range_val == 0) = 1;
    X_scaled = (X - min_val) ./ range_val;
end
