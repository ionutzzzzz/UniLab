function [p] = poly_from_roots(r)
    % POLY_FROM_ROOTS Generate polynomial coefficients from roots
    % [p] = poly_from_roots([r1, r2, ...])
    
    n = length(r);
    p = [1];
    
    for i = 1:n
        % Multiply current p by (x - r(i))
        p = [p, 0] - [0, p * r(i)];
    end
end
