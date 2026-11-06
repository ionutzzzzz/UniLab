function n = vector_norm_1(v)
    % VECTOR_NORM_1 L1 norm
    if nargin < 1, v = []; end
    n = sum(abs(v));
end
