function [g] = gcd_custom(a, b)
    % GCD_CUSTOM Greatest Common Divisor
    
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    while b ~= 0
        temp = b;
        b = mod(a, b);
        a = temp;
    end
    g = a;
end
