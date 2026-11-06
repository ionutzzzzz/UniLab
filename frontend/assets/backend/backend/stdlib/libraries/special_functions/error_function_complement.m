function y = error_function_complement(x)
    % ERROR_FUNCTION_COMPLEMENT erfc(x) = 1 - erf(x)
    if nargin < 1, x = []; end
    y = 1 - erf_approx(x);
end
