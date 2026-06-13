function y = bessel_y0(x)
    % Approximation for small x
    if nargin < 1, x = []; end
    gamma = 0.5772156649;
    y = (2/pi()) * (log(x/2) + gamma) .* bessel_j0_approx(x, 10);
end