function [centroids, idx] = kmeans(X, K, max_iters)
    % KMEANS K-means clustering algorithm
    % [centroids, idx] = kmeans(X, K, max_iters)
    
    [m, n] = size(X);
    
    % Initialize centroids randomly from X
    rand_idx = randperm(m);
    centroids = X(rand_idx(1:K), :);
    
    idx = zeros(m, 1);
    
    for iter = 1:max_iters
        % Assignment step
        for i = 1:m
            distances = sum((X(i, :) - centroids).^2, 2);
            min_idx = argmin(distances);
            idx(i) = min_idx;
        end
        
        % Update step
        for k = 1:K
            centroids(k, :) = mean(X(idx == k, :), 1);
        end
    end
end
