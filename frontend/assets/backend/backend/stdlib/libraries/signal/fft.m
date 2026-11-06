function [Y] = fft(x)
    if nargin < 1, x = []; end
    Y = unilab_fft(x);
end