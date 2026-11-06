function T = ideal_gas_law_t(P, V, n, R)
    if nargin < 1, P = []; end
    if nargin < 2, V = []; end
    if nargin < 3, n = []; end
    if nargin < 4, R = []; end
    T = (P * V) / (n * R);
end
