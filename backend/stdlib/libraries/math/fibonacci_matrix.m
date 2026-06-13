function f = fibonacci_matrix(n)
    % FIBONACCI_MATRIX Calculate the n-th Fibonacci number using matrix exponentiation
    % [F_{n+1}, F_n; F_n, F_{n-1}] = [1, 1; 1, 0]^n
    if nargin < 1, n = []; end
    if n == 0, f = 0; return; end
    if n == 1, f = 1; return; end
    
    T = [1, 1; 1, 0];
    Tn = T^n;
    f = Tn(1, 2);
end
