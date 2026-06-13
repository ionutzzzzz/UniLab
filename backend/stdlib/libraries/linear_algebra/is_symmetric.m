function b = is_symmetric(M)
    if nargin < 1, M = []; end
    b = all(all(M == M'));
end
