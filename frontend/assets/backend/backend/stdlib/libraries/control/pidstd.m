function [sys] = pidstd(Kp, Ti, Td)
    % PIDSTD Create a Proportional-Integral-Derivative controller in standard form
    % C(s) = Kp * (1 + 1/(Ti*s) + Td*s)
    if nargin < 1, Kp = []; end
    if nargin < 2, Ti = inf; end
    if nargin < 3, Td = 0; end
    
    Ki = Kp / Ti;
    Kd = Kp * Td;
    sys = pid(Kp, Ki, Kd);
end
