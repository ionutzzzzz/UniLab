function [eff] = transformer_efficiency(P_out, P_iron, R_eq, I_out)
    % TRANSFORMER_EFFICIENCY Calculates transformer efficiency
    % P_out: output power, P_iron: core losses, R_eq: equivalent resistance, I_out: current
    
    P_copper = I_out^2 * R_eq;
    eff = P_out / (P_out + P_iron + P_copper);
end
