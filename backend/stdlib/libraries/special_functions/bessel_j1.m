function y = bessel_j1(x)
    % Approximation using series
    y = (x/2) .* (1 - (x.^2)/8 + (x.^4)/192 - (x.^6)/9216);
end