function sigma = stress_calc(F, A)
    if nargin < 1, F = []; end
    if nargin < 2, A = []; end
    sigma = F / A;
end
