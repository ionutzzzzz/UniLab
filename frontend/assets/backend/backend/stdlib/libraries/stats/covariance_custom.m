function cov = covariance_custom(x, y)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    n = length(x);
    mx = mean(x);
    my = mean(y);
    cov = sum((x - mx) .* (y - my)) / (n - 1);
end
