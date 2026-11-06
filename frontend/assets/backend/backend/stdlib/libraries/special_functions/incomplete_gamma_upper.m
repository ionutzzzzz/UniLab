function y = incomplete_gamma_upper(a, x)
    % INCOMPLETE_GAMMA_UPPER Upper incomplete gamma function
    if nargin < 1, a = []; end
    if nargin < 2, x = []; end
    y = gamma_stirling(a) - incomplete_gamma_lower(a, x);
end
