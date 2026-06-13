function [z] = zero(sys)
    % ZERO Calculate system zeros
    if nargin < 1, sys = []; end
    z = unilab_zero(sys);
end
