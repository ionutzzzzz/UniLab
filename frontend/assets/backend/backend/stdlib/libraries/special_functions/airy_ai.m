function y = airy_ai(x)
    % Approximation using fractional Bessel functions
    zeta = (2/3) * x.^(3/2);
    y = (1/pi()) * sqrt(x/3) .* bessel_k0(zeta); % Rough approx
end