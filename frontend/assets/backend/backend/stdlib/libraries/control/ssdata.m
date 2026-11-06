function [A, B, C, D] = ssdata(sys)
    if nargin < 1, sys = []; end
    [A, B, C, D] = unilab_ssdata(sys);
end