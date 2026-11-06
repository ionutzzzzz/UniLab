function [H] = hessian_custom(f, vars)
    % HESSIAN_CUSTOM Symbolic Hessian matrix
    % H = hessian_custom(f, [x, y])
    
    if nargin < 1, f = []; end
    if nargin < 2, vars = []; end
    n = length(vars);
    H = cell(n, n);
    
    for i = 1:n
        for j = 1:n
            H{i, j} = diff(diff(f, vars(i)), vars(j));
        end
    end
end
