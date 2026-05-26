function [v, lambda] = rayleigh_quotient_iteration(A, x0, tol, max_iters)
    % RAYLEIGH_QUOTIENT_ITERATION Rapid convergence to nearest eigenvalue
    v = x0(:) / norm(x0);
    lambda = (v' * A * v);
    I = eye(size(A));
    
    for i = 1:max_iters
        try
            v_next = solve_linear_system(A - lambda * I, v);
        catch
            break; % Singular matrix
        end
        v_next = v_next / norm(v_next);
        lambda_next = (v_next' * A * v_next);
        
        if abs(lambda_next - lambda) < tol
            v = v_next;
            lambda = lambda_next;
            break;
        end
        v = v_next;
        lambda = lambda_next;
    end
end
