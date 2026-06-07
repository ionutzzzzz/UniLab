function [means, ci_low, ci_high] = bootstrap_mean(data, n_iterations)
    % Performs bootstrapping to estimate the distribution of the mean
    if nargin < 2, n_iterations = 1000; end
    
    n = length(data);
    means = zeros(1, n_iterations);
    
    for i = 1:n_iterations
        % Resample with replacement
        idx = randi(n, 1, n);
        sample = data(idx);
        means(i) = mean(sample);
    end
    
    % Compute 95% confidence interval
    means_sorted = sort(means);
    ci_low = means_sorted(floor(0.025 * n_iterations) + 1);
    ci_high = means_sorted(floor(0.975 * n_iterations) + 1);
end
