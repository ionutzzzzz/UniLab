function [mu] = gpr_predict(X_test, gp_model)
    % GPR_PREDICT Predict using Gaussian Process Regressor
    
    m_test = size(X_test, 1);
    
    % Compute cross-kernel matrix K_s
    K_s = compute_kernel(gp_model.X_train, X_test, gp_model.kernel);
    
    mu = K_s' * gp_model.K_inv * gp_model.y_train;
end

function [K] = compute_kernel(X1, X2, kernel)
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
