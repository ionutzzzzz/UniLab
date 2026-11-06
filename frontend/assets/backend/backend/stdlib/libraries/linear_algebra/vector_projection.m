function p = vector_projection(u, v)
    % VECTOR_PROJECTION Projection of vector u onto vector v
    if nargin < 1, u = []; end
    if nargin < 2, v = []; end
    p = (dot_product(u, v) / dot_product(v, v)) * v;
end
