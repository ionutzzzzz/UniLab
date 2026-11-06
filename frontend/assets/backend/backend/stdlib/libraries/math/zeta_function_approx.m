function z = zeta_function_approx(s, n_terms)
    % ZETA_FUNCTION_APPROX Approximate the Riemann zeta function for real s > 1
    if nargin < 1, s = []; end
    if nargin < 2, n_terms = 1000; end
    z = sum((1:n_terms).^(-s));
end
