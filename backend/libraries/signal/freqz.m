function [h, w] = freqz(b, a, worN)
    if nargin < 3, worN = 512; end
    [w, h] = unilab_freqfreqz(b, a, worN);
end