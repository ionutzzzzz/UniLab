function counts = rand_multinomial_custom(n_trials, p)
    if nargin < 1, n_trials = []; end
    if nargin < 2, p = []; end
    k = length(p);
    counts = zeros(1, k);
    for i = 1:n_trials
        r = rand();
        cum_p = cumsum(p);
        idx = find(cum_p >= r, 1);
        counts(idx) = counts(idx) + 1;
    end
end