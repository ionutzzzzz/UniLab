function c = specific_heat_capacity(Q, m, dT)
    if nargin < 1, Q = []; end
    if nargin < 2, m = []; end
    if nargin < 3, dT = []; end
    c = Q / (m * dT);
end
