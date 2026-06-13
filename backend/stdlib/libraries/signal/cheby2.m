function [b, a] = cheby2(N, rs, Wn, btype)
    if nargin < 1, N = []; end
    if nargin < 2, rs = []; end
    if nargin < 3, Wn = []; end
    if nargin < 4, btype = 'low'; end
    [b, a] = unilab_cheby2(N, rs, Wn, btype);
end