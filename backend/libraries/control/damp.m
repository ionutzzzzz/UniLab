function [wn, zeta, p] = damp(sys)
    % DAMP Natural frequency and damping ratio for system poles
    % [wn, zeta, p] = damp(sys)
    [wn, zeta, p] = unilab_damp(sys);
end
