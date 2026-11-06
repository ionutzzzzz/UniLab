function [f] = fibonacci(n)
    % FIBONACCI Calculate the n-th Fibonacci number
    
    if nargin < 1, n = []; end
    if n <= 1
        f = n;
        return;
    end
    
    a = 0;
    b = 1;
    for i = 2:n
        temp = a + b;
        a = b;
        b = temp;
    end
    f = b;
end
