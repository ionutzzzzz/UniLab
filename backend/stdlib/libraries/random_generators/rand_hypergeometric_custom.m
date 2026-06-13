function k = rand_hypergeometric_custom(K, N, n_draws, n_samples)
    if nargin < 1, K = []; end
    if nargin < 2, N = []; end
    if nargin < 3, n_draws = []; end
    if nargin < 4, n_samples = 1; end
    k = zeros(n_samples, 1);
    for s = 1:n_samples
        pop = [ones(1, K), zeros(1, N - K)];
        pop = pop(randperm(N));
        k(s) = sum(pop(1:n_draws));
    end
end