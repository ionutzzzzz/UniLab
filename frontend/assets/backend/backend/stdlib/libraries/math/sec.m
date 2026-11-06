function y = sec(x)
    % SEC Secant in radians
    if nargin < 1, x = []; end
    y = 1 ./ cos(x);
end
