function [scaled] = robust_scaler(data)
    % Scales data using median and interquartile range (IQR)
    % Robust to outliers

    data = data(:);
    med = median(data);
    q1 = quantile(data, 0.25);
    q3 = quantile(data, 0.75);
    iqr_val = q3 - q1;
    
    scaled = (data - med) / iqr_val;
end
