function [x_best, f_best] = simulated_annealing(f, x0, T0, alpha, n_iters)
    % SIMULATED_ANNEALING Global optimization algorithm
    
    x = x0;
    f_current = unilab_call(f, x);
    x_best = x;
    f_best = f_current;
    T = T0;
    
    for i = 1:n_iters
        % Perturb x
        x_new = x + randn(size(x)) * 0.1;
        f_new = unilab_call(f, x_new);
        
        delta = f_new - f_current;
        
        % Accept if better, or with probability exp(-delta/T)
        if delta < 0 || rand() < exp(-delta / T)
            x = x_new;
            f_current = f_new;
            
            if f_current < f_best
                x_best = x;
                f_best = f_current;
            end
        end
        
        % Cool down
        T = T * alpha;
    end
end
