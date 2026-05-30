function [z, p, k] = ss2zp(A, B, C, D, iu)
    % SS2ZP State-space to zero-pole-gain conversion
    if nargin < 5, iu = 1; end
    [z, p, k] = unilab_ss2zp(A, B, C, D, iu - 1);
end
