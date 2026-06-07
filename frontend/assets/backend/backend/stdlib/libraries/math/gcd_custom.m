function [g] = gcd_custom(a, b)
    % GCD_CUSTOM Greatest Common Divisor
    
    while b ~= 0
        temp = b;
        b = mod(a, b);
        a = temp;
    end
    g = a;
end
