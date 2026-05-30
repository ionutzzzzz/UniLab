function [y] = poly_val(p, x)
    % POLY_VAL Evaluate polynomial at x
    % p is a vector of coefficients [a_n, ..., a_1, a_0]
    
    n = length(p);
    y = zeros(size(x));
    for i = 1:n
        y = y + p(i) .* x.^(n-i);
    end
end
