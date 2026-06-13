function p = momentum(m, v)
    if nargin < 1, m = []; end
    if nargin < 2, v = []; end
    p = m * v;
end
