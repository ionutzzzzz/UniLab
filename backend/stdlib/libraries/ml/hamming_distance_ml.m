function d = hamming_distance_ml(u, v)
    % HAMMING_DISTANCE_ML Number of positions at which symbols are different
    if nargin < 1, u = []; end
    if nargin < 2, v = []; end
    d = sum(u ~= v);
end
