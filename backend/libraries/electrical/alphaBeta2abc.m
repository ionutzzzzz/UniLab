function [abc] = alphaBeta2abc(ab0)
    % ALPHABETA2ABC Performs inverse Clarke transformation (alpha-beta-0 to abc)
    
    if size(ab0, 2) ~= 3
        ab0 = ab0';
    end
    
    alpha = ab0(:, 1);
    beta = ab0(:, 2);
    z = ab0(:, 3);
    
    a = alpha + z;
    b = -0.5*alpha + sqrt(3)/2 * beta + z;
    c = -0.5*alpha - sqrt(3)/2 * beta + z;
    
    abc = [a, b, c];
end
