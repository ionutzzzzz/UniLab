function r = circumcircle_radius(a, b, c)
    % CIRCUMCIRCLE_RADIUS Radius of the circumcircle of a triangle
    area = herons_formula(a, b, c);
    r = (a * b * c) / (4 * area);
end
