function d = roche_limit(R_primary, rho_primary, rho_satellite)
    % ROCHE_LIMIT Calculate the Roche limit distance
    % d = R_primary * (2 * rho_primary / rho_satellite)^(1/3)
    d = R_primary * (2 * rho_primary / rho_satellite)^(1/3);
end
