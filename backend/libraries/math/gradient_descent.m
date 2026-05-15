function [x, history] = gradient_descent(f, df, x0, alpha, num_iters)
    % GRADIENT_DESCENT Generic gradient descent optimization
    % [x, history] = gradient_descent(f, df, x0, alpha, num_iters)
    
    x = x0;
    history = zeros(num_iters, length(x0));
    
    for i = 1:num_iters
        grad = unilab_call(df, x);
        x = x - alpha .* grad;
        history(i, :) = x;
    end
end
