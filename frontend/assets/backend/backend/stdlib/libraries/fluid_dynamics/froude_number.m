function Fr = froude_number(v, g, L)
    if nargin < 1, v = []; end
    if nargin < 2, g = []; end
    if nargin < 3, L = []; end
    Fr = v / sqrt(g * L);
end
