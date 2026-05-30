function [T] = taylor(expr, var, point, order)
    % TAYLOR Symbolic Taylor series expansion
    % T = taylor(expr, var, point, order)
    
    if nargin < 3, point = 0; end
    if nargin < 4, order = 6; end
    
    T = unilab_call(taylor, expr, var, point, order);
end
