function [P] = dare(A, B, Q, R)
    % DARE Discrete-time Algebraic Riccati Equation solver
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, Q = []; end
    if nargin < 4, R = []; end
    P = unilab_dare(A, B, Q, R);
end
