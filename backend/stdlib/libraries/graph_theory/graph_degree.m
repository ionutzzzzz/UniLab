function d = graph_degree(A)
    if nargin < 1, A = []; end
    d = sum(A ~= 0, 2);
end