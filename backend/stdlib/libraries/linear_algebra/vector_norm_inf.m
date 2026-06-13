function n = vector_norm_inf(v)
    if nargin < 1, v = []; end
    n = max(abs(v));
end
