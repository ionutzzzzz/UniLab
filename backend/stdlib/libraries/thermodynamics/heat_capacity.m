function C = heat_capacity(Q, dT)
    if nargin < 1, Q = []; end
    if nargin < 2, dT = []; end
    C = Q / dT;
end
