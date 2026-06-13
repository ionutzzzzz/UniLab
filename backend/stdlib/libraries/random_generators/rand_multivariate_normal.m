function R = rand_multivariate_normal(mu, sigma, n)
    if nargin < 1, mu = []; end
    if nargin < 2, sigma = []; end
    if nargin < 3, n = 1; end
    L = chol(sigma, 'lower');
    Z = randn(n, length(mu));
    R = bsxfun(@plus, Z * L', mu(:)');
end