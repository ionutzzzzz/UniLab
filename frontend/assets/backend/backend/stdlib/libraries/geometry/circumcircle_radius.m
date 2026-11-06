function r = circumcircle_radius(a, b, c)
    % CIRCUMCIRCLE_RADIUS Radius of the circumcircle of a triangle
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, c = []; end
    area = herons_formula(a, b, c);
    r = (a * b * c) / (4 * area);
end
