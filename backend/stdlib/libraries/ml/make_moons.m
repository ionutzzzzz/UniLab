function [X, y] = make_moons(n_samples, noise)
    % MAKE_MOONS Generate two interleaving half circles
    % [X, y] = make_moons(n_samples, noise)
    
    if nargin < 2, noise = 0.1; end
    
    n_samples_out = floor(n_samples / 2);
    n_samples_in = n_samples - n_samples_out;
    
    theta_out = linspace(0, pi(), n_samples_out)';
    theta_in = linspace(0, pi(), n_samples_in)';
    
    X_out = [cos(theta_out), sin(theta_out)];
    X_in = [(1 - cos(theta_in)), (0.5 - sin(theta_in))];
    
    X = [X_out; X_in];
    y = [zeros(n_samples_out, 1); ones(n_samples_in, 1)];
    
    if noise > 0
        X = X + randn(size(X)) * noise;
    end
end
