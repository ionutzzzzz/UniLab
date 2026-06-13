function [B] = bezier_curve(P, t)
    % BEZIER_CURVE Calculate points on a Bezier curve
    % P is control points [x1, y1; x2, y2; ...]
    % t is a vector of parameters from 0 to 1
    
    if nargin < 1, P = []; end
    if nargin < 2, t = []; end
    n = size(P, 1) - 1;
    m = length(t);
    B = zeros(m, size(P, 2));
    
    for i = 1:m
        ti = t(i);
        point = zeros(1, size(P, 2));
        for k = 0:n
            % Bernstein polynomial
            coeff = factorial(n) / (factorial(k) * factorial(n - k));
            bern = coeff * (ti^k) * (1 - ti)^(n - k);
            point = point + bern .* P(k + 1, :);
        end
        B(i, :) = point;
    end
end
