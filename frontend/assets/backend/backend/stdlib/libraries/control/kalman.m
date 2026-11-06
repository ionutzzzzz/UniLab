function [L, P, E] = kalman(sys, Q, R)
    % KALMAN Design Kalman filter for continuous-time system
    % [L, P, E] = kalman(sys, Q, R)
    if nargin < 1, sys = []; end
    if nargin < 2, Q = []; end
    if nargin < 3, R = []; end
    [L, P, E] = unilab_kalman(sys, Q, R);
end
