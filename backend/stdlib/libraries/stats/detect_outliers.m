function [outliers] = detect_outliers(data, k)
    % Detects outliers using k * IQR method
    if nargin < 2, k = 1.5; end
    
    q1 = quantile(data, 0.25);
    q3 = quantile(data, 0.75);
    iqr_val = q3 - q1;
    
    lower = q1 - k * iqr_val;
    upper = q3 + k * iqr_val;
    
    outliers = (data < lower) | (data > upper);
end
