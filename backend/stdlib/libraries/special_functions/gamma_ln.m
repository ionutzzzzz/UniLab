function y = gamma_ln(x)
    % GAMMA_LN Natural logarithm of the gamma function
    % Lanczos approximation for better stability than log(gamma)
    if nargin < 1, x = []; end
    y = log(gamma_stirling(x));
end
