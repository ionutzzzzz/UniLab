function [b, a] = cheby2(N, rs, Wn, btype)
    if nargin < 4, btype = 'low'; end
    [b, a] = unilab_cheby2(N, rs, Wn, btype);
end