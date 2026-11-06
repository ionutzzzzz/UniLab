function P = pressure(F, A)
    if nargin < 1, F = []; end
    if nargin < 2, A = []; end
    P = F / A;
end
