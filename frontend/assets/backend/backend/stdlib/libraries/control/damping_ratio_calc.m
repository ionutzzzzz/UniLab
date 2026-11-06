function zeta = damping_ratio_calc(OS_percent)
    % DAMPING_RATIO_CALC Calculate damping ratio from percentage overshoot
    % OS = exp(-zeta * pi / sqrt(1 - zeta^2)) * 100
    if nargin < 1, OS_percent = []; end
    L = log(OS_percent / 100);
    zeta = sqrt(L^2 / (pi()^2 + L^2));
end
