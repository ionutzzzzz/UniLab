function p = normcdf(x, mu, sigma)
    % NORMCDF Normal cumulative distribution function
    if nargin < 1, x = []; end
    if nargin < 2, mu = 0; end
    if nargin < 3, sigma = 1; end
    
    p = 0.5 * (1 + erf_approx((x - mu) / (sigma * sqrt(2))));
end
