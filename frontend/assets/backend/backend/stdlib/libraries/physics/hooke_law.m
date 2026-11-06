function F = hooke_law(k, x)
    if nargin < 1, k = []; end
    if nargin < 2, x = []; end
    F = -k * x;
end
