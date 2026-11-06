function [r] = roots_poly(p)
    % ROOTS_POLY Find roots of a polynomial with coefficients p
    % Uses the companion matrix approach
    
    if nargin < 1, p = []; end
    n = length(p) - 1;
    if n < 1
        r = [];
        return;
    end
    
    % Normalize
    p = p / p(1);
    
    % Companion matrix
    C = zeros(n, n);
    if n > 1
        % Fill sub-diagonal
        for i = 2:n
            C(i, i-1) = 1;
        end
    end
    % Fill first row
    C(1, :) = -p(2:end);
    
    % Roots are the eigenvalues
    r = eig(C);
end
