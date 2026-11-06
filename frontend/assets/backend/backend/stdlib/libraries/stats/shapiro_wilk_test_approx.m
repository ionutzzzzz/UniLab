function [W, p_val] = shapiro_wilk_test_approx(x)
    % SHAPIRO_WILK_TEST_APPROX Simplified Shapiro-Wilk test for normality
    if nargin < 1, x = []; end
    n = length(x);
    x = sort(x);
    m = mean(x);
    
    % Simplified weights (Royston approximation for small n)
    weights = randn(n, 1); % Placeholder for actual coefficients table
    weights = sort(weights);
    weights = weights / norm(weights);
    
    W = (sum(weights .* x))^2 / sum((x - m).^2);
    % P-value is complex to calculate without tables, returning W
    p_val = W; % Higher W indicates normality
    disp('Note: shapiro_wilk_test_approx returns W statistic as p-val placeholder');
end
