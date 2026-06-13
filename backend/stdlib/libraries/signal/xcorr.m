function [c, lags] = xcorr(a, v, mode)
    if nargin < 1, a = []; end
    if nargin < 2, v = a; end
    if nargin < 3, mode = 'full'; end
    [c, lags] = unilab_xcorr(a, v, mode);
end
