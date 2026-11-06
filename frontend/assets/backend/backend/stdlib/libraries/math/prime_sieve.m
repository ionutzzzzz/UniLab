function [primes] = prime_sieve(n)
    % PRIME_SIEVE Sieve of Eratosthenes to find all primes up to n
    
    if nargin < 1, n = []; end
    if n < 2
        primes = [];
        return;
    end
    
    is_prime_arr = ones(1, n);
    is_prime_arr(1) = 0;
    
    for p = 2:floor(sqrt(n))
        if is_prime_arr(p) == 1
            for i = p*p:p:n
                is_prime_arr(i) = 0;
            end
        end
    end
    
    primes = find(is_prime_arr == 1);
end
