function [ab0] = abc2alphaBeta(abc)
    % ABC2ALPHABETA Performs Clarke transformation (abc to alpha-beta-0)
    % ab0 = abc2alphaBeta(abc)
    
    if size(abc, 2) ~= 3
        abc = abc';
    end
    
    a = abc(:, 1);
    b = abc(:, 2);
    c = abc(:, 3);
    
    alpha = (2/3) * (a - 0.5*b - 0.5*c);
    beta = (2/3) * (sqrt(3)/2 * b - sqrt(3)/2 * c);
    z = (1/3) * (a + b + c);
    
    ab0 = [alpha, beta, z];
end
