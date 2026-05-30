function [p] = cheby_poly(n, x)
    % CHEBY_POLY Calculate the n-th degree Chebyshev polynomial of the first kind
    % T_n(x) = cos(n * acos(x))
    
    p = cos(n * acos(x));
end
