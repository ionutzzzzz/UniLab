function area = herons_formula(a, b, c)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, c = []; end
    s = (a + b + c) / 2;
    area = sqrt(s * (s - a) * (s - b) * (s - c));
end