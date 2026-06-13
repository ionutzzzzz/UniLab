function [re, im, w] = nyquist(sys, w)
    % NYQUIST Nyquist frequency response plot
    % [re, im, w] = nyquist(sys, w)
    if nargin < 1, sys = []; end
    if nargin < 2, w = []; end
    [w_out, h] = unilab_nyquist(sys, w);
    re = real(h);
    im = imag(h);
    w = w_out;
end
