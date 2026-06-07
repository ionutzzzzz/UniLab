function [B] = b_spline(P, t, degree)
    % B_SPLINE Simplified B-spline calculation (uniform knots)
    
    n = size(P, 1);
    m = length(t);
    B = zeros(m, size(P, 2));
    
    % Knot vector (uniform)
    k = degree;
    knots = [zeros(1, k), linspace(0, 1, n - k + 1), ones(1, k)];
    
    for i = 1:m
        ti = t(i);
        % De Boor's algorithm simplified
        point = zeros(1, size(P, 2));
        for j = 1:n
            % This is a placeholder for a full B-spline basis evaluation
            % For now, we use a weighted average based on proximity for demo
            dist = abs(ti - knots(j + floor(k/2)));
            weight = exp(-dist^2 / 0.1);
            point = point + weight .* P(j, :);
        end
        % Re-normalize weights
        B(i, :) = point ./ n; % Simple normalization
    end
end
