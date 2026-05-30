function k = rand_binomial_custom(n_trials, p, n_samples)
    if nargin < 3, n_samples = 1; end
    k = sum(rand(n_samples, n_trials) < p, 2);
end