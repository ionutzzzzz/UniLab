function [x, f_val] = gradient_descent(f, x0, alpha, num_iters)
    % GRADIENT_DESCENT Generic gradient descent optimization
    % [x, f_val] = gradient_descent(f, x0, alpha, num_iters)
    
    if nargin < 4, num_iters = 1000; end
    if nargin < 3, alpha = 0.01; end
    
    x = x0;
    epsilon = 1e-6;

    for i = 1:num_iters
        % Numerical gradient
        grad = zeros(size(x));
        f0 = f(x);
        for j = 1:length(x)
            x_plus = x;
            x_plus(j) = x_plus(j) + epsilon;
            grad(j) = (f(x_plus) - f0) / epsilon;
        end
        
        x = x - alpha .* grad;
    end
    f_val = f(x);
end
