function d = graph_density(A, directed)
    if nargin < 1, A = []; end
    if nargin < 2, directed = false; end
    n = size(A, 1);
    E = sum(sum(A ~= 0));
    if directed, d = E / (n * (n - 1)); else, d = E / (n * (n - 1) / 2); end
end