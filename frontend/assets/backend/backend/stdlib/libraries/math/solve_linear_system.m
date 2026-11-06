function [sol] = solve_linear_system(A, b)
    % SOLVE_LINEAR_SYSTEM Solve Ax = b using matrix inverse
    % sol = A \ b
    if nargin < 1, A = []; end
    if nargin < 2, b = []; end
    sol = inv(A) * b;
end
