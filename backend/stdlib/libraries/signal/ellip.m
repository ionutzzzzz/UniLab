function [b, a] = ellip(N, rp, rs, Wn, btype)
    if nargin < 5, btype = 'low'; end
    [b, a] = unilab_ellip(N, rp, rs, Wn, btype);
end