function n = vector_norm_2(v)
    % VECTOR_NORM_2 L2 norm
    if nargin < 1, v = []; end
    n = sqrt(sum(v.^2));
end
