function c = closeness_centrality(A)
    % CLOSENESS_CENTRALITY C(u) = (n-1) / sum(dist(u, v))
    if nargin < 1, A = []; end
    n = size(A, 1);
    D = floyd_warshall(A);
    c = zeros(n, 1);
    for i = 1:n
        sum_dist = sum(D(i, D(i, :) < inf));
        if sum_dist > 0
            c(i) = (n - 1) / sum_dist;
        end
    end
end
