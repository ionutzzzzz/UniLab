function [sys] = zpk(z, p, k)
    if nargin < 1, z = []; end
    if nargin < 2, p = []; end
    if nargin < 3, k = []; end
    sys = unilab_zpk(z, p, k);
end