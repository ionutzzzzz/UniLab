function G = gibbs_free_energy(H, T, S)
    % GIBBS_FREE_ENERGY Calculate Gibbs free energy
    % G = H - T * S
    G = H - T * S;
end
