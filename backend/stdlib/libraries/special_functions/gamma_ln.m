function y = gamma_ln(x)
    % GAMMA_LN Natural logarithm of the gamma function
    % Lanczos approximation for better stability than log(gamma)
    y = log(gamma_stirling(x));
end
