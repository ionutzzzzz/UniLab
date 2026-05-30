function pairs = goldbach_conjecture_check(n)
    % GOLDBACH_CONJECTURE_CHECK Find all pairs of primes that sum to even n
    if mod(n, 2) ~= 0 || n <= 2
        pairs = [];
        return;
    end
    
    primes = prime_sieve(n);
    pairs = [];
    for i = 1:length(primes)
        p1 = primes(i);
        if p1 > n/2, break; end
        p2 = n - p1;
        if is_prime(p2)
            pairs = [pairs; p1, p2];
        end
    end
end
