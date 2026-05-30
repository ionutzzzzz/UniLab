function [G, is_outlier] = grubbs_test_outlier(x, alpha)
    % GRUBBS_TEST_OUTLIER Detect a single outlier in a univariate dataset
    if nargin < 2, alpha = 0.05; end
    n = length(x);
    m = mean(x);
    s = std(x);
    
    [max_diff, idx] = max(abs(x - m));
    G = max_diff / s;
    
    % Critical value approximation (simplified)
    t_crit = 2.0; % Placeholder for t-distribution based critical value
    G_crit = ((n - 1) / sqrt(n)) * sqrt(t_crit^2 / (n - 2 + t_crit^2));
    
    is_outlier = G > G_crit;
end
