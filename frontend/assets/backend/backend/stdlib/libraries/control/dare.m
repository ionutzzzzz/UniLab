function [P] = dare(A, B, Q, R)
    % DARE Discrete-time Algebraic Riccati Equation solver
    P = unilab_dare(A, B, Q, R);
end
