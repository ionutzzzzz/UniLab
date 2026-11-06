function d = graph_diameter(A)
    % GRAPH_DIAMETER Maximum shortest path in the graph
    if nargin < 1, A = []; end
    D = floyd_warshall(A);
    D(D == inf) = 0;
    d = max(max(D));
end
