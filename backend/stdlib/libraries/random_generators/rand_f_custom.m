function r = rand_f_custom(d1, d2, n)
    if nargin < 1, d1 = []; end
    if nargin < 2, d2 = []; end
    if nargin < 3, n = 1; end
    X1 = rand_chi_square_custom(d1, n);
    X2 = rand_chi_square_custom(d2, n);
    r = (X1 / d1) ./ (X2 / d2);
end