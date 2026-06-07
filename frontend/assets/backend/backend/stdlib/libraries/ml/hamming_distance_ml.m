function d = hamming_distance_ml(u, v)
    % HAMMING_DISTANCE_ML Number of positions at which symbols are different
    d = sum(u ~= v);
end
