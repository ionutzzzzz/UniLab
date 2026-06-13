function [dist, path] = dijkstra(A, start_node)
    if nargin < 1, A = []; end
    if nargin < 2, start_node = []; end
    n = size(A, 1);
    dist = inf(1, n);
    visited = false(1, n);
    prev = zeros(1, n);
    dist(start_node) = 0;
    for i = 1:n
        [~, u] = min(dist + visited * 1e9);
        visited(u) = true;
        neighbors = find(A(u, :));
        for j = 1:length(neighbors)
            v = neighbors(j);
            alt = dist(u) + A(u, v);
            if alt < dist(v)
                dist(v) = alt;
                prev(v) = u;
            end
        end
    end
    path = prev;
end