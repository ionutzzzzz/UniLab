function [p] = npermutek_custom(n, k)
    if nargin < 1, n = []; end
    if nargin < 2, k = []; end
    p = factorial_custom(n) / factorial_custom(n - k);
end
