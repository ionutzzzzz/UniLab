function C = capacitance(Q, V)
    if nargin < 1, Q = []; end
    if nargin < 2, V = []; end
    C = Q / V;
end
