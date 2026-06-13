function y = nchoosek_custom(n, k)
    if nargin < 1, n = []; end
    if nargin < 2, k = []; end
    y = factorial(n) / (factorial(k) * factorial(n-k));
end
