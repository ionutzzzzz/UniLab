function [dq0] = alphaBeta2dq(ab0, theta)
    % ALPHABETA2DQ Transforms variables from stationary to rotating frame
    % dq0 = alphaBeta2dq(ab0, theta)
    
    if nargin < 1, ab0 = []; end
    if nargin < 2, theta = []; end
    if size(ab0, 2) ~= 3
        ab0 = ab0';
    end
    
    alpha = ab0(:, 1);
    beta = ab0(:, 2);
    z = ab0(:, 3);
    
    d = alpha .* cos(theta) + beta .* sin(theta);
    q = -alpha .* sin(theta) + beta .* cos(theta);
    
    dq0 = [d, q, z];
end
