function [y] = poly_val(p, x)
    % POLY_VAL Evaluate polynomial at x
    % p is a vector of coefficients [a_n, ..., a_1, a_0]
    
    if nargin < 1, p = []; end
    if nargin < 2, x = []; end
    n = length(p);
    y = zeros(size(x));
    for i = 1:n
        y = y + p(i) .* x.^(n-i);
    end
end
