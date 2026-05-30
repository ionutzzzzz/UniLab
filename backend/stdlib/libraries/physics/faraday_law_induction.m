function epsilon = faraday_law_induction(N, dPhi_dt)
    % FARADAY_LAW_INDUCTION Induced EMF in a coil
    % epsilon = -N * (dPhi / dt)
    epsilon = -N * dPhi_dt;
end
