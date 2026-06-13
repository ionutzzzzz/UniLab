function OS = peak_overshoot_calc(zeta)
    % PEAK_OVERSHOOT_CALC Calculate percentage overshoot from damping ratio
    if nargin < 1, zeta = []; end
    OS = exp(-zeta * pi() / sqrt(1 - zeta^2)) * 100;
end
