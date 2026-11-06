function [r, k] = rlocus(sys)
    if nargin < 1, sys = []; end
    [r, k] = unilab_rlocus(sys);
end