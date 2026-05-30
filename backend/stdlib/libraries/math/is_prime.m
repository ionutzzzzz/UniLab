function [p] = is_prime(n)
    % IS_PRIME Check if a number is prime
    
    if n <= 1
        p = 0;
        return;
    end
    if n <= 3
        p = 1;
        return;
    end
    if mod(n, 2) == 0 || mod(n, 3) == 0
        p = 0;
        return;
    end
    
    i = 5;
    while i * i <= n
        if mod(n, i) == 0 || mod(n, i + 2) == 0
            p = 0;
            return;
        end
        i = i + 6;
    end
    p = 1;
end
