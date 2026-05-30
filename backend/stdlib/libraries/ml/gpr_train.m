function [gp_model] = gpr_train(X, y, alpha, kernel)
    % GPR_TRAIN Train a Gaussian Process Regressor
    % gp_model = gpr_train(X, y, alpha, kernel)
    
    if nargin < 4, kernel = 'rbf'; end
    if nargin < 3, alpha = 1e-10; end
    
    m = size(X, 1);
    
    % Compute kernel matrix K
    K = compute_kernel(X, X, kernel);
    K = K + alpha * eye(m);
    
    K_inv = inv(K);
    
    gp_model = struct('X_train', X, 'y_train', y, 'K_inv', K_inv, 'kernel', kernel);
end

function [K] = compute_kernel(X1, X2, kernel)
    % RBF Kernel: exp(-0.5 * ||x1 - x2||^2)
    m1 = size(X1, 1);
    m2 = size(X2, 1);
    K = zeros(m1, m2);
    
    for i = 1:m1
        for j = 1:m2
            d = norm(X1(i, :) - X2(j, :));
            K(i, j) = exp(-0.5 * d^2);
        end
    end
end
