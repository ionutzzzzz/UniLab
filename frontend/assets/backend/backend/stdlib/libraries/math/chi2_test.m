function [chi2, p_val] = chi2_test(observed, expected)
    % CHI2_TEST Chi-square test for goodness of fit
    
    if nargin < 1, observed = []; end
    if nargin < 2, expected = []; end
    chi2 = sum((observed - expected).^2 ./ expected);
    
    % Degrees of freedom
    df = length(observed) - 1;
    % P-value approximation (simplified)
    p_val = 1 - erf_approx(sqrt(chi2 / 2));
end
