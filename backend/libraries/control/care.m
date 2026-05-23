function [P] = care(A, B, Q, R)
    % CARE Continuous-time Algebraic Riccati Equation solver
    % P = care(A, B, Q, R) solves A'P + PA - PBR^-1B'P + Q = 0
    P = unilab_care(A, B, Q, R);
end
