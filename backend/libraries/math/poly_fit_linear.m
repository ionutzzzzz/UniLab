function [p] = poly_fit_linear(x, y)
    % POLY_FIT_LINEAR Simple linear least squares fit (y = ax + b)
    % Returns [a, b]
    
    n = length(x);
    sum_x = sum(x);
    sum_y = sum(y);
    sum_xx = sum(x.*x);
    sum_xy = sum(x.*y);
    
    a = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x^2);
    b = (sum_y - a * sum_x) / n;
    p = [a, b];
end
