function r = rand_beta_custom(alpha, beta, n)
    if nargin < 3, n = 1; end
    x = rand_gamma_custom(alpha, 1, n);
    y = rand_gamma_custom(beta, 1, n);
    r = x ./ (x + y);
end