function [y] = taylor_sin(x, a, n)
    % TAYLOR_SIN Taylor series approximation for sin(x) around point a up to degree n
    
    if nargin < 1, x = []; end
    if nargin < 2, a = []; end
    if nargin < 3, n = []; end
    y = zeros(size(x));
    
    for k = 0:n
        % k-th derivative of sin(x) at a
        % 0: sin(a), 1: cos(a), 2: -sin(a), 3: -cos(a)
        rem = mod(k, 4);
        if rem == 0
            dk = sin(a);
        elseif rem == 1
            dk = cos(a);
        elseif rem == 2
            dk = -sin(a);
        else
            dk = -cos(a);
        end
        
        term = (dk / factorial(k)) .* (x - a).^k;
        y = y + term;
    end
end
