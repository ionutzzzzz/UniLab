function b = beta_function(x, y)
    % BETA_FUNCTION Euler beta function B(x, y)
    b = (gamma_stirling(x) * gamma_stirling(y)) / gamma_stirling(x + y);
end
