function p = nprime(n)
% Compute the nth prime using the general algorithm.
%
%   p = function p = nprime(n)

    validateattributes(n, {'numeric'}, ...
        {'scalar','integer','positive','finite'});

    N = 2^n;

    % Generate the first N primes
    primesList = zeros(1, N);
    k = 0;
    candidate = 2;

    while k < N
        if isprime(candidate)
            k = k + 1;
            primesList(k) = candidate;
        end
        candidate = candidate + 1;
    end

    % Evaluate the formula
    p = 1;
    for m = 1:N
        innerSum = sum(floor((primesList ./ m).^(1/n)));

        if innerSum > 0
            p = p + floor(n / innerSum);
        end
    end
end