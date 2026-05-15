function [g, x, y] = extended_gcd(a, b)
    % EXTENDED_GCD Extended Euclidean Algorithm
    % Returns [g, x, y] such that ax + by = g = gcd(a, b)
    
    if a == 0
        g = b; x = 0; y = 1;
        return;
    end
    
    [g1, x1, y1] = extended_gcd(mod(b, a), a);
    
    x = y1 - floor(b / a) * x1;
    y = x1;
    g = g1;
end
