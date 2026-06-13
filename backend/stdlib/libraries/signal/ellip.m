function [b, a] = ellip(N, rp, rs, Wn, btype)
    if nargin < 1, N = []; end
    if nargin < 2, rp = []; end
    if nargin < 3, rs = []; end
    if nargin < 4, Wn = []; end
    if nargin < 5, btype = 'low'; end
    [b, a] = unilab_ellip(N, rp, rs, Wn, btype);
end