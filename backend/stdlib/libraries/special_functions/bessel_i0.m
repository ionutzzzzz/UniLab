function y = bessel_i0(x)
    % Modified Bessel function of the first kind
    if nargin < 1, x = []; end
    y = bessel_j0_approx(1j * x, 10);
end