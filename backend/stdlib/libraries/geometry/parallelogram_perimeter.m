function P = parallelogram_perimeter(a, b)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    P = 2 * (a + b);
end
