function p = ideal_gas_p(n, R, T, V)
    if nargin < 1, n = []; end
    if nargin < 2, R = []; end
    if nargin < 3, T = []; end
    if nargin < 4, V = []; end
    p = n * R * T / V;
end