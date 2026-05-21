function P = ellipse_perimeter_approx(a, b)
    % Ramanujan approximation
    h = (a - b)^2 / (a + b)^2;
    P = pi() * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)));
end
