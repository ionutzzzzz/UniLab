function p = poisson_probability(lambda, k)
    if nargin < 1, lambda = []; end
    if nargin < 2, k = []; end
    p = (lambda^k * exp(-lambda)) / factorial_custom(k);
end
