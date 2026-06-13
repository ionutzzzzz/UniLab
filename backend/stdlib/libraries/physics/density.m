function d = density(m, V)
    if nargin < 1, m = []; end
    if nargin < 2, V = []; end
    d = m / V;
end
