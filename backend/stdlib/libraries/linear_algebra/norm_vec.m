function n = norm_vec(v, p)
    % NORM_VEC Vector p-norm
    if nargin < 1, v = []; end
    if nargin < 2, p = 2; end
    if p == inf
        n = max(abs(v));
    elseif p == -inf
        n = min(abs(v));
    else
        n = sum(abs(v).^p)^(1/p);
    end
end
