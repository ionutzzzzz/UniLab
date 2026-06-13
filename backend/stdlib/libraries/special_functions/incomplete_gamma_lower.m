function y = incomplete_gamma_lower(a, x, n_terms)
    % INCOMPLETE_GAMMA_LOWER Lower incomplete gamma function (series)
    if nargin < 1, a = []; end
    if nargin < 2, x = []; end
    if nargin < 3, n_terms = 50; end
    sum_val = 0;
    for k = 0:n_terms
        sum_val = sum_val + (x^k) / (prod(a:a+k));
    end
    y = sum_val * exp(-x) * x^a;
end
