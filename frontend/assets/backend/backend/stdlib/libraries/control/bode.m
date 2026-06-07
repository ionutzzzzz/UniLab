function [mag, phase, w] = bode(sys, w)
    if nargin < 2, w = []; end
    [w, mag, phase] = unilab_bode(sys, w);
end