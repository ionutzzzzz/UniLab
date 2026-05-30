function [weights, means, covs] = gmm_em(X, K, max_iters, tol)
    % GMM_EM Gaussian Mixture Model using Expectation-Maximization
    [m, n] = size(X);
    if nargin < 4, tol = 1e-6; end
    if nargin < 3, max_iters = 100; end
    
    % Initialize randomly
    rand_idx = randperm(m);
    means = X(rand_idx(1:K), :);
    covs = cell(K, 1);
    for k = 1:K
        covs{k} = eye(n);
    end
    weights = ones(K, 1) / K;
    
    log_likelihood_old = -1e99;
    gamma = zeros(m, K);
    
    for iter = 1:max_iters
        % E-step
        for k = 1:K
            diff = X - means(k, :);
            inv_cov = inv(covs{k});
            exponent = -0.5 * sum((diff * inv_cov) .* diff, 2);
            norm_const = 1 / sqrt(((2*pi())^n) * det(covs{k}));
            gamma(:, k) = weights(k) .* norm_const .* exp(exponent);
        end
        
        gamma_sum = sum(gamma, 2);
        for i = 1:m
            if gamma_sum(i) == 0
                gamma_sum(i) = 1e-15;
            end
        end
        
        for k = 1:K
            gamma(:, k) = gamma(:, k) ./ gamma_sum;
        end
        
        log_likelihood = sum(log(gamma_sum));
        if abs(log_likelihood - log_likelihood_old) < tol
            break;
        end
        log_likelihood_old = log_likelihood;
        
        % M-step
        N_k = sum(gamma, 1);
        for k = 1:K
            means(k, :) = (gamma(:, k)' * X) / N_k(k);
            diff = X - means(k, :);
            weighted_diff = zeros(m, n);
            for j = 1:n
                weighted_diff(:, j) = gamma(:, k) .* diff(:, j);
            end
            covs{k} = (diff' * weighted_diff) / N_k(k) + eye(n) * 1e-6;
            weights(k) = N_k(k) / m;
        end
    end
end
