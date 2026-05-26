function r = incircle_radius(a, b, c)
    % INCIRCLE_RADIUS Radius of the incircle of a triangle
    area = herons_formula(a, b, c);
    s = (a + b + c) / 2;
    r = area / s;
end
