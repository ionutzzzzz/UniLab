function [A, B, C, D] = tf2ss(num, den)
    if nargin < 1, num = []; end
    if nargin < 2, den = []; end
    [A, B, C, D] = unilab_tf2ss(num, den);
end