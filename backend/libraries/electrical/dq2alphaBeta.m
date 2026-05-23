function [ab0] = dq2alphaBeta(dq0, theta)
    % DQ2ALPHABETA Transforms variables from rotating to stationary frame
    
    if size(dq0, 2) ~= 3
        dq0 = dq0';
    end
    
    d = dq0(:, 1);
    q = dq0(:, 2);
    z = dq0(:, 3);
    
    alpha = d .* cos(theta) - q .* sin(theta);
    beta = d .* sin(theta) + q .* cos(theta);
    
    ab0 = [alpha, beta, z];
end
