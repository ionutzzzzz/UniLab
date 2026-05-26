function [sol] = solve_linear_system(A, b)
    % SOLVE_LINEAR_SYSTEM Solve Ax = b using matrix inverse
    % sol = A \ b
    sol = inv(A) * b;
end
