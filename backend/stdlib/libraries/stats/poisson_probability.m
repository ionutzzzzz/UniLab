function p = poisson_probability(lambda, k)
    p = (lambda^k * exp(-lambda)) / factorial_custom(k);
end
