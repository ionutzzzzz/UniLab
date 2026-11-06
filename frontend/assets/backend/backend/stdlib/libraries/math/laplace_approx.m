function [F] = laplace_approx(t, f_t, s)
    % LAPLACE_APPROX Numerical approximation of the Laplace transform
    % F(s) = integral_0^inf e^{-st} f(t) dt
    % [F] = laplace_approx(t, f_t, s)
    
    if nargin < 1, t = []; end
    if nargin < 2, f_t = []; end
    if nargin < 3, s = []; end
    num_s = length(s);
    F = zeros(num_s, 1);
    
    for i = 1:num_s
        integrand = exp(-s(i) * t) .* f_t;
        % Integrate over the provided range of t
        F(i) = trapz_custom(integrand, t);
    end
end
