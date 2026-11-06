function [y] = filtfilt(b, a, x)
    if nargin < 1, b = []; end
    if nargin < 2, a = []; end
    if nargin < 3, x = []; end
    y = unilab_filtfilt(b, a, x);
end