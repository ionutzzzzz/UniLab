function b = beta_function(x, y)
    % BETA_FUNCTION Euler beta function B(x, y)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    b = (gamma_stirling(x) * gamma_stirling(y)) / gamma_stirling(x + y);
end
