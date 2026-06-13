function W = adiabatic_work_ideal_gas(P1, V1, P2, V2, gamma)
    if nargin < 1, P1 = []; end
    if nargin < 2, V1 = []; end
    if nargin < 3, P2 = []; end
    if nargin < 4, V2 = []; end
    if nargin < 5, gamma = []; end
    W = (P1 * V1 - P2 * V2) / (gamma - 1);
end
