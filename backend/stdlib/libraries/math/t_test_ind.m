function [t_stat, p_val] = t_test_ind(x1, x2)
    % T_TEST_IND Independent two-sample t-test
    
    n1 = length(x1);
    n2 = length(x2);
    m1 = mean(x1);
    m2 = mean(x2);
    v1 = var(x1);
    v2 = var(x2);
    
    % Pooled standard deviation
    sp = sqrt(((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2));
    
    t_stat = (m1 - m2) / (sp * sqrt(1/n1 + 1/n2));
    
    % Degrees of freedom
    df = n1 + n2 - 2;
    % P-value approximation using erf (simplified)
    p_val = 1 - erf_approx(abs(t_stat) / sqrt(2));
end
