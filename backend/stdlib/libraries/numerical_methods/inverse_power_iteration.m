function [v, lambda] = inverse_power_iteration(A, x0, mu, tol, max_iters)
    % INVERSE_POWER_ITERATION Find eigenvalue closest to mu
    n = size(A, 1);
    I = eye(n);
    B = A - mu * I;
    v = x0(:);
    
    for i = 1:max_iters
        v_next = solve_linear_system(B, v);
        v_next = v_next / norm(v_next);
        if norm(v_next - v) < tol || norm(v_next + v) < tol
            v = v_next;
            break;
        end
        v = v_next;
    end
    lambda = (v' * A * v) / (v' * v);
end
