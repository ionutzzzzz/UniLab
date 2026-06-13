function n = ideal_gas_law_n(P, V, R, T)
    if nargin < 1, P = []; end
    if nargin < 2, V = []; end
    if nargin < 3, R = []; end
    if nargin < 4, T = []; end
    n = (P * V) / (R * T);
end
