function D = floyd_warshall(A)
    % FLOYD_WARSHALL All-pairs shortest paths
    n = size(A, 1);
    D = A;
    D(D == 0) = inf;
    for i = 1:n, D(i, i) = 0; end
    
    for k = 1:n
        for i = 1:n
            for j = 1:n
                if D(i, k) + D(k, j) < D(i, j)
                    D(i, j) = D(i, k) + D(k, j);
                end
            end
        end
    end
end
