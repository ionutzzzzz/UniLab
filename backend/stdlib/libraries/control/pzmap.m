function [p, z] = pzmap(sys)
    % PZMAP Pole-zero map of an LTI system
    % [p, z] = pzmap(sys)
    if nargin < 1, sys = []; end
    [p, z] = unilab_pzmap(sys);
end
