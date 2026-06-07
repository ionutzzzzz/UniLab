function y = spherical_bessel_y(n, x)
    % SPHERICAL_BESSEL_Y y_n(x) = sqrt(pi / 2x) * Y_{n+1/2}(x)
    if n == 0
        y = -cos(x) ./ x;
    elseif n == 1
        y = -(cos(x) ./ x^2) - (sin(x) ./ x);
    else
        y = -spherical_bessel_j(-(n+1), x); % Property
    end
end
