function k = arrhenius_equation(A, Ea, T, R)
    % ARRHENIUS_EQUATION Calculate rate constant
    % k = A * exp(-Ea / (R * T))
    if nargin < 1, A = []; end
    if nargin < 2, Ea = []; end
    if nargin < 3, T = []; end
    if nargin < 4, R = 8.314462618; end
    k = A * exp(-Ea / (R * T));
end
