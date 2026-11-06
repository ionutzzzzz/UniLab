function [factors] = prime_factors(n)
    % PRIME_FACTORS Find prime factors of n
    
    if nargin < 1, n = []; end
    factors = [];
    d = 2;
    temp = n;
    while d * d <= temp
        while mod(temp, d) == 0
            factors = [factors, d];
            temp = temp / d;
        end
        d = d + 1;
    end
    if temp > 1
        factors = [factors, temp];
    end
end
