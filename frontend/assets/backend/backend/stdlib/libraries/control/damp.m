function [wn, zeta, p] = damp(sys)
    % DAMP Natural frequency and damping ratio for system poles
    % [wn, zeta, p] = damp(sys)
    if nargin < 1, sys = []; end
    [wn, zeta, p] = unilab_damp(sys);
end
