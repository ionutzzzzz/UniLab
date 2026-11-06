function k = thermal_conductivity(Q, d, A, dT)
    if nargin < 1, Q = []; end
    if nargin < 2, d = []; end
    if nargin < 3, A = []; end
    if nargin < 4, dT = []; end
    k = (Q * d) / (A * dT);
end
