function P = electrical_power(V, I)
    if nargin < 1, V = []; end
    if nargin < 2, I = []; end
    P = V * I;
end
