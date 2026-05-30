function E = matrix_exponential_approx(A, n_terms)
    % MATRIX_EXPONENTIAL_APPROX Matrix exponential using Taylor series
    if nargin < 2, n_terms = 20; end
    n = size(A, 1);
    E = eye(n);
    term = eye(n);
    for i = 1:n_terms
        term = (term * A) / i;
        E = E + term;
    end
end
