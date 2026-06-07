function [b, a] = butter(N, Wn, btype)
    if nargin < 3, btype = 'low'; end
    [b, a] = unilab_butter(N, Wn, btype);
end