function [sysd] = c2d(sys, dt, method)
    % C2D Convert continuous-time system to discrete-time
    % sysd = c2d(sys, dt, method)
    % method defaults to 'zoh'
    if nargin < 3, method = 'zoh'; end
    res = unilab_c2d(sys, dt, method);
    % Reconstruct appropriate system type based on res
    if length(res) == 3 % (num, den, dt)
        sysd = tf(res{1}, res{2}, res{3});
    elseif length(res) == 5 % (A, B, C, D, dt)
        sysd = ss(res{1}, res{2}, res{3}, res{4}, res{5});
    else
        sysd = res;
    end
end
