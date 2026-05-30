function [p, z] = pzmap(sys)
    % PZMAP Pole-zero map of an LTI system
    % [p, z] = pzmap(sys)
    [p, z] = unilab_pzmap(sys);
end
