function n = vector_norm_inf(v)
    % VECTOR_NORM_INF Linf norm
    if nargin < 1, v = []; end
    n = max(abs(v));
end
