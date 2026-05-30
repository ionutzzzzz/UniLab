function count = prime_counting_function(n)
    % PRIME_COUNTING_FUNCTION Number of primes less than or equal to n
    % count = prime_counting_function(n)
    
    if n < 2
        count = 0;
        return;
    end
    
    primes = prime_sieve(n);
    count = length(primes);
end
