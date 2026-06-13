function [labels] = agglomerative_clustering(X, n_clusters)
    % AGGLOMERATIVE_CLUSTERING Bottom-up hierarchical clustering
    
    if nargin < 1, X = []; end
    if nargin < 2, n_clusters = 2; end
    
    m = size(X, 1);
    clusters = cell(m, 1);
    for i = 1:m
        clusters{i} = i;
    end
    
    while length(clusters) > n_clusters
        min_dist = 1e9;
        pair = [1, 2];
        
        for i = 1:length(clusters)
            for j = (i+1):length(clusters)
                % Single linkage (min dist between points)
                d = compute_min_dist(X(clusters{i}, :), X(clusters{j}, :));
                if d < min_dist
                    min_dist = d;
                    pair = [i, j];
                end
            end
        end
        
        % Merge
        new_cluster = [clusters{pair(1)}, clusters{pair(2)}];
        idx_to_remove = sort(pair, 'descend');
        clusters(idx_to_remove(1)) = [];
        clusters(idx_to_remove(2)) = [];
        clusters{end+1} = new_cluster;
    end
    
    labels = zeros(m, 1);
    for i = 1:length(clusters)
        labels(clusters{i}) = i;
    end
end

function [d] = compute_min_dist(C1, C2)
    if nargin < 1, C1 = []; end
    if nargin < 2, C2 = []; end
    m1 = size(C1, 1);
    m2 = size(C2, 1);
    d = 1e9;
    for i = 1:m1
        for j = 1:m2
            dist = norm(C1(i, :) - C2(j, :));
            if dist < d
                d = dist;
            end
        end
    end
end
