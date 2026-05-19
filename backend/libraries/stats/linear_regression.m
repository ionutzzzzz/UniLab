function [slope, intercept, r2] = linear_regression(x, y)
    % Performs simple linear regression
    % [slope, intercept, r2] = linear_regression(x, y)

    x = x(:);
    y = y(:);
    n = length(x);
    x_mean = mean(x);
    y_mean = mean(y);
    
    num = sum((x - x_mean) .* (y - y_mean));
    den = sum((x - x_mean) .^ 2);
    
    slope = num / den;
    intercept = y_mean - slope * x_mean;
    
    y_pred = (slope * x + intercept);
    ss_res = sum((y - y_pred) .^ 2);
    ss_tot = sum((y - y_mean) .^ 2);
    r2 = (1 - (ss_res / ss_tot));
end
