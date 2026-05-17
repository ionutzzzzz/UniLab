function [J] = jacobian_custom(f, vars)
    % JACOBIAN_CUSTOM Symbolic Jacobian matrix
    % J = jacobian_custom([f1; f2], [x1, x2])
    
    m = length(f);
    n = length(vars);
    J = cell(m, n);
    
    for i = 1:m
        for j = 1:n
            J{i, j} = diff(f(i), vars(j));
        end
    end
end
