function [X] = lyap(A, Q)
    % LYAP Solve continuous-time Lyapunov equations
    % X = lyap(A, Q) solves AX + XA' + Q = 0
    X = unilab_lyap(A, Q);
end
