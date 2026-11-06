function eff = rankine_cycle_efficiency_simple(h1, h2, h3, h4)
    % RANKINE_CYCLE_EFFICIENCY_SIMPLE Efficiency of a simple Rankine cycle
    % h1: turbine inlet, h2: turbine exit, h3: pump inlet, h4: pump exit
    if nargin < 1, h1 = []; end
    if nargin < 2, h2 = []; end
    if nargin < 3, h3 = []; end
    if nargin < 4, h4 = []; end
    w_turb = h1 - h2;
    w_pump = h4 - h3;
    q_in = h1 - h4;
    eff = (w_turb - w_pump) / q_in;
end
