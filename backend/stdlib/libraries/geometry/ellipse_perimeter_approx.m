function P = ellipse_perimeter_approx(a, b)
    % Ramanujan approximation
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    h = (a - b)^2 / (a + b)^2;
    P = pi() * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)));
end
