function p = probProbit(X, beta)
    % PROBPROBIT Probit regression probability
    if nargin < 1, X = []; end
    if nargin < 2, beta = []; end
    z = X * beta;
    % Requires normcdf from math library
    p = normcdf(z);
end
