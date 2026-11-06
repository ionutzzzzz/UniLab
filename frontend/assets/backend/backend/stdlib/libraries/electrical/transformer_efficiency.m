function [eff] = transformer_efficiency(P_out, P_iron, R_eq, I_out)
    % TRANSFORMER_EFFICIENCY Calculates transformer efficiency
    % P_out: output power, P_iron: core losses, R_eq: equivalent resistance, I_out: current
    
    if nargin < 1, P_out = []; end
    if nargin < 2, P_iron = []; end
    if nargin < 3, R_eq = []; end
    if nargin < 4, I_out = []; end
    P_copper = I_out^2 * R_eq;
    eff = P_out / (P_out + P_iron + P_copper);
end
