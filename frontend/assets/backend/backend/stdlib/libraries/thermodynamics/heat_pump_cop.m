function cop = heat_pump_cop(Q_high, W_in)
    % HEAT_PUMP_COP Coefficient of Performance for a heat pump
    if nargin < 1, Q_high = []; end
    if nargin < 2, W_in = []; end
    cop = Q_high / W_in;
end
