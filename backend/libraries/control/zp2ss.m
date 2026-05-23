function [A, B, C, D] = zp2ss(z, p, k)
    % ZP2SS Zero-pole-gain to state-space conversion
    [A, B, C, D] = unilab_zp2ss(z, p, k);
end
