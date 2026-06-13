function F = newton_second_law(m, a)
    if nargin < 1, m = []; end
    if nargin < 2, a = []; end
    F = m * a;
end
