function [g] = dcgain(sys)
    % DCGAIN Calculate steady-state (DC) gain of a system
    if nargin < 1, sys = []; end
    g = unilab_dcgain(sys);
end
