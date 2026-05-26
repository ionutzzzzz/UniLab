function x = inverse_error_function_approx(y)
    % INVERSE_ERROR_FUNCTION_APPROX Approximation of the inverse error function
    % Winitzki approximation
    a = 8 * (pi() - 3) / (3 * pi() * (4 - pi()));
    L = log(1 - y^2);
    part1 = (2 / (pi() * a)) + (L / 2);
    x = sign(y) * sqrt(sqrt(part1^2 - (L / a)) - part1);
end
