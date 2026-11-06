function y = bessel_k0(x)
    % Modified Bessel function of the second kind
    if nargin < 1, x = []; end
    I0 = bessel_i0(x);
    y = -log(x/2) .* I0; % Simplified approx
end