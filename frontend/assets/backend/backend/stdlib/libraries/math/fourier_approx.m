function [F] = fourier_approx(t, f_t, f)
    % FOURIER_APPROX Numerical approximation of the Continuous Fourier Transform
    % F(f) = integral_{-inf}^inf f(t) e^{-j 2 pi f t} dt
    % [F] = fourier_approx(t, f_t, f)
    
    if nargin < 1, t = []; end
    if nargin < 2, f_t = []; end
    if nargin < 3, f = []; end
    num_f = length(f);
    F = zeros(num_f, 1);
    
    for i = 1:num_f
        integrand = f_t .* exp(-1i * 2 * pi() * f(i) * t);
        F(i) = trapz_custom(integrand, t);
    end
end
