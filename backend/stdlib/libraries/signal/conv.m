function [c] = conv(a, v, mode)
    if nargin < 1, a = []; end
    if nargin < 2, v = []; end
    if nargin < 3, mode = 'full'; end
    c = unilab_conv(a, v, mode);
end