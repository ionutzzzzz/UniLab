function [L] = limit(expr, var, value, direction)
    % LIMIT Symbolic limit
    % L = limit(expr, var, value)
    % L = limit(expr, var, value, 'left') or 'right'
    
    if nargin < 1, expr = []; end
    if nargin < 2, var = []; end
    if nargin < 3, value = []; end
    if nargin < 4, direction = 'both'; end
    L = unilab_call(limit, expr, var, value, direction);
end
