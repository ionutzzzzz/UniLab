function n = vector_norm_1(v)
    if nargin < 1, v = []; end
    n = sum(abs(v));
end
