function sim = cosine_similarity(u, v)
    if nargin < 1, u = []; end
    if nargin < 2, v = []; end
    sim = dot_product(u, v) / (vector_norm_2(u) * vector_norm_2(v));
end
