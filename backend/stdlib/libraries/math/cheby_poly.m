function [p] = cheby_poly(n, x)
    % CHEBY_POLY Calculate the n-th degree Chebyshev polynomial of the first kind
    % T_n(x) = cos(n * acos(x))
    
    if nargin < 1, n = []; end
    if nargin < 2, x = []; end
    p = cos(n * acos(x));
end
