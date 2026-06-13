function [p] = pole(sys)
    % POLE Calculate system poles
    if nargin < 1, sys = []; end
    p = unilab_pole(sys);
end
