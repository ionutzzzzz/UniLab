function [L, P, E] = kalman(sys, Q, R)
    % KALMAN Design Kalman filter for continuous-time system
    % [L, P, E] = kalman(sys, Q, R)
    [L, P, E] = unilab_kalman(sys, Q, R);
end
