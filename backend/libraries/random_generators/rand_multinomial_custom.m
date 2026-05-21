function counts = rand_multinomial_custom(n_trials, p)
    k = length(p);
    counts = zeros(1, k);
    for i = 1:n_trials
        r = rand();
        cum_p = cumsum(p);
        idx = find(cum_p >= r, 1);
        counts(idx) = counts(idx) + 1;
    end
end