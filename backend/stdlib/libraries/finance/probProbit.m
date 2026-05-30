function p = probProbit(X, beta)
    % PROBPROBIT Probit regression probability
    z = X * beta;
    % Requires normcdf from math library
    p = normcdf(z);
end
