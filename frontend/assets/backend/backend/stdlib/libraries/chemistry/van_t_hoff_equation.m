function ln_K2_K1 = van_t_hoff_equation(delta_H, T1, T2, R)
    % VAN_T_HOFF_EQUATION Change in equilibrium constant with temperature
    % ln(K2/K1) = (delta_H / R) * (1/T1 - 1/T2)
    if nargin < 1, delta_H = []; end
    if nargin < 2, T1 = []; end
    if nargin < 3, T2 = []; end
    if nargin < 4, R = 8.314462618; end
    ln_K2_K1 = (delta_H / R) * (1/T1 - 1/T2);
end
