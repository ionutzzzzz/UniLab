function [c] = xcorr(a, v, mode)
    if nargin < 2, v = a; end
    if nargin < 3, mode = 'full'; end
    c = unilab_xcorr(a, v, mode);
end