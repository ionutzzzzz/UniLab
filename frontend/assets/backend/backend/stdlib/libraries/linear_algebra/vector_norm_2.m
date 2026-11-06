function n = vector_norm_2(v)
    if nargin < 1, v = []; end
    n = sqrt(sum(v.^2));
end
