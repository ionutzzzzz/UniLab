function [p] = hermite_poly(n, x)
    % HERMITE_POLY Calculate the n-th degree physicist's Hermite polynomial
    % H_n(x) uses recursion
    
    if nargin < 1, n = []; end
    if nargin < 2, x = []; end
    if n == 0
        p = ones(size(x));
        return;
    end
    if n == 1
        p = 2 .* x;
        return;
    end
    
    h0 = ones(size(x));
    h1 = 2 .* x;
    for i = 2:n
        h2 = 2 .* x .* h1 - 2 * (i - 1) .* h0;
        h0 = h1;
        h1 = h2;
    end
    p = h1;
end
