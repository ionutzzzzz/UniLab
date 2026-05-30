function [p] = legendre_poly(n, x)
    % LEGENDRE_POLY Calculate the n-th degree Legendre polynomial at x
    % Uses the Bonnet's recursion formula
    
    if n == 0
        p = ones(size(x));
        return;
    end
    if n == 1
        p = x;
        return;
    end
    
    p0 = ones(size(x));
    p1 = x;
    
    for i = 2:n
        p2 = ((2*i - 1) .* x .* p1 - (i - 1) .* p0) ./ i;
        p0 = p1;
        p1 = p2;
    end
    p = p1;
end
