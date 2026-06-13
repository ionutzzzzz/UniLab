function [R, iterations] = romberg_integration(f, a, b, tol, max_steps)
    % ROMBERG_INTEGRATION Numerical integration using Romberg's method
    % [R, iterations] = romberg_integration(f, a, b, tol, max_steps)
    
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = 1e-6; end
    if nargin < 5, max_steps = 10; end
    
    R = zeros(max_steps, max_steps);
    h = b - a;
    
    % First step: Trapezoidal rule with 1 interval
    R(1,1) = (h/2) * (unilab_call(f, a) + unilab_call(f, b));
    
    for i = 2:max_steps
        h = h / 2;
        sum_val = 0;
        for k = 1:2^(i-2)
            sum_val = sum_val + unilab_call(f, a + (2*k-1)*h);
        end
        
        R(i,1) = 0.5 * R(i-1,1) + h * sum_val;
        
        for j = 2:i
            R(i,j) = R(i,j-1) + (R(i,j-1) - R(i-1,j-1)) / (4^(j-1) - 1);
        end
        
        if abs(R(i,i) - R(i-1,i-1)) < tol
            R = R(i,i);
            iterations = i;
            return;
        end
    end
    
    iterations = max_steps;
    R = R(max_steps, max_steps);
end
