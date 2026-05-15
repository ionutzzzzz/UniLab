function [means] = bootstrap_mean(data, n_iterations)
    % Performs bootstrapping to estimate the distribution of the mean
    n = length(data);
    means = zeros(1, n_iterations);
    
    for i = 1:n_iterations
        % Resample with replacement
        indices = randi(n, 1, n);
        sample = data(indices);
        means(i) = mean(sample);
    end
end
