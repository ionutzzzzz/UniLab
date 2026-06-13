function [h, w] = freqz(b, a, worN)
    if nargin < 1, b = []; end
    if nargin < 2, a = []; end
    if nargin < 3, worN = 512; end
    [w, h] = unilab_freqfreqz(b, a, worN);
end