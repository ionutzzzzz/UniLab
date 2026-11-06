function [A, B, C, D] = zp2ss(z, p, k)
    % ZP2SS Zero-pole-gain to state-space conversion
    if nargin < 1, z = []; end
    if nargin < 2, p = []; end
    if nargin < 3, k = []; end
    [A, B, C, D] = unilab_zp2ss(z, p, k);
end
