function d = euclidean_distance(u, v)
    if nargin < 1, u = []; end
    if nargin < 2, v = []; end
    d = vector_norm_2(u - v);
end
