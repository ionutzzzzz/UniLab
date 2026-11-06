function s = silhouette_score_approx(X, labels)
    % SILHOUETTE_SCORE_APPROX Mean silhouette coefficient
    if nargin < 1, X = []; end
    if nargin < 2, labels = []; end
    m = size(X, 1);
    unique_labels = unique(labels);
    K = length(unique_labels);
    if K <= 1, s = 0; return; end
    
    scores = zeros(m, 1);
    for i = 1:m
        % Intra-cluster distance
        a_i = mean(sqrt(sum((X(labels == labels(i), :) - X(i, :)).^2, 2)));
        % Inter-cluster distance
        b_i = inf;
        for k = 1:K
            if unique_labels(k) == labels(i), continue; end
            dist = mean(sqrt(sum((X(labels == unique_labels(k), :) - X(i, :)).^2, 2)));
            b_i = min(b_i, dist);
        end
        scores(i) = (b_i - a_i) / max(a_i, b_i);
    end
    s = mean(scores);
end
