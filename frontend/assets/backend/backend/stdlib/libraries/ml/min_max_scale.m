function [X_scaled, min_val, max_val] = min_max_scale(X)
    % MIN_MAX_SCALE Scale features to [0, 1] range
    
    min_val = min(X, 1);
    max_val = max(X, 1);
    range_val = max_val - min_val;
    
    % Avoid division by zero
    range_val(range_val == 0) = 1;
    
    X_scaled = (X - min_val) ./ range_val;
end
