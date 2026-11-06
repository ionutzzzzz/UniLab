function [b, a] = butter(N, Wn, btype)
    if nargin < 1, N = []; end
    if nargin < 2, Wn = []; end
    if nargin < 3, btype = 'low'; end
    [b, a] = unilab_butter(N, Wn, btype);
end