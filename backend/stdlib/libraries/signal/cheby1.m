function [b, a] = cheby1(N, rp, Wn, btype)
    if nargin < 4, btype = 'low'; end
    [b, a] = unilab_cheby1(N, rp, Wn, btype);
end