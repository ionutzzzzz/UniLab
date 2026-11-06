function y = trapz_custom(v, x)
    if nargin < 1, v = []; end
    if nargin < 2, x = []; end
    y = trapz(v, x);
end
