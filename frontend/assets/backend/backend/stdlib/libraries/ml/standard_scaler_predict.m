function X_std = standard_scaler_predict(X, mu, sigma)
    % STANDARD_SCALER_PREDICT Apply learned standardization
    X_std = (X - mu) ./ sigma;
end
