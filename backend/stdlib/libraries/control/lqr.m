function [K, P, E] = lqr(A, B, Q, R)
    % LQR Linear-Quadratic Regulator design
    % [K, P, E] = lqr(A, B, Q, R)
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, Q = []; end
    if nargin < 4, R = []; end
    if nargin == 1 % lqr(sys, Q, R)
        error('lqr(sys, Q, R) not yet implemented, use lqr(A, B, Q, R)');
    end
    [K, P, E] = unilab_lqr(A, B, Q, R);
end
