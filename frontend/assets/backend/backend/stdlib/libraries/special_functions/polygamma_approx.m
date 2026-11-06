function y = polygamma_approx(m, x)
    % General polygamma for m > 1
    if nargin < 1, m = []; end
    if nargin < 2, x = []; end
    y = (-1)^(m+1) * factorial(m) ./ x.^(m+1);
end