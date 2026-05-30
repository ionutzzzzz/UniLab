function [g] = dcgain(sys)
    % DCGAIN Calculate steady-state (DC) gain of a system
    g = unilab_dcgain(sys);
end
