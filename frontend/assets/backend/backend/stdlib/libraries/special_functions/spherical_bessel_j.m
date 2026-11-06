function y = spherical_bessel_j(n, x)
    % SPHERICAL_BESSEL_J j_n(x) = sqrt(pi / 2x) * J_{n+1/2}(x)
    if nargin < 1, n = []; end
    if nargin < 2, x = []; end
    if n == 0
        y = sin(x) ./ x;
    elseif n == 1
        y = (sin(x) ./ x^2) - (cos(x) ./ x);
    else
        y = sqrt(pi() / (2 * x)) * bessel_j_all(n + 0.5, x); % Approx
    end
end
