function x = fixed_point_iteration(g, x0, tol, max_iter)
    % FIXED_POINT_ITERATION Find fixed point of x = g(x)
    % x = fixed_point_iteration(g, x0, tol, max_iter)
    
    if nargin < 3, tol = 1e-6; end
    if nargin < 4, max_iter = 100; end
    
    x = x0;
    for i = 1:max_iter
        x_next = unilab_call(g, x);
        if abs(x_next - x) < tol
            x = x_next;
            return;
        end
        x = x_next;
    end
end
