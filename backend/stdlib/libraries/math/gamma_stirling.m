function [g] = gamma_stirling(x)
    % GAMMA_STIRLING Stirling's approximation for the Gamma function
    % Gamma(x) approx sqrt(2*pi/x) * (x/e)^x
    
    g = sqrt(2 * pi() ./ x) .* (x ./ exp(1)).^x;
end
