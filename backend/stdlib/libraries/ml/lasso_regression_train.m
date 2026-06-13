function [theta] = lasso_regression_train(X, y, lambda, max_iters, tol)
    % LASSO_REGRESSION_TRAIN Train linear regression with L1 regularization
    % Uses Coordinate Descent algorithm
    
    if nargin < 2, y = []; end
    if nargin < 3, lambda = []; end
    if nargin < 5, tol = 1e-6; end
    if nargin < 4, max_iters = 1000; end
    
    [m, n] = size(X);
    X = [ones(m, 1), X]; % Add bias term
    n = n + 1;
    
    theta = zeros(n, 1);
    
    for iter = 1:max_iters
        theta_old = theta;
        for j = 1:n
            % Residual without feature j
            h = X * theta;
            residual = y - h + theta(j) * X(:, j);
            
            % Correlation of feature j with residual
            rho = X(:, j)' * residual;
            
            if j == 1
                % Bias term (no shrinkage)
                theta(j) = rho / m;
            else
                % Soft thresholding for L1 regularization
                denom = sum(X(:, j).^2);
                if rho < -lambda/2
                    theta(j) = (rho + lambda/2) / denom;
                elseif rho > lambda/2
                    theta(j) = (rho - lambda/2) / denom;
                else
                    theta(j) = 0;
                end
            end
        end
        
        if norm(theta - theta_old) < tol
            break;
        end
    end
end
