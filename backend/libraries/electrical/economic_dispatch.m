function [P_gen] = economic_dispatch(costs, P_min, P_max, P_demand)
    % ECONOMIC_DISPATCH Solves a simple economic dispatch problem
    % costs: [a, b, c] coefficients for C = a*P^2 + b*P + c
    % P_min, P_max: generation limits
    % P_demand: total system demand
    
    num_units = size(costs, 1);
    
    % Lambda iteration method (Simplified)
    lambda = max(costs(:, 2)); % Start with max linear cost
    for iter = 1:50
        P_gen = (lambda - costs(:, 2)) ./ (2 * costs(:, 1));
        P_gen = max(min(P_gen, P_max), P_min);
        
        diff = P_demand - sum(P_gen);
        if abs(diff) < 1e-4
            break;
        end
        
        % Adjust lambda
        d_lambda = diff / sum(1 ./ (2 * costs(:, 1)));
        lambda = lambda + d_lambda;
    end
end
