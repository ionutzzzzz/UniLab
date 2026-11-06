function [sys] = pid(Kp, Ki, Kd)
    % PID Create a Proportional-Integral-Derivative controller
    % sys = pid(Kp, Ki, Kd) returns a transfer function model
    if nargin < 1, Kp = []; end
    if nargin < 2, Ki = 0; end
    if nargin < 3, Kd = 0; end
    
    % C(s) = Kp + Ki/s + Kd*s = (Kd*s^2 + Kp*s + Ki) / s
    num = [Kd, Kp, Ki];
    den = [1, 0];
    
    % Simplified case for P only
    if Ki == 0 && Kd == 0
        num = [Kp];
        den = [1];
    elseif Kd == 0
        % PI controller: (Kp*s + Ki) / s
        num = [Kp, Ki];
        den = [1, 0];
    end
    
    sys = tf(num, den);
end
