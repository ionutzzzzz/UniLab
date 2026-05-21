function r = rand_chi_square_custom(k, n)
    if nargin < 2, n = 1; end
    r = rand_gamma_custom(k/2, 2, n);
end