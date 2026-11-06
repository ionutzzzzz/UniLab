function [P] = care(A, B, Q, R)
    % CARE Continuous-time Algebraic Riccati Equation solver
    % P = care(A, B, Q, R) solves A'P + PA - PBR^-1B'P + Q = 0
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, Q = []; end
    if nargin < 4, R = []; end
    P = unilab_care(A, B, Q, R);
end
