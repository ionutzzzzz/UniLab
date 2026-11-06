function r = incircle_radius(a, b, c)
    % INCIRCLE_RADIUS Radius of the incircle of a triangle
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, c = []; end
    area = herons_formula(a, b, c);
    s = (a + b + c) / 2;
    r = area / s;
end
