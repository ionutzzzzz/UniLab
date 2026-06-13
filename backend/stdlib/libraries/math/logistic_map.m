function [x] = logistic_map(r, x0, n)
    % LOGISTIC_MAP Generate a sequence from the logistic map
    % x_{n+1} = r * x_n * (1 - x_n)
    
    if nargin < 1, r = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, n = []; end
    x = zeros(n, 1);
    x(1) = x0;
    for i = 1:n-1
        x(i+1) = r * x(i) * (1 - x(i));
    end
end
