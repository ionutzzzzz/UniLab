function d = graph_degree(A)
    d = sum(A ~= 0, 2);
end