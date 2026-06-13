function H = enthalpy(U, P, V)
    if nargin < 1, U = []; end
    if nargin < 2, P = []; end
    if nargin < 3, V = []; end
    H = U + P * V;
end
