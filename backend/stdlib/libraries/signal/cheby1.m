function [b, a] = cheby1(N, rp, Wn, btype)
    if nargin < 1, N = []; end
    if nargin < 2, rp = []; end
    if nargin < 3, Wn = []; end
    if nargin < 4, btype = 'low'; end
    [b, a] = unilab_cheby1(N, rp, Wn, btype);
end