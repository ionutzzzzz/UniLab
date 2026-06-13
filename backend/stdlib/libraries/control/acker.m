function [K] = acker(A, B, p)
    % ACKER Pole placement for SISO systems using Ackermann's formula
    % K = acker(A, B, p)
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, p = []; end
    K = unilab_acker(A, B, p);
end
