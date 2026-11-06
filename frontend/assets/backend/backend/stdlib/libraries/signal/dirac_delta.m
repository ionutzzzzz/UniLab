function y = dirac_delta(x)
    if nargin < 1, x = []; end
    y = zeros(size(x));
    y(x == 0) = inf;
end
