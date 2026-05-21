function y = incomplete_beta_function(x, a, b, n_terms)
    % INCOMPLETE_BETA_FUNCTION Incomplete beta function B(x; a, b)
    if nargin < 4, n_terms = 50; end
    sum_val = 0;
    for k = 0:n_terms
        term = (factorial_custom(k) / prod(a:a+k)) * (x^(a+k)); % Highly simplified
        sum_val = sum_val + term;
    end
    y = sum_val;
    disp('Note: incomplete_beta_function is a simplified series approximation.');
end
