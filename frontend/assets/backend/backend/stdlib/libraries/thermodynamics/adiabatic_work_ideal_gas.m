function W = adiabatic_work_ideal_gas(P1, V1, P2, V2, gamma)
    W = (P1 * V1 - P2 * V2) / (gamma - 1);
end
