function [mu] = gpr_predict(X_test, gp_model)
    % GPR_PREDICT Predict using Gaussian Process Regressor
    
    if nargin < 1, X_test = []; end
    if nargin < 2, gp_model = []; end
    m_test = size(X_test, 1);
    
    % Compute cross-kernel matrix K_s
    K_s = compute_kernel(gp_model.X_train, X_test, gp_model.kernel);
    
    mu = K_s' * gp_model.K_inv * gp_model.y_train;
end

function [K] = compute_kernel(X1, X2, kernel)
    if nargin < 1, X1 = []; end
    if nargin < 2, X2 = []; end
    if nargin < 3, kernel = []; end
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
