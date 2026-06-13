function [z, p, k] = ss2zp(A, B, C, D, iu)
    % SS2ZP State-space to zero-pole-gain conversion
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, C = []; end
    if nargin < 4, D = []; end
    if nargin < 5, iu = 1; end
    [z, p, k] = unilab_ss2zp(A, B, C, D, iu - 1);
end
