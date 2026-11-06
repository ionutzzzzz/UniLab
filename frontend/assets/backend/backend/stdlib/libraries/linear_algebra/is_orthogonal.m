function b = is_orthogonal(M)
    if nargin < 1, M = []; end
    I = eye(size(M, 1));
    b = max(max(abs(M * M' - I))) < 1e-10;
end
