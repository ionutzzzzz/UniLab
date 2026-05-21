function sim = cosine_similarity(u, v)
    sim = dot_product(u, v) / (vector_norm_2(u) * vector_norm_2(v));
end
