function eff = diesel_cycle_efficiency(r, rc, gamma)
    % DIESEL_CYCLE_EFFICIENCY Theoretical efficiency of a Diesel cycle
    % r: compression ratio, rc: cutoff ratio
    num = rc^gamma - 1;
    den = gamma * (rc - 1);
    eff = 1 - (1 / r^(gamma - 1)) * (num / den);
end
