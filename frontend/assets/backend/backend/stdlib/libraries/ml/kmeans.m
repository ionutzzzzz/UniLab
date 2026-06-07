function [centroids, idx] = kmeans(X, K, max_iters, init_method)
    % KMEANS K-means clustering algorithm
    % [centroids, idx] = kmeans(X, K, max_iters, init_method)
    
    if nargin < 4, init_method = 'random'; end
    if nargin < 3, max_iters = 100; end
    
    [m, n] = size(X);
    
    if strcmp(init_method, 'random')
        % Initialize centroids randomly from X
        rand_idx = randperm(m);
        centroids = X(rand_idx(1:K), :);
    else
        % kmeans++ initialization
        centroids = zeros(K, n);
        centroids(1, :) = X(randi(m), :);
        for k = 2:K
            distances = zeros(m, 1);
            for i = 1:m
                d2 = sum((X(i, :) - centroids(1:k-1, :)).^2, 2);
                distances(i) = min(d2);
            end
            % Choose next centroid with probability proportional to d^2
            probs = distances / sum(distances);
            cum_probs = cumsum(probs);
            r = rand();
            idx_next = find(cum_probs >= r);
            centroids(k, :) = X(idx_next(1), :);
        end
    end
    
    idx = zeros(m, 1);
    
    for iter = 1:max_iters
        % Assignment step
        for i = 1:m
            distances = sum((X(i, :) - centroids).^2, 2);
            min_idx = argmin(distances);
            idx(i) = min_idx;
        end
        
        % Update step
        centroids_new = zeros(K, n);
        for k = 1:K
            X_k = X(idx == k, :);
            if isempty(X_k) == 0
                centroids_new(k, :) = mean(X_k, 1);
            else
                % Re-initialize empty cluster
                centroids_new(k, :) = X(randi(m), :);
            end
        end
        
        if norm(centroids_new - centroids) < 1e-6
            centroids = centroids_new;
            break;
        end
        centroids = centroids_new;
    end
end
