function [sys] = tf(num, den)
    if nargin < 1, num = []; end
    if nargin < 2, den = []; end
    sys = unilab_tf(num, den);
end