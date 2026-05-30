function p = vector_projection(u, v)
    % VECTOR_PROJECTION Projection of vector u onto vector v
    p = (dot_product(u, v) / dot_product(v, v)) * v;
end
