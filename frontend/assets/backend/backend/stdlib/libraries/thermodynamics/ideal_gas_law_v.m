function V = ideal_gas_law_v(P, n, R, T)
    if nargin < 1, P = []; end
    if nargin < 2, n = []; end
    if nargin < 3, R = []; end
    if nargin < 4, T = []; end
    V = (n * R * T) / P;
end
