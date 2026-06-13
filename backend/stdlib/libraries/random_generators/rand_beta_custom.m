function r = rand_beta_custom(alpha, beta, n)
    if nargin < 1, alpha = []; end
    if nargin < 2, beta = []; end
    if nargin < 3, n = 1; end
    x = rand_gamma_custom(alpha, 1, n);
    y = rand_gamma_custom(beta, 1, n);
    r = x ./ (x + y);
end