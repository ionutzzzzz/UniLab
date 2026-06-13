function [X] = lyap(A, Q)
    % LYAP Solve continuous-time Lyapunov equations
    % X = lyap(A, Q) solves AX + XA' + Q = 0
    if nargin < 1, A = []; end
    if nargin < 2, Q = []; end
    X = unilab_lyap(A, Q);
end
