function y = expm1(x)
    % EXPM1 Exponential of x minus 1
    if nargin < 1, x = []; end
    if abs(x) < 1e-4
        y = x + x^2/2 + x^3/6; % Taylor approximation for small x
    else
        y = exp(x) - 1;
    end
end
