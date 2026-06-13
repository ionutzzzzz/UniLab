function [g_best, f_g_best] = particle_swarm(f, n_particles, dim, n_iters, bounds)
    % PARTICLE_SWARM Particle Swarm Optimization
    
    % bounds is [min, max]
    if nargin < 1, f = []; end
    if nargin < 2, n_particles = []; end
    if nargin < 3, dim = []; end
    if nargin < 4, n_iters = []; end
    if nargin < 5, bounds = []; end
    low = bounds(1);
    high = bounds(2);
    
    x = low + (high - low) .* rand(n_particles, dim);
    v = zeros(n_particles, dim);
    p_best = x;
    f_p_best = zeros(n_particles, 1);
    
    for i = 1:n_particles
        f_p_best(i) = unilab_call(f, x(i, :));
    end
    
    [f_g_best, g_idx] = min(f_p_best);
    g_best = p_best(g_idx, :);
    
    w = 0.5; c1 = 1.5; c2 = 1.5;
    
    for iter = 1:n_iters
        for i = 1:n_particles
            r1 = rand(1, dim);
            r2 = rand(1, dim);
            
            v(i, :) = w .* v(i, :) + c1 .* r1 .* (p_best(i, :) - x(i, :)) + c2 .* r2 .* (g_best - x(i, :));
            x(i, :) = x(i, :) + v(i, :);
            
            % Boundary check
            x(i, :) = max(min(x(i, :), high), low);
            
            f_i = unilab_call(f, x(i, :));
            if f_i < f_p_best(i)
                f_p_best(i) = f_i;
                p_best(i, :) = x(i, :);
                
                if f_i < f_g_best
                    f_g_best = f_i;
                    g_best = x(i, :);
                end
            end
        end
    end
end
