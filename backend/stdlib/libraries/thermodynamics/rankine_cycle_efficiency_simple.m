function eff = rankine_cycle_efficiency_simple(h1, h2, h3, h4)
    % RANKINE_CYCLE_EFFICIENCY_SIMPLE Efficiency of a simple Rankine cycle
    % h1: turbine inlet, h2: turbine exit, h3: pump inlet, h4: pump exit
    w_turb = h1 - h2;
    w_pump = h4 - h3;
    q_in = h1 - h4;
    eff = (w_turb - w_pump) / q_in;
end
