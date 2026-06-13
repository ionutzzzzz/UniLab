function [mag, phase, w] = nichols(sys, w)
    % NICHOLS Nichols frequency response plot
    if nargin < 1, sys = []; end
    if nargin < 2, w = []; end
    [w_out, h] = unilab_nichols(sys, w);
    mag = 20 * log10(abs(h));
    phase = rad2deg(angle(h));
    w = w_out;
end
