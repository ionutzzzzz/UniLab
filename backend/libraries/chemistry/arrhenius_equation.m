function k = arrhenius_equation(A, Ea, T, R)
    % ARRHENIUS_EQUATION Calculate rate constant
    % k = A * exp(-Ea / (R * T))
    if nargin < 4, R = 8.314462618; end
    k = A * exp(-Ea / (R * T));
end
